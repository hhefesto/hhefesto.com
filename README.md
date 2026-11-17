# hhefesto.dev

My landing page, written in [Bend](https://bend-lang.com) as a
[bend-frp](https://github.com/hhefesto/bend-frp) app: the page is a view of its
state, and its state a fold of what happens to it.

| file | what it is |
|---|---|
| `src/index.html` | the page's head, styles, no-JS summary and footer; it mounts the app |
| `src/Main.bend` | the app: every section of the page, and the free call's slot picker |
| `src/Book.bend` | the booking logic: reading the open slots, the visitor's clock, the days, the email |
| `src/shim.js` | the one thing only the browser knows: its clock and time zone |
| `LAWS.bend`, `PROOF.bend` | what the booking logic promises, and the proofs |
| `tests/book.bend` | what the proofs cannot say: dates, times and the email's text, checked against the browser's own `Intl` |
| `public/` | served as it is: `og.png`, `CNAME`, and `slots.json`, which `horas publish` writes |

## Building

```
nix build .#site        # the site as GitHub Pages serves it, in ./result
nix flake check         # that, the tests, and the proofs rechecked by BendTT's kernel
nix develop             # bend (with --verdict) and darkhttpd
darkhttpd result --port 8000
```

`nix build .#site` checks the Bend and the proofs, then bundles the page
(`bend src/index.html -o $out`) and copies `public/` beside it. The flake pins
bend-frp, and Bend through it (2.0.39). `src/Main.bend` imports
`../../bend-frp/Web.bend`, so outside Nix it expects bend-frp checked out next
to this repository (`~/src/bend-frp`), at the commit `flake.lock` names.

Every push runs the same build and the tests on GitHub Actions; a push to
`master` also deploys `result` to GitHub Pages.

## The free call

[horas](https://github.com/hhefesto/horas) publishes my open 30-minute slots
for the next two weeks into `public/slots.json`, and commits it:

```
horas publish            # sync, write public/slots.json, commit (no push)
git push                 # deploys
```

The file holds only the slots' start times in UTC, the zone and when it was
made. The page reads it, asks the browser where each slot falls on the
visitor's clock, and offers the slots still to come by day, in the visitor's
time with mine (UTC-6) beside them. Picking one opens an email to
hhefesto@rdataa.com with the slot in its subject and body; the call is
confirmed when I reply. When the file is missing, malformed, more than 7 days
old or has no slot left, the page offers the plain email link instead.

`LAWS.bend` states, and `PROOF.bend` proves (`bend PROOF.bend --verdict`):

- `group_flat`: grouping the slots by day neither loses, adds nor reorders one;
- `group_keyed`, `offer_keyed`: every slot is listed under the day it falls on
  in the visitor's time;
- `shown_future`: no slot offered has started;
- `stale_plain`, `none_plain`: a list more than 7 days old, or with no slot
  still to come, gives the plain email link.

A proof that checks says the code does what the law says, not that the law
is all one wants, so `tests/book.bend` checks the arithmetic and the text
(local times in six zones with and without summer time, 12- and 24-hour
clocks, the email's encoding against `encodeURIComponent`). Planted bugs make
each fail: those in the logic fail the proofs, those in the arithmetic fail
the tests.
