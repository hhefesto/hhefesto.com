# The proofs of LAWS.bend. Nothing here is trusted: `bend PROOF.bend` checks
# every def, and `--verdict` rechecks them with BendTT's kernel.

import Base
import ./src/Book.bend as K
import ./LAWS.bend as Laws

# Bool
# ----

def bdisc(b: Bool) -> Type:
  match b:
    case True{}:
      Empty
    case False{}:
      Unit

def ft(h: {False{} == True{} : Bool}) -> Empty:
  %h : bdisc(_)
  Unit{}

def no(-A: Type, h: {False{} == True{} : Bool}) -> A:
  Empty.absurd(A, ft(h))

def and_l(a: Bool, -b: Bool) -> {Bool.and(a, b) == True{} : Bool} -> {a == True{} : Bool}:
  match a:
    case True{}:
      h => {==}
    case False{}:
      h => no({False{} == True{} : Bool}, h)

def and_r(a: Bool, -b: Bool) -> {Bool.and(a, b) == True{} : Bool} -> {b == True{} : Bool}:
  match a:
    case True{}:
      h => h
    case False{}:
      h => no({b == True{} : Bool}, h)

def and_i(a: Bool, -b: Bool) -> {a == True{} : Bool} -> {b == True{} : Bool} -> {Bool.and(a, b) == True{} : Bool}:
  match a:
    case True{}:
      ha => hb => hb
    case False{}:
      ha => hb => no({False{} == True{} : Bool}, ha)

def cons_cong(-A: Data, -h: A, -a: List<&2, A>, -b: List<&2, A>, e: {a == b : List<&2, A>}) -> {h <> a == h <> b : List<&2, A>}:
  %e : {h <> a == h <> _ : List<&2, A>}
  {==}

# A U32 equals itself (by its 32 bits)
# -----------------------------------

def bcmp_refl(b: Bool) -> {Bool.cmp(b, b) == EQ{} : Cmp}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def wcmp_refl(n: Nat, a: Word(n)) -> {Word.cmp(n, a, a) == EQ{} : Cmp}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      match a:
        case WCon{ab, at}:
          %Equal.sym(Cmp, Word.cmp(p, at, at), EQ{}, wcmp_refl(p, at)) : {Word.cmp.fin(ab, ab, _) == EQ{} : Cmp}
          bcmp_refl(ab)

def u32_eq_refl(a: U32) -> {U32.is_eq(a, a) == True{} : Bool}:
  match a:
    case U32{w}:
      %Equal.sym(Cmp, Word.cmp(32n, w, w), EQ{}, wcmp_refl(32n, w)) : {Cmp.is_eq(_) == True{} : Bool}
      {==}

# Grouping keeps the slots
# ------------------------

def put_if_flat(same: Bool, +x: K.It, +k: U32, its: List<&2, K.It>, rest: List<&2, K.Day>) ->
    {K.flat(K.put.if(same, x, k, its, rest)) == x <> K.flat(K.Day{k, its} <> rest) : List<&2, K.It>}:
  match same:
    case True{}:
      {==}
    case False{}:
      {==}

def put_flat(+x: K.It, ds: List<&2, K.Day>) -> {K.flat(K.put(x, ds)) == x <> K.flat(ds) : List<&2, K.It>}:
  match ds:
    case Nil{}:
      {==}
    case K.Day{+k, its} <> rest:
      put_if_flat(U32.is_eq(K.It.day(x), k), x, k, its, rest)

def Laws.group_flat(xs):
  match xs:
    case Nil{}:
      {==}
    case +x <> +t:
      Equal.trans(List<&2, K.It>, K.flat(K.put(x, K.group(t))), x <> K.flat(K.group(t)), x <> t,
                  put_flat(x, K.group(t)), cons_cong(K.It, x, K.flat(K.group(t)), t, Laws.group_flat(t)))

# Grouping puts each slot under its day
# -------------------------------------

def single_on(+x: K.It) -> {K.on.day([x], K.It.day(x)) == True{} : Bool}:
  %Equal.sym(Bool, U32.is_eq(K.It.day(x), K.It.day(x)), True{}, u32_eq_refl(K.It.day(x))) : {Bool.and(_, True{}) == True{} : Bool}
  {==}

def put_if_keyed(same: Bool, +x: K.It, +k: U32, +its: List<&2, K.It>, +rest: List<&2, K.Day>) ->
    {U32.is_eq(K.It.day(x), k) == same : Bool} ->
    {K.all.keyed(K.Day{k, its} <> rest) == True{} : Bool} ->
    {K.all.keyed(K.put.if(same, x, k, its, rest)) == True{} : Bool}:
  match same:
    case True{}:
      e => +h => and_i(Bool.and(U32.is_eq(K.It.day(x), k), K.on.day(its, k)), K.all.keyed(rest),
                      and_i(U32.is_eq(K.It.day(x), k), K.on.day(its, k), e, and_l(K.on.day(its, k), K.all.keyed(rest), h)),
                      and_r(K.on.day(its, k), K.all.keyed(rest), h))
    case False{}:
      e => h => and_i(K.on.day([x], K.It.day(x)), K.all.keyed(K.Day{k, its} <> rest), single_on(x), h)

