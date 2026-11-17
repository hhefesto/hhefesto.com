import Base
import ../../bend-frp/Web.bend as W
import ./Book.bend as K

# hhefesto.dev, as a bend-frp app: the page is a view of its state, and its
# state a fold of what happens to it (bend-frp's runtime.js turns the
# browser's events into inputs and patches the DOM).
#
# Almost all of the page never changes. What does is the free call: the page
# asks for slots.json (the open slots horas publishes), then asks the
# browser's clock (shim.js) where each slot falls for the visitor, and offers
# the slots by day, each a link to an email with the slot filled in. Until
# then, or when the list is missing, stale or empty, it offers the plain
# email link (Book.bend's laws).

# State
# -----

type S is Data:
  # Asking for slots.json.
  Asking{}
  # Asking the browser's clock about these slots.
  Timing{+feed: K.Feed}
  # What the page offers.
  Offered{+offer: K.Offer}

def init() -> S:
  Asking{}

def mins(f: K.Feed) -> List<&2, U32>:
  match f:
    case K.Feed{g, ms}:
      ms

def mins.text(ms: List<&2, U32>) -> String:
  match ms:
    case Nil{}:
      ""
    case +m <> t:
      U32.show(m) ++ " " ++ mins.text(t)

# slots.json came: ask the clock about its slots.
def fed(m: Maybe<&2, K.Feed>) -> S & List<&2, W.Effect>:
  match m:
    case None{}:
      (Offered{K.Plain{}}, [])
    case Some{+f}:
      (Timing{f}, [W.Host{"clock", "clock", mins.text(mins(f))}])

# The clock answered: what to offer.
def timed.with(f: K.Feed, c: K.Clock, m: Maybe<&2, List<&2, K.It>>) -> K.Offer:
  match f c m:
    case K.Feed{+g, ms} K.Clock{+now, +h12, +zone, offs} Some{xs}:
      K.offer(now, g, zone, h12, xs)
    case _ _ _:
      K.Plain{}

def clock.offs(k: K.Clock) -> List<&2, U32>:
  match k:
    case K.Clock{n, h, z, o}:
      o

def timed.of(+f: K.Feed, m: Maybe<&2, K.Clock>) -> K.Offer:
  match m:
    case None{}:
      K.Plain{}
    case Some{+k}:
      timed.with(f, k, K.pair(mins(f), clock.offs(k)))

def timed(s: S, +v: String) -> S:
  match s:
    case Timing{+f}:
      Offered{timed.of(f, K.Clock.read(v))}
    case other:
      other

# A day picked: show its slots.
def pick.day(o: K.Offer, m: Maybe<&2, U32>) -> K.Offer:
  match o m:
    case K.Pick{z, h, ds, s} Some{k}:
      K.Pick{z, h, ds, k}
    case o2 _:
      o2

def picked(s: S, +v: String) -> S:
  match s:
    case Offered{o}:
      Offered{pick.day(o, U32.read(v))}
    case other:
      other

type Msg is Data:
  MStart{}
  MSlots{+text: String}
  MNoSlots{}
  MClock{+text: String}
  MDay{+key: String}
  MOther{}

def msg.pick(st: Bool, sl: Bool, nf: Bool, cl: Bool, dy: Bool, +tag: String, +v: String) -> Msg:
  match st sl nf cl dy:
    case True{} _ _ _ _:
      MStart{}
    case False{} True{} _ _ _:
      MSlots{v}
    case False{} False{} True{} _ _:
      MNoSlots{}
    case False{} False{} False{} True{} _:
      MClock{v}
    case False{} False{} False{} False{} True{}:
      MDay{String.drop(tag, 4n)}
    case False{} False{} False{} False{} False{}:
      MOther{}

def msg.of(+tag: String, +v: String) -> Msg:
  msg.pick(String.eq(tag, "start"), String.eq(tag, "slots"), String.eq(tag, "slots:failed"),
           String.eq(tag, "clock"), String.starts_with(tag, "day:"), tag, v)

def apply(s: S, m: Msg) -> S & List<&2, W.Effect>:
  match m:
    case MStart{}:
      (s, [W.Http{"slots", "GET", "./slots.json", ""}])
    case MSlots{+t}:
      fed(K.Feed.read(t))
    case MNoSlots{}:
      (Offered{K.Plain{}}, [])
    case MClock{+t}:
      (timed(s, t), [])
    case MDay{+k}:
      (picked(s, k), [])
    case MOther{}:
      (s, [])

