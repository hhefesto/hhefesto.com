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
    , services
    , process
    , pricing
    , faq
    , contact
    ]

hero =
  HH.section
    [ HP.attr (H.AttrName "class") "hero container" ]
    [ pill "Reproducible • Secure • Fast"
    , HH.h1_ [ HH.text "Modern DevOps that ships reliably — and is actually reproducible" ]
    , HH.p [ HP.attr (H.AttrName "class") "lead" ]
        [ HH.text "I help teams go from ad-hoc servers to solid, automated environments. GitHub runners that build and deploy to "
        , HH.strong_ [ HH.text "dev → staging → production" ]
        , HH.text ", private LLMs for internal workflows, secure databases, SSL/Nginx hardening, and robust secret management. Self-hosted on your infra or managed from mine."
        ]
    , HH.div [ HP.attr (H.AttrName "class") "cta-row" ]
        [ HH.a
            [ HP.attr (H.AttrName "id") "cta"
            , HP.attr (H.AttrName "class") "btn"
            , HP.href "#contact"
            ]
            [ HH.text "Book a free consultation" ]
        , HH.a
            [ HP.attr (H.AttrName "class") "btn btn-outline"
            , HP.href "#pricing"
            ]
            [ HH.text "See pricing" ]
        , HH.span
            [ HP.attr (H.AttrName "id") "cta-note"
            , HP.attr (H.AttrName "class") "sr-only"
            ]
            [ HH.text "This button is interactive." ]
        ]
    , HH.p
        [ HP.attr (H.AttrName "id") "app"
        , HP.attr (H.AttrName "class") "lead"
        , HP.attr (H.AttrName "style") "margin-top:12px; font-size:14px;"
        ]
        [ HH.text "Ready! Click the button above." ]
    , HH.div
        [ HP.attr (H.AttrName "class") "badges"
        , HP.attr (H.AttrName "aria-label") "tooling" ]
        [ pill "Nix/NixOS"
        , pill "GitHub Actions & self-hosted runners"
        , pill "Docker & Kubernetes"
        , pill "PostgreSQL"
        , pill "Nginx • SSL"
        , pill "AWS / GCP / OVH / Rumble"
        , pill "Private LLMs"
        ]
    ]

services =
  section "services" "What I deliver"
    [ grid
        [ card "Multi-env pipelines" "Automated GitHub runners that build, test, and promote artifacts from dev → staging → production with approvals and rollbacks."
        , card "Self-hosted or managed" "Run CI/CD on your infra (NixOS, Kubernetes) or use my fully managed runners and servers."
        , card "Private LLMs" "Deploy internal LLMs that can safely access confidential docs (policy-guarded)."
        , card "Database setup" "PostgreSQL provisioning, migrations, backups, monitoring, and secure connections."
        , card "Security & secrets" "SSL certificates, Nginx hardening, SSO, key rotation, and encrypted secret management."
        , card "Observability" "Metrics, logs, health checks, and alerts—see deploy impact instantly."
        ]
    ]

process =
  section "process" "How we work"
    [ HH.div [ HP.attr (H.AttrName "class") "process" ]
        [ step "01" "Discovery" "Quick audit of your repos, infra, and goals. We agree on target state and success metrics."
        , step "02" "Design" "Plan environments, runners, secrets, and data. Choose self-hosted vs managed and promotion strategy."
        , step "03" "Build" "Implement CI/CD, infra as code (Nix/Terraform), DBs, SSL/Nginx, monitoring, and private LLMs."
        , step "04" "Operate" "Handover with docs/training or ongoing ops/SLA where I keep everything healthy and fast."
        ]
    ]

