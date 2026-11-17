import Base
import ../src/Book.bend as K

# Tests of src/Book.bend that the proofs cannot give: the arithmetic and the
# text. The expected strings were made by the browser's own Intl and
# encodeURIComponent (node 22), and GNU date, not by Book.bend:
#
#   new Intl.DateTimeFormat("en-GB", {timeZone, weekday: "short", day: "numeric",
#     month: "short", hour: "2-digit", minute: "2-digit", hourCycle: "h23"})
#   new Intl.DateTimeFormat("en-US", {timeZone, hour: "numeric", minute: "2-digit"})
#
# `bend tests/book.bend` prints "ok" or a FAIL line per test and exits 1 if
# any failed.

def say(ok: Bool, +name: String, +got: String) -> IO(U32):
  match ok:
    case True{}:
      do IO<U32>:
        IO.print("ok   " ++ name)
        return 0
    case False{}:
      do IO<U32>:
        IO.print("FAIL " ++ name ++ ": " ++ got)
        return 1

def finish(ok: Bool, +bad: U32) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("all page tests pass")
    case False{}:
      IO.die(Unit, 1, U32.show(bad) ++ " page tests failed")

def show.mins(xs: List<&2, U32>) -> String:
  match xs:
    case Nil{}:
      ""
    case +x <> t:
      U32.show(x) ++ " " ++ show.mins(t)

def same.mins(xs: List<&2, U32>, ys: List<&2, U32>) -> Bool:
  match xs ys:
    case Nil{} Nil{}:
      True{}
    case +x <> xt +y <> yt:
      Bool.and(U32.is_eq(x, y), same.mins(xt, yt))
    case _ _:
      False{}

def feed.show(m: Maybe<&2, K.Feed>) -> String:
  match m:
    case None{}:
      "none"
    case Some{K.Feed{+g, ms}}:
      U32.show(g) ++ " / " ++ show.mins(ms)