def update(s: S, i: W.Input) -> S & List<&2, W.Effect>:
  match i:
    case W.Input{at, +tag, +v}:
      apply(s, msg.of(tag, v))

# Views
# -----

def c(+s: String) -> W.Attr:
  W.Prop{"class", s}

def t(+s: String) -> W.Html:
  W.text(s)

def div(+cl: String, kids: List<&2, W.Html>) -> W.Html:
  W.el("div", [c(cl)], kids)

def ext(+url: String, +label: String) -> W.Html:
  W.el("a", [W.Prop{"href", url}, W.Prop{"target", "_blank"}, W.Prop{"rel", "noopener"}], [t(label)])

def section(+sid: String, +title: String, body: List<&2, W.Html>) -> W.Html:
  W.el("section", [W.Prop{"id", sid}, c("section container")],
    W.el("h2", [c("section-title")], [t(title)]) <> body)

def lis(xs: List<&2, String>) -> List<&2, W.Html>:
  match xs:
    case Nil{}:
      Nil{}
    case +x <> r:
      W.el("li", [], [t(x)]) <> lis(r)

# Every "Book a free call" button leads to the contact section, and only that
# section holds the email links.
def book.call(+cls: String) -> W.Html:
  W.el("a", [c(cls), W.Prop{"href", "#contact"}], [t("Book a free call")])

def badge(+s: String) -> W.Html:
  div("badge", [t(s)])

# Hero

def first.step() -> W.Html:
  div("card pricing-card pricing-card--hero",
    [div("card-kicker", [t("A fixed-price first step")]),
     W.el("h3", [c("card-title")], [t("One-week audit")]),
     W.el("p", [c("muted")], [t("I review your builds, deploys and infrastructure, and hand you a written, prioritised plan plus the first fixes. The price is fixed and agreed before we start; the first call is free.")]),
     W.el("ul", [c("list-compact")],
       lis(["✅ What breaks reproducibility today, and why",
            "✅ A dev → staging → prod plan with testing gates",
            "✅ The first fixes, done that same week"])),
     div("card-actions", [book.call("btn btn-primary btn-block")]),
     div("card-footnote", [t("I usually reply within 4 hours during UTC-6 business hours.")])])

def hero() -> W.Html:
  W.el("section", [c("hero container")],
    [div("hero-grid",
      [div("hero-content",
        [badge("Nix • Haskell • Bend • Verified software"),
         W.el("h1", [c("hero-title")], [t("Reproducible infrastructure and verified software")]),
         W.el("p", [c("hero-subtitle")],
           [t("I build "), W.el("strong", [], [t("Nix")]),
            t(" dev shells, CI and deploys that behave the same on every machine, and "),
            W.el("strong", [], [t("functional software")]),
            t(" (Haskell, PureScript, Bend) whose key properties are stated as laws and checked by the compiler, not only tested. "),
            t("My own work includes "), ext("https://ana.hhefesto.dev", "ana"),
            t(", a language model specified, trained and evaluated in Bend, and "),
            ext("https://elcubodeedgar.hhefesto.dev", "El cubo de Edgar"),
            t(", an optimal Rubik's cube solver in Bend with its group theory as proven laws.")]),
         div("hero-cta",
           [book.call("btn btn-primary"),
            W.el("a", [c("btn btn-secondary"), W.Prop{"href", "#work"}], [t("See my work")])])]),
       W.el("aside", [c("hero-offer")], [first.step()])])])

# Work

type Link is Data:
  Link{+url: String, +label: String}

def links(xs: List<&2, Link>) -> List<&2, W.Html>:
  match xs:
    case Nil{}:
      Nil{}
    case Link{+u, +l} <> r:
      ext(u, l) <> links(r)

def project(+title: String, ls: List<&2, Link>, +desc: String) -> W.Html:
  div("service-card project-card",
    [W.el("h3", [c("service-title")], [t(title)]),
     W.el("p", [c("service-description")], [t(desc)]),
     div("project-links", links(ls))])