pricing =
  section "pricing" "Engagements"
    [ HH.div [ HP.attr (H.AttrName "class") "pricing" ]
        [ plan "Starter" "Project-based"
            [ "Dev → staging pipeline"
            , "Self-hosted or managed runners"
            , "SSL & Nginx setup"
            , "Database provisioning"
            ]
        , planFeatured "Growth" "Monthly retainer"
            [ "Dev → staging → production promotions"
            , "Backups, monitoring & alerts"
            , "Secret management & SSO"
            , "Cloud cost & performance tuning"
            ]
        , plan "Pro" "Custom"
            [ "Private LLMs with policy controls"
            , "Kubernetes or NixOS fleets"
            , "24/7 on-call & SLAs"
            , "Advanced security / compliance"
            ]
        ]
    ]

faq =
  section "faq" "FAQ"
    [ details "Can you work with our existing cloud?" "Yes. I commonly deploy to AWS, GCP, OVH, or Rumble. I can also provision dedicated machines for you."
    , details "Do you do one-off projects?" "Absolutely. Many clients start with a fixed-scope project and later move to a retainer."
    , details "Where do private LLMs run?" "Either on your infra (air-gapped if necessary) or on my managed GPU servers. Policies ensure only approved files are accessible."
    ]

contact =
  section "contact" "Let’s talk"
    [ HH.p [ HP.attr (H.AttrName "class") "lead" ]
        [ HH.text "Tell me about your stack and what “done” looks like. I’ll reply with a short plan and a quote." ]
    , HH.div [ HP.attr (H.AttrName "class") "cta-row" ]
        [ HH.a [ HP.attr (H.AttrName "class") "btn", HP.href "mailto:you@hhefesto.com?subject=DevOps%20Consulting%20Inquiry" ]
            [ HH.text "Email me" ]
        , HH.a
            [ HP.attr (H.AttrName "class") "btn btn-outline"
            , HP.href "#"
            , HP.title "Replace with your scheduling link"
            ]
            [ HH.text "Schedule a call" ]
        ]
    ]

-- UI helpers ---------------------------------------------------------------

section sid title body =
  HH.section
    [ HP.attr (H.AttrName "id") sid
    , HP.attr (H.AttrName "class") "section container"
    ]
    ([ HH.h2_ [ HH.text title ] ] <> body)

pill s = HH.span [ HP.attr (H.AttrName "class") "pill" ] [ HH.text s ]

card title text =
  HH.div [ HP.attr (H.AttrName "class") "card" ]
    [ HH.h3_ [ HH.text title ]
    , HH.p_  [ HH.text text ]
    ]

grid items = HH.div [ HP.attr (H.AttrName "class") "grid" ] items

step n title text =
  HH.div [ HP.attr (H.AttrName "class") "step" ]
    [ HH.div [ HP.attr (H.AttrName "class") "num" ] [ HH.text n ]
    , HH.h4_ [ HH.text title ]
    , HH.p_  [ HH.text text ]
    ]

plan name price features =
  HH.div [ HP.attr (H.AttrName "class") "plan" ]
    [ HH.div [ HP.attr (H.AttrName "class") "title" ] [ HH.text name ]
    , HH.div [ HP.attr (H.AttrName "class") "price" ] [ HH.text price ]
    , HH.ul_ (map (\f -> HH.li_ [ HH.text f ]) features)
    , HH.a [ HP.attr (H.AttrName "class") "btn", HP.href "#contact" ] [ HH.text "Get a quote" ]
    ]

planFeatured name price feats =
  HH.div
    [ HP.attr (H.AttrName "class") "plan"
    , HP.attr (H.AttrName "style") "outline:2px solid var(--primary); outline-offset:2px;"
    ]
    [ HH.div [ HP.attr (H.AttrName "class") "title" ] [ HH.text name ]
    , HH.div [ HP.attr (H.AttrName "class") "price" ] [ HH.text price ]
    , HH.ul_ (map (\f -> HH.li_ [ HH.text f ]) feats)
    , HH.a [ HP.attr (H.AttrName "class") "btn", HP.href "#contact" ] [ HH.text "Book a call" ]
    ]

details q a =
  HH.details_ [ HH.summary_ [ HH.text q ], HH.p_ [ HH.text a ] ]

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
