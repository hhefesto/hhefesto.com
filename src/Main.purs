module Main where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class (liftEffect)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.VDom.Driver (runUI)
import Web.DOM.Document (toNonElementParentNode)
import Web.DOM.NonElementParentNode (getElementById)
import Web.HTML (window)
import Web.HTML.HTMLDocument (toDocument)
import Web.HTML.HTMLElement (fromElement)
import Web.HTML.Window (document)

-- Minimal model (static page for maximum compatibility)
type State = Unit
data Action = NoOp

initialState :: forall i. i -> State
initialState _ = unit

handleAction :: forall o m. Action -> H.HalogenM State Action () o m Unit
handleAction _ = pure unit

-- Component ----------------------------------------------------------------

component :: forall q i o m. H.Component q i o m
component = H.mkComponent
  { initialState
  , render
  , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
  }

-- View ---------------------------------------------------------------------

render :: forall m. State -> H.ComponentHTML Action () m
render _ =
  HH.main_
    [ hero
    , work
    , expertise
    , services
    , process
    , pricing
    , about
    , contact
    ]

-- The one way in: every "Book a free call" button leads to the contact
-- section, and only that section holds the email link.
mailto :: String
mailto = "mailto:hhefesto@rdataa.com?subject=Free%20call"

bookCall cls =
  HH.a
    [ HP.attr (H.AttrName "class") cls
    , HP.href "#contact"
    ]
    [ HH.text "Book a free call" ]

-- HERO ---------------------------------------------------------------------

hero =
  HH.section
    [ HP.attr (H.AttrName "class") "hero container" ]
    [ HH.div [ HP.attr (H.AttrName "class") "hero-grid" ]
        [ HH.div [ HP.attr (H.AttrName "class") "hero-content" ]
            [ badge "Nix • Haskell • Bend • Verified software"
            , HH.h1 [ HP.attr (H.AttrName "class") "hero-title" ]
                [ HH.text "Reproducible infrastructure and verified software" ]
            , HH.p [ HP.attr (H.AttrName "class") "hero-subtitle" ]
                [ HH.text "I build "
                , HH.strong_ [ HH.text "Nix" ]
                , HH.text " dev shells, CI and deploys that behave the same on every machine, and "
                , HH.strong_ [ HH.text "functional software" ]
                , HH.text " (Haskell, PureScript, Bend) whose key properties are stated as laws and checked by the compiler, not only tested. "
                , HH.text "My own work includes "
                , extLink "https://ana.hhefesto.dev" "ana"
                , HH.text ", a language model specified, trained and evaluated in Bend, and "
                , extLink "https://elcubodeedgar.hhefesto.dev" "El cubo de Edgar"
                , HH.text ", an optimal Rubik's cube solver in Bend with its group theory as proven laws."
                ]
            , HH.div [ HP.attr (H.AttrName "class") "hero-cta" ]
                [ bookCall "btn btn-primary"
                , HH.a
                    [ HP.attr (H.AttrName "class") "btn btn-secondary"
                    , HP.href "#work"
                    ]
                    [ HH.text "See my work" ]
                ]
            ]
        , HH.aside [ HP.attr (H.AttrName "class") "hero-offer" ]
            [ firstStep ]
        ]
    ]

firstStep =
  HH.div [ HP.attr (H.AttrName "class") "card pricing-card pricing-card--hero" ]
    [ HH.div [ HP.attr (H.AttrName "class") "card-kicker" ]
        [ HH.text "A fixed-price first step" ]
    , HH.h3 [ HP.attr (H.AttrName "class") "card-title" ]
        [ HH.text "One-week audit" ]
    , HH.p [ HP.attr (H.AttrName "class") "muted" ]
        [ HH.text "I review your builds, deploys and infrastructure, and hand you a written, prioritised plan plus the first fixes. The price is fixed and agreed before we start; the first call is free." ]
    , HH.ul [ HP.attr (H.AttrName "class") "list-compact" ]
        [ HH.li_ [ HH.text "✅ What breaks reproducibility today, and why" ]
        , HH.li_ [ HH.text "✅ A dev → staging → prod plan with testing gates" ]
        , HH.li_ [ HH.text "✅ The first fixes, done that same week" ]
        ]
    , HH.div [ HP.attr (H.AttrName "class") "card-actions" ]
        [ bookCall "btn btn-primary btn-block" ]
    , HH.div [ HP.attr (H.AttrName "class") "card-footnote" ]
        [ HH.text "I usually reply within 4 hours during UTC-6 business hours." ]
    ]