def put_keyed(+x: K.It, ds: List<&2, K.Day>) ->
    {K.all.keyed(ds) == True{} : Bool} -> {K.all.keyed(K.put(x, ds)) == True{} : Bool}:
  match ds:
    case Nil{}:
      h => and_i(K.on.day([x], K.It.day(x)), True{}, single_on(x), {==})
    case K.Day{+k, +its} <> +rest:
      h => put_if_keyed(U32.is_eq(K.It.day(x), k), x, k, its, rest, {==}, h)

def Laws.group_keyed(xs):
  match xs:
    case Nil{}:
      {==}
    case +x <> +t:
      put_keyed(x, K.group(t), Laws.group_keyed(t))

# What is offered has not started
# -------------------------------

def up_put(c: Bool, +x: K.It, r: List<&2, K.It>, +now: U32) ->
    {K.after.now(now, x) == c : Bool} -> {K.all.after(r, now) == True{} : Bool} ->
    {K.all.after(List.filter.put(K.It, x, r, c), now) == True{} : Bool}:
  match c:
    case True{}:
      e => ih => and_i(K.after.now(now, x), K.all.after(r, now), e, ih)
    case False{}:
      e => ih => ih

def up_after(xs: List<&2, K.It>, +now: U32) -> {K.all.after(K.upcoming(xs, now), now) == True{} : Bool}:
  match xs:
    case Nil{}:
      {==}
    case +x <> +t:
      up_put(K.after.now(now, x), x, K.upcoming(t, now), now, {==}, up_after(t, now))

def of_after.go(+x: K.It, +t: List<&2, K.It>, +now: U32, h: {K.all.after(x <> t, now) == True{} : Bool}) ->
    {K.all.after(K.flat(K.group(x <> t)), now) == True{} : Bool}:
  %Equal.sym(List<&2, K.It>, K.flat(K.group(x <> t)), x <> t, Laws.group_flat(x <> t)) : {K.all.after(_, now) == True{} : Bool}
  h

def of_after(xs: List<&2, K.It>, +now: U32, +zone: String, +h12: Bool) ->
    {K.all.after(xs, now) == True{} : Bool} ->
    {K.all.after(K.shown(K.offer.of(xs, zone, h12)), now) == True{} : Bool}:
  match xs:
    case Nil{}:
      h => {==}
    case +x <> +t:
      h => of_after.go(x, t, now, h)

def if_after(ok: Bool, +xs: List<&2, K.It>, +now: U32, +zone: String, +h12: Bool) ->
    {K.all.after(K.shown(K.offer.if(ok, xs, now, zone, h12)), now) == True{} : Bool}:
  match ok:
    case False{}:
      {==}
    case True{}:
      of_after(K.upcoming(xs, now), now, zone, h12, up_after(xs, now))

def Laws.shown_future(now, gen, zone, h12, xs):
  if_after(K.fresh(now, gen), xs, now, zone, h12)

# What is offered is listed by day
# --------------------------------

def of_keyed(xs: List<&2, K.It>, +zone: String, +h12: Bool) ->
    {K.all.keyed(K.offer.days(K.offer.of(xs, zone, h12))) == True{} : Bool}:
  match xs:
    case Nil{}:
      {==}
    case +x <> +t:
      Laws.group_keyed(x <> t)

def if_keyed(ok: Bool, +xs: List<&2, K.It>, +now: U32, +zone: String, +h12: Bool) ->
    {K.all.keyed(K.offer.days(K.offer.if(ok, xs, now, zone, h12))) == True{} : Bool}:
  match ok:
    case False{}:
      {==}
    case True{}:
      of_keyed(K.upcoming(xs, now), zone, h12)

def Laws.offer_keyed(now, gen, zone, h12, xs):
  if_keyed(K.fresh(now, gen), xs, now, zone, h12)

# When the plain link is offered
# ------------------------------

def Laws.stale_plain(now, gen, zone, h12, xs, e):
  %Equal.sym(Bool, K.fresh(now, gen), False{}, e) : {K.offer.if(_, xs, now, zone, h12) == K.Plain{} : K.Offer}
  {==}

def none_if(ok: Bool, +xs: List<&2, K.It>, +now: U32, +zone: String, +h12: Bool,
            e: {K.upcoming(xs, now) == Nil{} : List<&2, K.It>}) ->
    {K.offer.if(ok, xs, now, zone, h12) == K.Plain{} : K.Offer}:
  match ok:
    case False{}:
      {==}
    case True{}:
      %Equal.sym(List<&2, K.It>, K.upcoming(xs, now), Nil{}, e) : {K.offer.of(_, zone, h12) == K.Plain{} : K.Offer}
      {==}

def Laws.none_plain(now, gen, zone, h12, xs, e):
  none_if(K.fresh(now, gen), xs, now, zone, h12, e)
