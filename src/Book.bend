import Base

# Booking the free call: what the page offers, from the open slots horas
# publishes (public/slots.json) and what the visitor's browser says of its
# clock. Everything here is a plain function of those two texts; Main.bend
# shows it, and LAWS.bend states what it promises (no slot offered is past,
# a stale or empty list gives the plain email link, and every slot is listed
# under the day it falls on in the visitor's own time).
#
# A time is a whole minute since 1970-01-01 00:00 UTC, as a U32; `now` and
# the list's `generated` are seconds.

# Calendar arithmetic
# -------------------
#
# Days count from 1970-01-01 (a Thursday) by the proleptic Gregorian calendar
# (Howard Hinnant's days_from_civil and civil_from_days, as in horas's
# Slots.bend).

def pad2(+n: U32) -> String:
  Bool.pick(String, U32.is_lt(n, 10), "0" ++ U32.show(n), U32.show(n))

# The number written at s[i..i+n], or 0.
def num(+s: String, +i: Nat, +n: Nat) -> U32:
  Maybe.default(&2, U32, U32.read(String.take(String.drop(s, i), n)), 0)

def days.go(+y: U32, +m: U32, +d: U32) -> U32:
  +era = (y / 400 : U32)
  +yoe = (y - (era * 400) : U32)
  +mp = ((m + 9) % 12 : U32)
  +doy = ((((153 * mp) + 2) / 5) + d - 1 : U32)
  +doe = ((yoe * 365) + (yoe / 4) - (yoe / 100) + doy : U32)
  ((era * 146097) + doe - 719468 : U32)

def days.of(+y: U32, +m: U32, +d: U32) -> U32:
  days.go(Bool.pick(U32, U32.is_le(m, 2), (y - 1 : U32), y), m, d)

type Ymd is Data:
  Ymd{+y: U32, +m: U32, +d: U32}

def ymd.fix(+y: U32, +m: U32, +d: U32) -> Ymd:
  Ymd{Bool.pick(U32, U32.is_le(m, 2), (y + 1 : U32), y), m, d}

def civil(+days: U32) -> Ymd:
  +z = (days + 719468 : U32)
  +era = (z / 146097 : U32)
  +doe = (z - (era * 146097) : U32)
  +yoe = ((doe - (doe / 1460) + (doe / 36524) - (doe / 146096)) / 365 : U32)
  +doy = (doe - ((365 * yoe) + (yoe / 4) - (yoe / 100)) : U32)
  +mp = (((5 * doy) + 2) / 153 : U32)
  +d = (doy - ((((153 * mp) + 2) / 5)) + 1 : U32)
  +m = Bool.pick(U32, U32.is_lt(mp, 10), (mp + 3 : U32), (mp - 9 : U32))
  ymd.fix((yoe + (era * 400) : U32), m, d)

# Naming days and times
# ---------------------

def nth(xs: List<&2, String>, +i: U32) -> String:
  match xs:
    case Nil{}:
      "?"
    case +x <> t:
      Bool.pick(String, U32.is_eq(i, 0), x, nth(t, (i - 1 : U32)))

# 0 is Monday.
def wday(+days: U32) -> U32:
  ((days + 3) % 7 : U32)

def wday.short(+days: U32) -> String:
  nth(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], wday(days))

def wday.long(+days: U32) -> String:
  nth(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], wday(days))

def month.short(+m: U32) -> String:
  nth(["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"], (m - 1 : U32))

def month.long(+m: U32) -> String:
  nth(["January", "February", "March", "April", "May", "June", "July", "August", "September", "October",
       "November", "December"], (m - 1 : U32))

# "Wed 18 Nov"
def day.short.of(+days: U32, c: Ymd) -> String:
  match c:
    case Ymd{y, +m, +d}:
      wday.short(days) ++ " " ++ U32.show(d) ++ " " ++ month.short(m)

def day.short(+days: U32) -> String:
  day.short.of(days, civil(days))

# "Wed 18"
def day.tab.of(+days: U32, c: Ymd) -> String:
  match c:
    case Ymd{y, m, +d}:
      wday.short(days) ++ " " ++ U32.show(d)