-- WORK ---------------------------------------------------------------------

work =
  section "work" "Selected work"
    [ HH.div [ HP.attr (H.AttrName "class") "services-grid" ]
        [ projectCard "xpsoasis.org and xesoasis.org"
            [ Tuple2 "https://xpsoasis.org" "xpsoasis.org", Tuple2 "https://xesoasis.org" "xesoasis.org" ]
            "Architected and built end to end, from first concept to production: infrastructure, CI/CD, reliability and delivery. Both are running systems."
        , projectCard "ana"
            [ Tuple2 "https://ana.hhefesto.dev" "ana.hhefesto.dev", Tuple2 "https://github.com/hhefesto/ana" "GitHub" ]
            "A 115M-parameter language model with a proven meaning: its specification is a set of theorems Bend checks, and the model, the GPU trainer, the decoder and the data tools are Bend programs too."
        , projectCard "El cubo de Edgar"
            [ Tuple2 "https://elcubodeedgar.hhefesto.dev" "elcubodeedgar.hhefesto.dev", Tuple2 "https://github.com/hhefesto/elcubodeedgar" "GitHub" ]
            "An optimal Rubik's cube solver in Bend (Korf's IDA*), its group theory as proven laws. It runs on the visitor's own device, compiled to JavaScript, one worker per core."
        , projectCard "mugen"
            [ Tuple2 "https://github.com/hhefesto/mugen" "GitHub" ]
            "One chat with an AI that never ends, in your terminal: every message kept, its memory a binary tree of summaries. Written in Bend 2."
        , projectCard "bend-frp"
            [ Tuple2 "https://github.com/hhefesto/bend-frp" "GitHub" ]
            "Functional reactive programming in Bend, after Conal Elliott: a precise meaning first, and an implementation proved to agree with it."
        , projectCard "agda2bend"
            [ Tuple2 "https://github.com/hhefesto/agda2bend" "GitHub" ]
            "Agda in, checked Bend out: translates Agda modules and their imports into Bend 2, keeping only what upstream Bend's checker accepts."
        ]
    ]

data Tuple2 = Tuple2 String String

projectCard title links description =
  HH.div [ HP.attr (H.AttrName "class") "service-card project-card" ]
    [ HH.h3 [ HP.attr (H.AttrName "class") "service-title" ] [ HH.text title ]
    , HH.p [ HP.attr (H.AttrName "class") "service-description" ] [ HH.text description ]
    , HH.div [ HP.attr (H.AttrName "class") "project-links" ]
        (map (\(Tuple2 url label) -> extLink url label) links)
    ]

extLink url label =
  HH.a
    [ HP.href url
    , HP.attr (H.AttrName "target") "_blank"
    , HP.attr (H.AttrName "rel") "noopener"
    ]
    [ HH.text label ]

-- EXPERTISE ----------------------------------------------------------------

expertise =
  section "expertise" "What I work with"
    [ HH.div [ HP.attr (H.AttrName "class") "expertise-grid" ]
        [ expertiseCard "Nix" "nix-logo"
            [ "Nix flakes for hermetic builds and dev shells"
            , "NixOS for immutable servers"
            , "CI that builds exactly what you build locally"
            , "Atomic deploys and rollbacks"
            ]
        , expertiseCard "Functional programming and proofs" "fp-logo"
            [ "Haskell backends"
            , "PureScript and Reflex FRP frontends"
            , "Bend and Agda: laws stated and machine-checked"
            , "Property tests where a proof is out of reach"
            ]
        , expertiseCard "Cloud and hosting" "cloud-logo"
            [ "AWS • GCP • Hetzner • OVH • Rumble"
            , "Provider-agnostic infrastructure as code"
            , "Cost optimization across platforms"
            , "Migrations between clouds"
            ]
        ]
    ]

-- SERVICES -----------------------------------------------------------------

