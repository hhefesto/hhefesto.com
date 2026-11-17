# The claims of the page's booking logic (src/Book.bend): what it offers a
# visitor who wants the free call. PROOF.bend proves them; a law that turns
# out false is reported, not reworded.
#
# The page reads the open slots horas publishes and the visitor's clock, and
# offers K.offer(now, gen, zone, h12, xs): the plain email link, or the slots
# grouped by day. xs are the slots on both clocks (UTC and the visitor's),
# `now` the time in seconds and `gen` when the list was made.

import Base
import ./src/Book.bend as K

# Grouping by day neither loses, adds nor reorders a slot.
law group_flat:
  for xs: List<&2, K.It>
  {K.flat(K.group(xs)) == xs : List<&2, K.It>}

# Every slot is listed under the day it falls on, on the visitor's clock.
law group_keyed:
  for xs: List<&2, K.It>
  {K.all.keyed(K.group(xs)) == True{} : Bool}

# No slot offered has started.
law shown_future:
  for +now: U32
  for +gen: U32
  for +zone: String
  for +h12: Bool
  for +xs: List<&2, K.It>
  {K.all.after(K.shown(K.offer(now, gen, zone, h12, xs)), now) == True{} : Bool}

# The days offered list each slot under its own day.
law offer_keyed:
  for +now: U32
  for +gen: U32
  for +zone: String
  for +h12: Bool
  for +xs: List<&2, K.It>
  {K.all.keyed(K.offer.days(K.offer(now, gen, zone, h12, xs))) == True{} : Bool}

# A list that is no longer fresh gives the plain email link.
law stale_plain:
  for +now: U32
  for +gen: U32
  for +zone: String
  for +h12: Bool
  for +xs: List<&2, K.It>
  for e: {K.fresh(now, gen) == False{} : Bool}
  {K.offer(now, gen, zone, h12, xs) == K.Plain{} : K.Offer}

# So does a list with no slot still to come.
law none_plain:
  for +now: U32
  for +gen: U32
  for +zone: String
  for +h12: Bool
  for +xs: List<&2, K.It>
  for e: {K.upcoming(xs, now) == Nil{} : List<&2, K.It>}
  {K.offer(now, gen, zone, h12, xs) == K.Plain{} : K.Offer}