def work() -> W.Html:
  section("work", "Selected work",
    [div("services-grid",
      [project("xpsoasis.org and xesoasis.org",
         [Link{"https://xpsoasis.org", "xpsoasis.org"}, Link{"https://xesoasis.org", "xesoasis.org"}],
         "Architected and built end to end, from first concept to production: infrastructure, CI/CD, reliability and delivery. Both are running systems."),
       project("ana",
         [Link{"https://ana.hhefesto.dev", "ana.hhefesto.dev"}, Link{"https://github.com/hhefesto/ana", "GitHub"}],
         "A 115M-parameter language model with a proven meaning: its specification is a set of theorems Bend checks, and the model, the GPU trainer, the decoder and the data tools are Bend programs too."),
       project("El cubo de Edgar",
         [Link{"https://elcubodeedgar.hhefesto.dev", "elcubodeedgar.hhefesto.dev"}, Link{"https://github.com/hhefesto/elcubodeedgar", "GitHub"}],
         "An optimal Rubik's cube solver in Bend (Korf's IDA*), its group theory as proven laws. It runs on the visitor's own device, compiled to JavaScript, one worker per core."),
       project("mugen", [Link{"https://github.com/hhefesto/mugen", "GitHub"}],
         "One chat with an AI that never ends, in your terminal: every message kept, its memory a binary tree of summaries. Written in Bend 2."),
       project("bend-frp", [Link{"https://github.com/hhefesto/bend-frp", "GitHub"}],
         "Functional reactive programming in Bend, after Conal Elliott: a precise meaning first, and an implementation proved to agree with it. This page is a bend-frp app."),
       project("agda2bend", [Link{"https://github.com/hhefesto/agda2bend", "GitHub"}],
         "Agda in, checked Bend out: translates Agda modules and their imports into Bend 2, keeping only what upstream Bend's checker accepts.")])])

# Expertise

def expertise.card(+title: String, +icon: String, fs: List<&2, String>) -> W.Html:
  div("expertise-card",
    [div("expertise-header",
       [div("expertise-icon " ++ icon, []),
        W.el("h3", [c("expertise-title")], [t(title)])]),
     W.el("ul", [c("expertise-features")], lis(fs))])

def expertise() -> W.Html:
  section("expertise", "What I work with",
    [div("expertise-grid",
      [expertise.card("Nix", "nix-logo",
         ["Nix flakes for hermetic builds and dev shells", "NixOS for immutable servers",
          "CI that builds exactly what you build locally", "Atomic deploys and rollbacks"]),
       expertise.card("Functional programming and proofs", "fp-logo",
         ["Haskell backends", "PureScript and Reflex FRP frontends",
          "Bend and Agda: laws stated and machine-checked", "Property tests where a proof is out of reach"]),
       expertise.card("Cloud and hosting", "cloud-logo",
         ["AWS • GCP • Hetzner • OVH • Rumble", "Provider-agnostic infrastructure as code",
          "Cost optimization across platforms", "Migrations between clouds"])])])

# Services

def service(+emoji: String, +title: String, +desc: String) -> W.Html:
  div("service-card",
    [div("service-emoji", [t(emoji)]),
     W.el("h3", [c("service-title")], [t(title)]),
     W.el("p", [c("service-description")], [t(desc)])])

def services() -> W.Html:
  section("services", "What I deliver",
    [div("services-grid",
      [service("🔄", "Reproducible CI/CD",
         "Self-hosted GitHub runners on NixOS, and an automated dev → staging → prod pipeline with testing gates between stages and rollbacks."),
       service("✅", "Verified software",
         "The properties your system depends on, stated as laws and checked on every change: proofs in Bend or Agda where they fit, property tests in Haskell where they don't."),
       service("🤖", "Private LLM infrastructure",
         "Internal LLMs that can process your confidential data, for companies that need AI but can't use public APIs. I train and serve my own model, ana, end to end."),
       service("🎨", "Type-safe frontends",
         "Full-stack functional development with Yesod, Reflex FRP, PureScript and bend-frp: composable UIs with compile-time guarantees."),
       service("📊", "Databases and observability",
         "PostgreSQL, Redis or others, managed or self-hosted, with backups and migrations; Grafana, Prometheus, structured logs, SLOs and alerts that point at the cause."),
       service("🔒", "Security and secrets",
         "TLS automation, Nginx hardening, secrets managed with sops/age, SSH security, and least-privilege access.")])])

# Process

def pstep(+n: String, +title: String, +desc: String) -> W.Html:
  div("process-step",
    [div("process-number", [t(n)]),
     div("process-content",
       [W.el("h4", [c("process-title")], [t(title)]),
        W.el("p", [c("process-description")], [t(desc)])])])

def process() -> W.Html:
  section("process", "How I work",
    [div("process-flow",
      [pstep("01", "Audit", "A close look at your current setup, its pain points and requirements, to find the biggest wins for reproducibility and reliability."),
       pstep("02", "Design", "A Nix-first plan: clear dev, staging and prod environments, a testing strategy, and the deployment workflow."),
       pstep("03", "Build", "Nix flakes, CI/CD pipelines, monitoring and security, built in small steps you can review."),
       pstep("04", "Hand over", "A step-by-step migration, tested at each stage, with documentation your team can run without me.")])])