def day.tab(+days: U32) -> String:
  day.tab.of(days, civil(days))

# "Wednesday 18 November 2026"
def day.long.of(+days: U32, c: Ymd) -> String:
  match c:
    case Ymd{+y, +m, +d}:
      wday.long(days) ++ " " ++ U32.show(d) ++ " " ++ month.long(m) ++ " " ++ U32.show(y)

def day.long(+days: U32) -> String:
  day.long.of(days, civil(days))

def hour12(+h: U32) -> U32:
  Bool.pick(U32, U32.is_eq((h % 12 : U32), 0), 12, (h % 12 : U32))

# A minute's clock time, on a 24-hour clock ("09:30") or a 12-hour one
# ("9:30 AM").
def clock.at(h12: Bool, +h: U32, +mm: U32) -> String:
  match h12:
    case False{}:
      pad2(h) ++ ":" ++ pad2(mm)
    case True{}:
      U32.show(hour12(h)) ++ ":" ++ pad2(mm) ++ Bool.pick(String, U32.is_lt(h, 12), " AM", " PM")

def clock(h12: Bool, +min: U32) -> String:
  clock.at(h12, ((min % 1440) / 60 : U32), (min % 60 : U32))

# The owner's zone: Mexico City, UTC-6 all year (Mexico keeps no summer time
# since 2022).
def cdmx(+utc: U32) -> U32:
  (utc - 360 : U32)

# Reading slots.json
# ------------------
#
# horas writes {"zone":"...","generated":"<UTC>","slots":["<UTC>",...]}, each
# time as 2026-11-18T15:00:00Z. A file that is not that shape gives nothing,
# and the page offers the plain email link.

def ch.is(+c: Char, +k: Char) -> Bool:
  U32.is_eq(Char.to_u32(c), Char.to_u32(k))

def ch.fits(+c: Char, +k: Char) -> Bool:
  Bool.pick(Bool, ch.is(k, 'd'), Char.is_digit(c), ch.is(c, k))

def shape(s: String, p: String) -> Bool:
  match s p:
    case SNil{} SNil{}:
      True{}
    case SCon{+c, st} SCon{+k, pt}:
      Bool.and(ch.fits(c, k), shape(st, pt))
    case _ _:
      False{}

def iso.ok(+s: String) -> Bool:
  Bool.and(shape(s, "dddd-dd-ddTdd:dd:ddZ"),
    Bool.and(Bool.and(U32.is_le(1, num(s, 5n, 2n)), U32.is_le(num(s, 5n, 2n), 12)),
      Bool.and(Bool.and(U32.is_le(1, num(s, 8n, 2n)), U32.is_le(num(s, 8n, 2n), 31)),
        Bool.and(U32.is_lt(num(s, 11n, 2n), 24), Bool.and(U32.is_lt(num(s, 14n, 2n), 60), U32.is_lt(num(s, 17n, 2n), 60))))))

def iso.min(+s: String) -> U32:
  ((days.of(num(s, 0n, 4n), num(s, 5n, 2n), num(s, 8n, 2n)) * 1440) + (num(s, 11n, 2n) * 60) + num(s, 14n, 2n) : U32)

def iso.sec(+s: String) -> U32:
  ((iso.min(s) * 60) + num(s, 17n, 2n) : U32)

# (These scan a string with a loop, a def calling itself last, deciding by a
# Bool it is handed: Bool.pick would take both sides computed, and a thunk
# per character would nest as deep as the text is long.)

def after.go(s: String, hit: Bool, +key: String) -> String:
  match s hit:
    case SNil{} _:
      SNil{}
    case SCon{c, t} True{}:
      String.drop(SCon{c, t}, String.length(key))
    case SCon{c, +t} False{}:
      after.go(t, String.starts_with(t, key), key)

# The text after the first `key` in s, or "".
def after(+s: String, +key: String) -> String:
  after.go(s, String.starts_with(s, key), key)