services =
  section "services" "What I deliver"
    [ HH.div [ HP.attr (H.AttrName "class") "services-grid" ]
        [ serviceCard "🔄" "Reproducible CI/CD"
            "Self-hosted GitHub runners on NixOS, and an automated dev → staging → prod pipeline with testing gates between stages and rollbacks."
        , serviceCard "✅" "Verified software"
            "The properties your system depends on, stated as laws and checked on every change: proofs in Bend or Agda where they fit, property tests in Haskell where they don't."
        , serviceCard "🤖" "Private LLM infrastructure"
            "Internal LLMs that can process your confidential data, for companies that need AI but can't use public APIs. I train and serve my own model, ana, end to end."
        , serviceCard "🎨" "Type-safe frontends"
            "Full-stack functional development with Yesod, Reflex FRP and PureScript: composable UIs with compile-time guarantees."
        , serviceCard "📊" "Databases and observability"
            "PostgreSQL, Redis or others, managed or self-hosted, with backups and migrations; Grafana, Prometheus, structured logs, SLOs and alerts that point at the cause."
        , serviceCard "🔒" "Security and secrets"
            "TLS automation, Nginx hardening, secrets managed with sops/age, SSH security, and least-privilege access."
        ]
    ]

-- PROCESS ------------------------------------------------------------------

process =
  section "process" "How I work"
    [ HH.div [ HP.attr (H.AttrName "class") "process-flow" ]
        [ processStep "01" "Audit" "A close look at your current setup, its pain points and requirements, to find the biggest wins for reproducibility and reliability."
        , processStep "02" "Design" "A Nix-first plan: clear dev, staging and prod environments, a testing strategy, and the deployment workflow."
        , processStep "03" "Build" "Nix flakes, CI/CD pipelines, monitoring and security, built in small steps you can review."
        , processStep "04" "Hand over" "A step-by-step migration, tested at each stage, with documentation your team can run without me."
        ]
    ]

-- PRICING ------------------------------------------------------------------

pricing =
  section "pricing" "Pricing: fixed quotes, no open-ended hours"
    [ HH.div [ HP.attr (H.AttrName "class") "pricing-layout" ]
        [ HH.div [ HP.attr (H.AttrName "class") "pricing-lede" ]
            [ HH.p [ HP.attr (H.AttrName "class") "lead" ]
                [ HH.text "We start with a free 30-minute call to set goals and check fit. Then a one-week audit at a fixed price: you get a written, prioritised plan plus the first fixes. After that I work by the week or by project, and you get a written scope and a fixed price before any work starts." ]
            , HH.div [ HP.attr (H.AttrName "class") "pill-row" ]
                [ pill "Nix-first"
                , pill "Verified where it matters"
                , pill "CI/CD + observability"
                , pill "Docs + handover"
                ]
            ]
        , HH.div [ HP.attr (H.AttrName "class") "pricing-cards" ]
            [ HH.div [ HP.attr (H.AttrName "class") "card pricing-card pricing-card--main" ]
                [ HH.div [ HP.attr (H.AttrName "class") "card-kicker" ] [ HH.text "How we start" ]
                , HH.h3 [ HP.attr (H.AttrName "class") "card-title" ] [ HH.text "Call, audit, then weekly or per project" ]
                , HH.div [ HP.attr (H.AttrName "class") "split" ]
                    [ HH.div_
                        [ HH.div [ HP.attr (H.AttrName "class") "split-title" ] [ HH.text "Steps" ]
                        , HH.ul [ HP.attr (H.AttrName "class") "list-compact" ]
                            [ HH.li_ [ HH.text "Free 30-minute call" ]
                            , HH.li_ [ HH.text "One-week audit, fixed price" ]
                            , HH.li_ [ HH.text "Weekly or per-project work, quoted up front" ]
                            ]
                        ]
                    , HH.div_
                        [ HH.div [ HP.attr (H.AttrName "class") "split-title" ] [ HH.text "Typical outcomes" ]
                        , HH.ul [ HP.attr (H.AttrName "class") "list-compact" ]
                            [ HH.li_ [ HH.text "Hermetic dev shell and build" ]
                            , HH.li_ [ HH.text "Dev → staging → prod pipeline" ]
                            , HH.li_ [ HH.text "Observability and alerting" ]
                            , HH.li_ [ HH.text "Secrets management" ]
                            ]
                        ]
                    ]
                , HH.div [ HP.attr (H.AttrName "class") "card-actions" ]
                    [ bookCall "btn btn-primary btn-block" ]
                ]
            ]
        ]
    ]