# Pricing

def pill(+s: String) -> W.Html:
  W.el("span", [c("pill")], [t(s)])

def pricing() -> W.Html:
  section("pricing", "Pricing: fixed quotes, no open-ended hours",
    [div("pricing-layout",
      [div("pricing-lede",
         [W.el("p", [c("lead")], [t("We start with a free 30-minute call to set goals and check fit. Then a one-week audit at a fixed price: you get a written, prioritised plan plus the first fixes. After that I work by the week or by project, and you get a written scope and a fixed price before any work starts.")]),
          div("pill-row", [pill("Nix-first"), pill("Verified where it matters"), pill("CI/CD + observability"), pill("Docs + handover")])]),
       div("pricing-cards",
         [div("card pricing-card pricing-card--main",
           [div("card-kicker", [t("How we start")]),
            W.el("h3", [c("card-title")], [t("Call, audit, then weekly or per project")]),
            div("split",
              [W.el("div", [],
                 [div("split-title", [t("Steps")]),
                  W.el("ul", [c("list-compact")],
                    lis(["Free 30-minute call", "One-week audit, fixed price", "Weekly or per-project work, quoted up front"]))]),
               W.el("div", [],
                 [div("split-title", [t("Typical outcomes")]),
                  W.el("ul", [c("list-compact")],
                    lis(["Hermetic dev shell and build", "Dev → staging → prod pipeline", "Observability and alerting", "Secrets management"]))])]),
            div("card-actions", [book.call("btn btn-primary btn-block")])])])])])

# About

def about() -> W.Html:
  section("about", "About",
    [div("contact-content",
      [W.el("p", [c("contact-subtitle")],
         [t("I'm Daniel Herrera ("), ext("https://github.com/hhefesto", "hhefesto"),
          t(" on GitHub), a functional programmer working in UTC-6. I like strong types, reproducible builds and proofs, and I use them on my own projects as much as on clients': ana, El cubo de Edgar, mugen, bend-frp and agda2bend are open source.")]),
       W.el("p", [c("contact-subtitle")],
         [t("What clients and colleagues say about working with me is on "),
          ext("https://www.linkedin.com/in/hhefesto/", "my LinkedIn"), t(", under Recommendations.")]),
       W.el("p", [c("contact-subtitle")],
         [t("My CV, as a PDF: "), ext("/CV-Daniel-Herrera.pdf", "CV-Daniel-Herrera.pdf"), t(".")])])])

# Contact: the free call

def day.tabs(ds: List<&2, K.Day>, +sel: U32) -> List<&2, W.Html>:
  match ds:
    case Nil{}:
      Nil{}
    case K.Day{+k, its} <> r:
      W.keyed("button", "d" ++ U32.show(k),
        [W.Prop{"type", "button"}, c(Bool.pick(String, U32.is_eq(k, sel), "slot-day is-on", "slot-day")),
         W.Prop{"aria-pressed", Bool.pick(String, U32.is_eq(k, sel), "true", "false")},
         W.On{"click", "day:" ++ U32.show(k)}],
        [t(K.day.tab(k))]) <> day.tabs(r, sel)

# My time, with its weekday when that is not the visitor's day.
def cdmx.text(+x: K.It) -> String:
  +d : U32 = (K.cdmx(K.It.utc(x)) / 1440 : U32)
  Bool.pick(String, U32.is_eq(d, K.It.day(x)), "", K.wday.short(d) ++ " ") ++
    K.clock(False{}, K.cdmx(K.It.utc(x))) ++ " UTC-6"

# The visitor's time, and mine beside it unless they are the same.
def slot.cdmx(same: Bool, +x: K.It) -> List<&2, W.Html>:
  match same:
    case True{}:
      Nil{}
    case False{}:
      [W.el("span", [c("slot-cdmx")], [t(cdmx.text(x))])]

def slot(+x: K.It, +zone: String, +h12: Bool) -> W.Html:
  W.keyed("a", "s" ++ U32.show(K.It.utc(x)),
    [c("slot"), W.Prop{"href", K.mail.slot(x, zone, h12)},
     W.Prop{"title", "Email me to book " ++ K.at.cdmx(K.It.utc(x))}],
    W.el("span", [c("slot-time")], [t(K.clock(h12, K.It.loc(x)))]) <>
      slot.cdmx(U32.is_eq(K.It.loc(x), K.cdmx(K.It.utc(x))), x))