def at.char(s: String, +c: Char) -> Bool:
  match s:
    case SNil{}:
      False{}
    case SCon{+h, t}:
      ch.is(h, c)

def upto.go(s: String, hit: Bool, +c: Char, acc: String) -> String:
  match s hit:
    case SNil{} _:
      String.reverse(acc)
    case SCon{h, t} True{}:
      String.reverse(acc)
    case SCon{+h, +t} False{}:
      upto.go(t, at.char(t, c), c, SCon{h, acc})

# The text up to the first c.
def upto(+s: String, +c: Char) -> String:
  upto.go(s, at.char(s, c), c, SNil{})

# A quoted time, "2026-11-18T15:00:00Z", as its minute.
def quoted(+q: String) -> Maybe<&2, U32>:
  +s : String = String.take(String.drop(q, 1n), 20n)
  Bool.pick(Maybe<&2, U32>,
    Bool.and(shape(q, "\"dddd-dd-ddTdd:dd:ddZ\""), iso.ok(s)), Some{iso.min(s)}, None{})

def quoted.all(xs: List<&2, String>) -> Maybe<&2, List<&2, U32>>:
  match xs:
    case Nil{}:
      Some{Nil{}}
    case +x <> t:
      do Maybe<&2, List<&2, U32>>:
        m : U32 <- quoted(String.trim(x))
        r : List<&2, U32> <- quoted.all(t)
        return m <> r

# "" holds no slot; else the items between the commas.
def items(+s: String) -> Maybe<&2, List<&2, U32>>:
  Bool.pick(Maybe<&2, List<&2, U32>>, String.is_empty(String.trim(s)), Some{Nil{}}, quoted.all(String.split(s, ',')))

type Feed is Data:
  Feed{+gen: U32, +mins: List<&2, U32>}

def feed.of(+gen: String, m: Maybe<&2, List<&2, U32>>) -> Maybe<&2, Feed>:
  match m:
    case None{}:
      None{}
    case Some{ms}:
      Bool.pick(Maybe<&2, Feed>, iso.ok(gen), Some{Feed{iso.sec(gen), ms}}, None{})

def Feed.read(+text: String) -> Maybe<&2, Feed>:
  feed.of(upto(after(text, "\"generated\":\""), '"'), items(upto(after(text, "\"slots\":["), ']')))

# The browser's clock
# -------------------
#
# shim.js answers "NOW H12 ZONE OFF...": the time now in seconds, 1 if the
# visitor's clock shows 12-hour time, their zone's name, and for each slot the
# minutes their clock is then ahead of UTC, plus 1440 (so none is negative).

type Clock is Data:
  Clock{+now: U32, +h12: Bool, +zone: String, +offs: List<&2, U32>}

def nums(xs: List<&2, String>) -> Maybe<&2, List<&2, U32>>:
  match xs:
    case Nil{}:
      Some{Nil{}}
    case +x <> t:
      do Maybe<&2, List<&2, U32>>:
        v : U32 <- U32.read(x)
        r : List<&2, U32> <- nums(t)
        return v <> r

def clock.parts(ps: List<&2, String>) -> Maybe<&2, Clock>:
  match ps:
    case +n <> +h <> +z <> rest:
      do Maybe<&2, Clock>:
        now : U32 <- U32.read(n)
        offs : List<&2, U32> <- nums(rest)
        return Clock{now, String.eq(h, "1"), z, offs}
    case _:
      None{}

def Clock.read(+s: String) -> Maybe<&2, Clock>:
  clock.parts(String.split(String.trim(s), ' '))

# A slot as the page shows it: its minute in UTC, and on the visitor's clock.
type It is Data:
  It{+utc: U32, +loc: U32}

def It.utc(x: It) -> U32:
  match x:
    case It{u, l}:
      u

def It.loc(x: It) -> U32:
  match x:
    case It{u, l}:
      l

# The day it falls on, on the visitor's clock (days since 1970).
def It.day(x: It) -> U32:
  match x:
    case It{u, +l}:
      (l / 1440 : U32)