pill txt =
  HH.span [ HP.attr (H.AttrName "class") "pill" ] [ HH.text txt ]

-- ABOUT --------------------------------------------------------------------

about =
  section "about" "About"
    [ HH.div [ HP.attr (H.AttrName "class") "contact-content" ]
        [ HH.p [ HP.attr (H.AttrName "class") "contact-subtitle" ]
            [ HH.text "I'm Daniel Herrera ("
            , extLink "https://github.com/hhefesto" "hhefesto"
            , HH.text " on GitHub), a functional programmer working in UTC-6. I like strong types, reproducible builds and proofs, and I use them on my own projects as much as on clients': ana, El cubo de Edgar, mugen, bend-frp and agda2bend are open source."
            ]
        , HH.p [ HP.attr (H.AttrName "class") "contact-subtitle" ]
            [ HH.text "What clients and colleagues say about working with me is on "
            , extLink "https://www.linkedin.com/in/hhefesto/" "my LinkedIn"
            , HH.text ", under Recommendations."
            ]
        ]
    ]

-- CONTACT ------------------------------------------------------------------

contact =
  section "contact" "Book a free call"
    [ HH.div [ HP.attr (H.AttrName "class") "contact-content" ]
        [ HH.p [ HP.attr (H.AttrName "class") "contact-subtitle" ]
            [ HH.text "Tell me about your current setup and where you want it to be. We'll talk for 30 minutes, free, and you'll get a written scope and a fixed price before any work starts." ]
        , HH.div [ HP.attr (H.AttrName "class") "contact-methods" ]
            [ HH.a
                [ HP.attr (H.AttrName "class") "btn btn-primary btn-large"
                , HP.href mailto
                ]
                [ HH.text "📧 Email me to book a call" ]
            , HH.div [ HP.attr (H.AttrName "class") "contact-note" ]
                [ HH.text "I usually reply within 4 hours during UTC-6 business hours." ]
            ]
        ]
    ]

-- UI helpers ---------------------------------------------------------------

section sid title body =
  HH.section
    [ HP.attr (H.AttrName "id") sid
    , HP.attr (H.AttrName "class") "section container"
    ]
    ([ HH.h2 [ HP.attr (H.AttrName "class") "section-title" ] [ HH.text title ] ] <> body)

badge text =
  HH.div [ HP.attr (H.AttrName "class") "badge" ]
    [ HH.text text ]

expertiseCard title icon features =
  HH.div [ HP.attr (H.AttrName "class") "expertise-card" ]
    [ HH.div [ HP.attr (H.AttrName "class") "expertise-header" ]
        [ HH.div [ HP.attr (H.AttrName "class") ("expertise-icon " <> icon) ] []
        , HH.h3 [ HP.attr (H.AttrName "class") "expertise-title" ] [ HH.text title ]
        ]
    , HH.ul [ HP.attr (H.AttrName "class") "expertise-features" ]
        (map (\f -> HH.li_ [ HH.text f ]) features)
    ]

serviceCard emoji title description =
  HH.div [ HP.attr (H.AttrName "class") "service-card" ]
    [ HH.div [ HP.attr (H.AttrName "class") "service-emoji" ] [ HH.text emoji ]
    , HH.h3 [ HP.attr (H.AttrName "class") "service-title" ] [ HH.text title ]
    , HH.p [ HP.attr (H.AttrName "class") "service-description" ] [ HH.text description ]
    ]

processStep number title description =
  HH.div [ HP.attr (H.AttrName "class") "process-step" ]
    [ HH.div [ HP.attr (H.AttrName "class") "process-number" ] [ HH.text number ]
    , HH.div [ HP.attr (H.AttrName "class") "process-content" ]
        [ HH.h4 [ HP.attr (H.AttrName "class") "process-title" ] [ HH.text title ]
        , HH.p [ HP.attr (H.AttrName "class") "process-description" ] [ HH.text description ]
        ]
    ]

-- Mount --------------------------------------------------------------------

main :: Effect Unit
main = HA.runHalogenAff do
  -- Version-agnostic mount: query #root from the DOM, then runUI
  mRoot <- liftEffect do
    win <- window
    doc <- document win
    let docNode = toNonElementParentNode (toDocument doc)
    getElementById "root" docNode
  case mRoot >>= fromElement of
    Nothing   -> pure unit
    Just root -> void $ runUI component unit root