def slots.of(xs: List<&2, K.It>, +zone: String, +h12: Bool) -> List<&2, W.Html>:
  match xs:
    case Nil{}:
      Nil{}
    case +x <> r:
      slot(x, zone, h12) <> slots.of(r, zone, h12)

def day.slots.if(hit: Bool, its: List<&2, K.It>, +zone: String, +h12: Bool, rest: Unit -> List<&2, W.Html>) -> List<&2, W.Html>:
  match hit:
    case True{}:
      slots.of(its, zone, h12)
    case False{}:
      rest(Unit{})

# The slots of the day shown (only those: each is an email to build).
def day.slots(ds: List<&2, K.Day>, +sel: U32, +zone: String, +h12: Bool) -> List<&2, W.Html>:
  match ds:
    case Nil{}:
      Nil{}
    case K.Day{+k, its} <> r:
      day.slots.if(U32.is_eq(k, sel), its, zone, h12, u => day.slots(r, sel, zone, h12))

def day.title(ds: List<&2, K.Day>, +sel: U32) -> String:
  match ds:
    case Nil{}:
      ""
    case K.Day{+k, its} <> r:
      Bool.pick(String, U32.is_eq(k, sel), K.day.long(k), day.title(r, sel))

# Every slot shows the same time on the visitor's clock as on mine.
def all.cdmx(xs: List<&2, K.It>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case +x <> r:
      Bool.and(U32.is_eq(K.It.loc(x), K.cdmx(K.It.utc(x))), all.cdmx(r))

# "America/Mexico_City" as "America/Mexico City".
def zone.show(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{+ch, r}:
      SCon{Bool.pick(Char, K.ch.is(ch, '_'), ' ', ch), zone.show(r)}

def zone.line(mine: Bool, +zone: String) -> String:
  match mine:
    case True{}:
      "30 minutes. Times are in your zone (" ++ zone.show(zone) ++ "), which is mine too: UTC-6."
    case False{}:
      "30 minutes. Times are in your zone (" ++ zone.show(zone) ++ "), with mine (UTC-6) beside them."

def picker(o: K.Offer) -> List<&2, W.Html>:
  match o:
    case K.Plain{}:
      Nil{}
    case K.Pick{+zone, +h12, +ds, +sel}:
      [W.keyed("div", "picker", [c("slots card")],
        [div("card-kicker", [t("Pick a time for the free call")]),
         W.el("p", [c("slot-zone")], [t(zone.line(all.cdmx(K.flat(ds)), zone))]),
         div("slot-days", day.tabs(ds, sel)),
         W.el("h3", [c("slot-title")], [t(day.title(ds, sel))]),
         div("slot-grid", day.slots(ds, sel, zone, h12)),
         W.el("p", [c("slot-note")], [t("Picking a time opens an email to me with it filled in. The call is confirmed when I reply.")])])]

def is.pick(o: K.Offer) -> Bool:
  match o:
    case K.Plain{}:
      False{}
    case K.Pick{z, h, ds, s}:
      True{}

def plain.link(pick: Bool) -> W.Html:
  match pick:
    case False{}:
      W.el("a", [c("btn btn-primary btn-large"), W.Prop{"href", K.mail.plain()}], [t("📧 Email me to book a call")])
    case True{}:
      W.el("a", [c("btn btn-secondary"), W.Prop{"href", K.mail.plain()}], [t("📧 None of these fit? Email me")])

def contact(+o: K.Offer) -> W.Html:
  section("contact", "Book a free call",
    [div("contact-content",
      List.append(&2, W.Html,
        W.el("p", [c("contact-subtitle")], [t("Tell me about your current setup and where you want it to be. We'll talk for 30 minutes, free, and you'll get a written scope and a fixed price before any work starts.")]) <> picker(o),
        [div("contact-methods",
          [plain.link(is.pick(o)),
           div("contact-note", [t("I usually reply within 4 hours during UTC-6 business hours.")])])]))])

def offer.of(s: S) -> K.Offer:
  match s:
    case Offered{o}:
      o
    case _:
      K.Plain{}

def view(s: S) -> W.Html:
  W.el("main", [], [hero(), work(), expertise(), services(), process(), pricing(), about(), contact(offer.of(s))])

def step(s: S, i: W.Input) -> S & W.Out:
  W.app.step(~S, ~update, ~view, s, i)