# Slots and offsets, pair by pair; None if they do not pair up.
def pair(ms: List<&2, U32>, os: List<&2, U32>) -> Maybe<&2, List<&2, It>>:
  match ms os:
    case Nil{} Nil{}:
      Some{Nil{}}
    case +m <> mt +o <> ot:
      Maybe.map(&2, List<&2, It>, List<&2, It>, r => It{m, ((m + o) - 1440 : U32)} <> r, pair(mt, ot))
    case _ _:
      None{}

# What the page offers
# --------------------

# The slots that have not started by `now` (seconds).
def after.now(+now: U32, x: It) -> Bool:
  U32.is_le(now, (It.utc(x) * 60 : U32))

def upcoming(xs: List<&2, It>, +now: U32) -> List<&2, It>:
  match xs:
    case Nil{}:
      Nil{}
    case +x <> t:
      List.filter.put(It, x, upcoming(t, now), after.now(now, x))

# A list made at `gen` is fresh for 7 days.
def fresh(+now: U32, +gen: U32) -> Bool:
  U32.is_lt(now, (gen + 604800 : U32))

# The slots by day: a day (on the visitor's clock) and its slots, in order.
type Day is Data:
  Day{+key: U32, +items: List<&2, It>}

def put.if(same: Bool, +x: It, +k: U32, its: List<&2, It>, rest: List<&2, Day>) -> List<&2, Day>:
  match same:
    case True{}:
      Day{k, x <> its} <> rest
    case False{}:
      Day{It.day(x), [x]} <> Day{k, its} <> rest

def put(+x: It, ds: List<&2, Day>) -> List<&2, Day>:
  match ds:
    case Nil{}:
      [Day{It.day(x), [x]}]
    case Day{+k, its} <> rest:
      put.if(U32.is_eq(It.day(x), k), x, k, its, rest)

def group(xs: List<&2, It>) -> List<&2, Day>:
  match xs:
    case Nil{}:
      Nil{}
    case +x <> t:
      put(x, group(t))

# The days' slots, one after another.
def flat(ds: List<&2, Day>) -> List<&2, It>:
  match ds:
    case Nil{}:
      Nil{}
    case Day{k, its} <> rest:
      List.append(&2, It, its, flat(rest))

type Offer is Data:
  # The plain email link.
  Plain{}
  # The slots by day, the day shown, the visitor's zone and clock style.
  Pick{+zone: String, +h12: Bool, +days: List<&2, Day>, +sel: U32}

def offer.of(xs: List<&2, It>, +zone: String, +h12: Bool) -> Offer:
  match xs:
    case Nil{}:
      Plain{}
    case +x <> +t:
      Pick{zone, h12, group(x <> t), It.day(x)}

def offer.if(ok: Bool, xs: List<&2, It>, +now: U32, +zone: String, +h12: Bool) -> Offer:
  match ok:
    case False{}:
      Plain{}
    case True{}:
      offer.of(upcoming(xs, now), zone, h12)

# What the page offers at `now`, from a list made at `gen`.
def offer(+now: U32, +gen: U32, +zone: String, +h12: Bool, xs: List<&2, It>) -> Offer:
  offer.if(fresh(now, gen), xs, now, zone, h12)

def offer.days(o: Offer) -> List<&2, Day>:
  match o:
    case Plain{}:
      Nil{}
    case Pick{z, h, ds, s}:
      ds

# The slots offered, in order.
def shown(o: Offer) -> List<&2, It>:
  flat(offer.days(o))

# What the laws say
# -----------------

def all.after(xs: List<&2, It>, +now: U32) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case x <> t:
      Bool.and(after.now(now, x), all.after(t, now))

def on.day(xs: List<&2, It>, +k: U32) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case x <> t:
      Bool.and(U32.is_eq(It.day(x), k), on.day(t, k))

def all.keyed(ds: List<&2, Day>) -> Bool:
  match ds:
    case Nil{}:
      True{}
    case Day{+k, its} <> rest:
      Bool.and(on.day(its, k), all.keyed(rest))

# The email
# ---------