# The list read is the one written.
def feed.is(m: Maybe<&2, K.Feed>, +gen: U32, want: List<&2, U32>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{K.Feed{+g, ms}}:
      Bool.and(U32.is_eq(g, gen), same.mins(ms, want))

def feed.none(m: Maybe<&2, K.Feed>) -> Bool:
  match m:
    case None{}:
      True{}
    case Some{f}:
      False{}

def clock.show(m: Maybe<&2, K.Clock>) -> String:
  match m:
    case None{}:
      "none"
    case Some{K.Clock{+n, +h, +z, os}}:
      U32.show(n) ++ " " ++ Bool.show(h) ++ " " ++ z ++ " " ++ show.mins(os)

def clock.is(m: Maybe<&2, K.Clock>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{K.Clock{+n, +h, +z, os}}:
      Bool.and(Bool.and(U32.is_eq(n, 1795000000), h), Bool.and(String.eq(z, "Europe/Madrid"), same.mins(os, [1500, 1500, 960])))

# A slot on a clock `off` minutes ahead of UTC, as the page names it:
# "Wed 18 Nov, 16:00 | 4:00 PM".
def local(+utc: U32, +off: U32) -> String:
  +x : K.It = K.It{utc, ((utc + off) - 1440 : U32)}
  K.day.short(K.It.day(x)) ++ ", " ++ K.clock(False{}, K.It.loc(x)) ++ " | " ++ K.clock(True{}, K.It.loc(x))

def local.is(+utc: U32, +off: U32, +want: String) -> IO(U32):
  say(String.eq(local(utc, off), want), "local time " ++ want, local(utc, off))

def its.utc(xs: List<&2, K.It>) -> List<&2, U32>:
  match xs:
    case Nil{}:
      Nil{}
    case x <> r:
      K.It.utc(x) <> its.utc(r)

def days.show(ds: List<&2, K.Day>) -> String:
  match ds:
    case Nil{}:
      ""
    case K.Day{+k, its} <> r:
      U32.show(k) ++ "=" ++ show.mins(its.utc(its)) ++ "; " ++ days.show(r)

def offer.show(o: K.Offer) -> String:
  match o:
    case K.Plain{}:
      "plain"
    case K.Pick{z, h, ds, +s}:
      "pick, day " ++ U32.show(s) ++ ": " ++ days.show(ds)

def show.locs(xs: List<&2, K.It>) -> String:
  match xs:
    case Nil{}:
      ""
    case +x <> r:
      U32.show(K.It.utc(x)) ++ ">" ++ U32.show(K.It.loc(x)) ++ " " ++ show.locs(r)

def text.of(o: K.Offer) -> String:
  offer.show(o)

def sample() -> String:
  "{\"zone\":\"America/Mexico_City\",\"generated\":\"2026-11-17T18:01:14Z\",\"slots\":[\"2026-11-18T15:00:00Z\",\"2026-11-18T22:30:00Z\",\"2027-03-15T15:00:00Z\"]}\n"

# Slots on a clock 60 minutes ahead (Madrid): 2026-11-18 15:00, 22:30 and
# 23:30 UTC (the last is past midnight there), and 2026-11-19 15:00.
def its() -> List<&2, K.It>:
  [K.It{29916900, 29916960}, K.It{29917350, 29917410}, K.It{29917410, 29917470}, K.It{29918340, 29918400}]

# The same, and one in March 2027, after every `now` below.
def its.later() -> List<&2, K.It>:
  List.append(&2, K.It, its(), [K.It{30085380, 30085440}])

def pair.show(m: Maybe<&2, List<&2, K.It>>) -> String:
  match m:
    case None{}:
      "none"
    case Some{xs}:
      show.locs(xs)

def main() -> IO(Unit):
  do IO<Unit>:
    a : U32 <- say(feed.is(K.Feed.read(sample()), 1794938474, [29916900, 29917350, 30085380]),
                   "slots.json as horas writes it is read", feed.show(K.Feed.read(sample())))
    b : U32 <- say(feed.is(K.Feed.read("{\"zone\":\"America/Mexico_City\",\"generated\":\"2026-11-17T18:01:14Z\",\"slots\":[]}"), 1794938474, []),
                   "an empty list is read as no slots", "")
    c : U32 <- say(Bool.and(Bool.and(feed.none(K.Feed.read("")), feed.none(K.Feed.read("<html>404 Not Found</html>"))),
                   Bool.and(feed.none(K.Feed.read("{\"generated\":\"2026-11-17T18:01:14Z\",\"slots\":[\"2026-13-18T15:00:00Z\"]}")),
                   Bool.and(feed.none(K.Feed.read("{\"generated\":\"yesterday\",\"slots\":[]}")),
                            feed.none(K.Feed.read("{\"generated\":\"2026-11-17T18:01:14Z\",\"slots\":[\"2026-11-18T15:00:00Z\",\"<b>\"]}"))))),
                   "a missing or malformed list is not read", "")
    d : U32 <- say(clock.is(K.Clock.read("1795000000 1 Europe/Madrid 1500 1500 960")), "the browser's clock is read",
                   clock.show(K.Clock.read("1795000000 1 Europe/Madrid 1500 1500 960")))
    e1 : U32 <- local.is(29916900, 1080, "Wed 18 Nov, 09:00 | 9:00 AM")
    e2 : U32 <- local.is(29917350, 1080, "Wed 18 Nov, 16:30 | 4:30 PM")
    e3 : U32 <- local.is(29917350, 1500, "Wed 18 Nov, 23:30 | 11:30 PM")
    e4 : U32 <- local.is(29917350, 1770, "Thu 19 Nov, 04:00 | 4:00 AM")
    e5 : U32 <- local.is(29916900, 1770, "Wed 18 Nov, 20:30 | 8:30 PM")
    e6 : U32 <- local.is(29916900, 2220, "Thu 19 Nov, 04:00 | 4:00 AM")
    e7 : U32 <- local.is(30085380, 2220, "Tue 16 Mar, 04:00 | 4:00 AM")
    e8 : U32 <- local.is(29917350, 960, "Wed 18 Nov, 14:30 | 2:30 PM")
    e9 : U32 <- local.is(30085380, 1020, "Mon 15 Mar, 08:00 | 8:00 AM")
    e10 : U32 <- local.is(29916900, 1230, "Wed 18 Nov, 11:30 | 11:30 AM")
    e11 : U32 <- local.is(30085380, 1290, "Mon 15 Mar, 12:30 | 12:30 PM")
    f : U32 <- say(Bool.and(String.eq(K.clock(True{}, 0), "12:00 AM"), Bool.and(String.eq(K.clock(True{}, 720), "12:00 PM"),
                   String.eq(K.clock(True{}, 1439), "11:59 PM"))), "midnight and noon on a 12-hour clock",
                   K.clock(True{}, 0) ++ " " ++ K.clock(True{}, 720) ++ " " ++ K.clock(True{}, 1439))
    g : U32 <- say(String.eq(K.at.cdmx(29916900), "Wed 18 Nov, 09:00 UTC-6"), "my time, UTC-6", K.at.cdmx(29916900))
    h : U32 <- say(Bool.and(String.eq(K.pct("Free call: Wed 18 Nov, 09:30 UTC-6"), "Free%20call%3A%20Wed%2018%20Nov%2C%2009%3A30%20UTC-6"),
                   String.eq(K.pct("a\nb (c) é → 😀 ~._-!*'"), "a%0D%0Ab%20%28c%29%20%C3%A9%20%E2%86%92%20%F0%9F%98%80%20~._-%21%2A%27")),
                   "percent-encoding agrees with encodeURIComponent (CR LF for a line break)",
                   K.pct("a\nb (c) é → 😀 ~._-!*'"))
    i : U32 <- say(String.eq(K.mail.plain(), "mailto:hhefesto@rdataa.com?subject=Free%20call"), "the plain link is the old one", K.mail.plain())
    j : U32 <- say(String.starts_with(K.mail.slot(K.It{29916900, 29916960}, "Europe/Madrid", False{}),
                   "mailto:hhefesto@rdataa.com?subject=Free%20call%3A%20Wed%2018%20Nov%2C%2009%3A00%20UTC-6&body=Hi%20Daniel%2C%0D%0A%0D%0AI%27d%20like%20the%20free%2030-minute%20call%20on%20Wednesday%2018%20November%202026%20at%2009%3A00%20UTC-6%20%28Wed%2018%20Nov%2C%2016%3A00%20in%20my%20zone%2C%20Europe%2FMadrid%29."),
                   "a slot's email names it in my time and the visitor's", K.mail.slot(K.It{29916900, 29916960}, "Europe/Madrid", False{}))
    k : U32 <- say(String.eq(text.of(K.offer(1794938474, 1794938474, "Europe/Madrid", False{}, its())),
                   "pick, day 20775: 20775=29916900 29917350 ; 20776=29917410 29918340 ; "),
                   "slots are grouped by the visitor's day", text.of(K.offer(1794938474, 1794938474, "Europe/Madrid", False{}, its())))
    l : U32 <- say(String.eq(text.of(K.offer(1795041001, 1794938474, "Europe/Madrid", False{}, its())),
                   "pick, day 20776: 20776=29917410 29918340 ; "),
                   "slots that have started are not offered", text.of(K.offer(1795041001, 1794938474, "Europe/Madrid", False{}, its())))
    m : U32 <- say(String.eq(text.of(K.offer(1795543274, 1794938474, "Europe/Madrid", False{}, its.later())), "plain"),
                   "a list 7 days old gives the plain link", text.of(K.offer(1795543274, 1794938474, "Europe/Madrid", False{}, its.later())))
    n : U32 <- say(String.eq(text.of(K.offer(1795543273, 1794938474, "Europe/Madrid", False{}, its())), "plain"),
                   "a list whose slots are all past gives the plain link", text.of(K.offer(1795543273, 1794938474, "Europe/Madrid", False{}, its())))
    p : U32 <- say(String.eq(pair.show(K.pair([29916900, 29916900, 29916900], [1500, 960, 1770])), "29916900>29916960 29916900>29916420 29916900>29917230 "),
                   "the visitor's clock is UTC plus the offset the browser gave", pair.show(K.pair([29916900, 29916900, 29916900], [1500, 960, 1770])))
    q : U32 <- say(String.eq(pair.show(K.pair([29916900, 29916900], [1500])), "none"), "slots and offsets that do not pair up give nothing", "")
    +bad : U32 = (a + b + p + q + c + d + e1 + e2 + e3 + e4 + e5 + e6 + e7 + e8 + e9 + e10 + e11 + f + g + h + i + j + k + l + m + n : U32)
    finish(U32.is_eq(bad, 0), bad)