def hex.digit(+v: U32) -> String:
  +d = (v % 16 : U32)
  SCon{Char.from_u32(Bool.pick(U32, U32.is_lt(d, 10), (d + 48 : U32), (d + 55 : U32))), SNil{}}

def pct.byte(+b: U32) -> String:
  "%" ++ hex.digit((b / 16 : U32)) ++ hex.digit(b)

# A character as UTF-8, each byte %XX.
def pct.utf8.go(b1: Bool, b2: Bool, b3: Bool, +c: U32) -> String:
  match b1 b2 b3:
    case True{} _ _:
      pct.byte(c)
    case False{} True{} _:
      pct.byte((192 + (c / 64) : U32)) ++ pct.byte((128 + (c % 64) : U32))
    case False{} False{} True{}:
      pct.byte((224 + (c / 4096) : U32)) ++ pct.byte((128 + ((c / 64) % 64) : U32)) ++ pct.byte((128 + (c % 64) : U32))
    case False{} False{} False{}:
      pct.byte((240 + (c / 262144) : U32)) ++ pct.byte((128 + ((c / 4096) % 64) : U32)) ++
        pct.byte((128 + ((c / 64) % 64) : U32)) ++ pct.byte((128 + (c % 64) : U32))

def pct.utf8(+c: U32) -> String:
  pct.utf8.go(U32.is_lt(c, 128), U32.is_lt(c, 2048), U32.is_lt(c, 65536), c)

# Kept as it is: A-Z a-z 0-9 - _ . ~ (RFC 3986's unreserved).
def unreserved(+c: U32) -> Bool:
  Bool.or(Bool.or(Bool.and(U32.is_le(65, c), U32.is_le(c, 90)), Bool.and(U32.is_le(97, c), U32.is_le(c, 122))),
    Bool.or(Bool.and(U32.is_le(48, c), U32.is_le(c, 57)),
      Bool.or(Bool.or(U32.is_eq(c, 45), U32.is_eq(c, 95)), Bool.or(U32.is_eq(c, 46), U32.is_eq(c, 126)))))

# A line break is CR LF in a mailto body (RFC 6068).
def pct.pick(keep: Bool, nl: Bool, +c: Char) -> String:
  match keep nl:
    case True{} _:
      SCon{c, SNil{}}
    case False{} True{}:
      "%0D%0A"
    case False{} False{}:
      pct.utf8(Char.to_u32(c))

def pct.char(+c: Char) -> String:
  pct.pick(unreserved(Char.to_u32(c)), U32.is_eq(Char.to_u32(c), 10), c)

def pct(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{+c, t}:
      pct.char(c) ++ pct(t)

def owner() -> String:
  "hhefesto@rdataa.com"

# The plain link: an email with "Free call" as its subject.
def mail.plain() -> String:
  "mailto:" ++ owner() ++ "?subject=" ++ pct("Free call")

# "Wed 18 Nov, 09:30 UTC-6"
def at.cdmx(+utc: U32) -> String:
  day.short((cdmx(utc) / 1440 : U32)) ++ ", " ++ clock(False{}, cdmx(utc)) ++ " UTC-6"

def mail.subject(+x: It) -> String:
  "Free call: " ++ at.cdmx(It.utc(x))

def mail.body(+x: It, +zone: String, +h12: Bool) -> String:
  "Hi Daniel,\n\n" ++
  "I'd like the free 30-minute call on " ++ day.long((cdmx(It.utc(x)) / 1440 : U32)) ++ " at " ++
  clock(False{}, cdmx(It.utc(x))) ++ " UTC-6 (" ++ day.short(It.day(x)) ++ ", " ++ clock(h12, It.loc(x)) ++
  " in my zone, " ++ zone ++ ").\n\n" ++
  "About me and what I'd like to talk about:\n\n\n" ++
  "I understand the call is confirmed once you reply.\n"

# Picking slot x opens this email.
def mail.slot(+x: It, +zone: String, +h12: Bool) -> String:
  "mailto:" ++ owner() ++ "?subject=" ++ pct(mail.subject(x)) ++ "&body=" ++ pct(mail.body(x, zone, h12))
