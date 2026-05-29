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
    , pricing
    , expertise
    , services
    , process
    , testimonial
    , contact
    ]

-- HERO ---------------------------------------------------------------------

hero =
  HH.section
    [ HP.attr (H.AttrName "class") "hero container" ]
    [ HH.div [ HP.attr (H.AttrName "class") "hero-grid" ]
        [ HH.div [ HP.attr (H.AttrName "class") "hero-content" ]
            [ badge "Nix • Reproducible • Bulletproof"
            , HH.h1 [ HP.attr (H.AttrName "class") "hero-title" ]
                [ HH.text "Turn your prototype into bulletproof production infrastructure" ]
            , HH.p [ HP.attr (H.AttrName "class") "hero-subtitle" ]
                [ HH.text "I specialize in "
                , HH.strong_ [ HH.text "Nix flakes" ]
                , HH.text " and "
                , HH.strong_ [ HH.text "functional programming" ]
                , HH.text " to build completely reproducible CI/CD pipelines. From dev → staging → prod with zero configuration drift, automated testing between stages, and deployments that work exactly the same every time."
                ]
            , HH.div [ HP.attr (H.AttrName "class") "hero-cta" ]
                [ HH.a
                    [ HP.attr (H.AttrName "class") "btn btn-primary"
                    , HP.href "#contact"
                    ]
                    [ HH.text "Transform your deployment" ]
                , HH.a
                    [ HP.attr (H.AttrName "class") "btn btn-secondary"
                    , HP.href "#services"
                    ]
                    [ HH.text "See what I build" ]
                , HH.a
                    [ HP.attr (H.AttrName "class") "btn btn-tertiary"
                    , HP.href "#pricing"
                    ]
                    [ HH.text "View pricing" ]
                ]
            , HH.div [ HP.attr (H.AttrName "class") "hero-stats" ]
                [ stat "100%" "Reproducible"
                , stat "0" "Config drift"
                , stat "24/7" "Reliability"
                ]
            ]
        , HH.aside [ HP.attr (H.AttrName "class") "hero-offer" ]
            [ pricingSpotlight ]
        ]
    ]

pricingSpotlight =
  HH.div [ HP.attr (H.AttrName "class") "card pricing-card pricing-card--hero" ]
    [ HH.div [ HP.attr (H.AttrName "class") "card-kicker" ]
        [ HH.text "First-week discount" ]
    , HH.h3 [ HP.attr (H.AttrName "class") "card-title" ]
        [ HH.text "Senior Infrastructure / FP" ]
    , HH.div [ HP.attr (H.AttrName "class") "pricing-amount" ]
        [ HH.span [ HP.attr (H.AttrName "class") "pricing-currency" ] [ HH.text "$" ]
        , HH.span [ HP.attr (H.AttrName "class") "pricing-number" ] [ HH.text "30" ]
        , HH.span [ HP.attr (H.AttrName "class") "pricing-period" ] [ HH.text "/hour" ]
        ]
    , HH.p [ HP.attr (H.AttrName "class") "muted" ]
        [ HH.text "I'm offering a big first-week discount at $30/hour so we can prove fit fast. For longer collaborations, we'll adjust scope and rate together." ]
    , HH.ul [ HP.attr (H.AttrName "class") "list-compact" ]
        [ HH.li_ [ HH.text "✅ Reproducible dev/staging/prod" ]
        , HH.li_ [ HH.text "✅ CI/CD with testing gates" ]
        , HH.li_ [ HH.text "✅ Monitoring + rollback strategy" ]
        ]
    , HH.div [ HP.attr (H.AttrName "class") "card-actions" ]
        [ HH.a
            [ HP.attr (H.AttrName "class") "btn btn-primary btn-block"
            , HP.href "mailto:hhefesto@rdataa.com?subject=DevOps%20Transformation%20Inquiry"
            ]
            [ HH.text "Start the conversation" ]
        , HH.a
            [ HP.attr (H.AttrName "class") "btn btn-secondary btn-block"
            , HP.href "#contact"
            ]
            [ HH.text "Free consultation" ]
        ]
    , HH.div [ HP.attr (H.AttrName "class") "card-footnote" ]
        [ HH.text "Usually respond within 4 hours during UTC-6 business hours" ]
    ]

-- EXPERTISE ----------------------------------------------------------------

expertise =
  section "expertise" "My expertise"
    [ HH.div [ HP.attr (H.AttrName "class") "expertise-grid" ]
        [ expertiseCard "Nix Ecosystem" "nix-logo"
            [ "Nix flakes for hermetic environments"
            , "NixOS for immutable infrastructure"
            , "Zero-config dev shells that work everywhere"
            , "Atomic rollbacks and perfect reproducibility"
            ]
        , expertiseCard "Functional Programming" "fp-logo"
            [ "Haskell for bulletproof backend systems"
            , "PureScript for type-safe frontends"
            , "Immutable infrastructure principles"
            , "Composable, testable system design"
            ]
        , expertiseCard "Multi-Cloud Mastery" "cloud-logo"
            [ "AWS • GCP • Hetzner • OVH • Rumble"
            , "Provider-agnostic infrastructure as code"
            , "Cost optimization across platforms"
            , "Migration strategies between clouds"
            ]
        ]
    ]

-- SERVICES -----------------------------------------------------------------

services =
  section "services" "What I deliver"
    [ HH.div [ HP.attr (H.AttrName "class") "services-grid" ]
        [ serviceCard "🔄" "Bulletproof CI/CD"
            "Self-hosted GitHub runners on NixOS. Automated dev → staging → prod pipeline with testing gates, rollback capabilities, and zero downtime deployments."
        , serviceCard "🤖" "Private LLM Infrastructure"
            "Deploy secure, internal LLMs that can safely process your confidential data. Perfect for companies that need AI but can't use public APIs."
        , serviceCard "🎨" "Type-Safe Frontends"
            "Full-stack functional development with Yesod, Reflex FRP, and PureScript. Reactive, composable UIs with compile-time guarantees and seamless backend integration."
        , serviceCard "🗄️" "Database Excellence"
            "PostgreSQL, Redis, or any database. Automated backups, migrations, monitoring, performance tuning. Managed cloud DB or self-hosted."
        , serviceCard "🔒" "Security & Secrets"
            "SSL automation, Nginx hardening, secret management with sops/age, SSH security, and least-privilege access controls."
        , serviceCard "📊" "Observability Stack"
            "Grafana dashboards, Prometheus metrics, structured logging, SLOs, and intelligent alerting. Know what's happening before your users do."
        ]
    ]

-- PROCESS ------------------------------------------------------------------

process =
  section "process" "How I work"
    [ HH.div [ HP.attr (H.AttrName "class") "process-flow" ]
        [ processStep "01" "Audit" "Deep dive into your current setup, pain points, and requirements. Identify the biggest wins for reproducibility and reliability."
        , processStep "02" "Design" "Create a Nix-first architecture plan with clear dev/staging/prod environments, testing strategies, and deployment workflows."
        , processStep "03" "Build" "Implement with Nix flakes, set up CI/CD pipelines, configure monitoring, and establish security best practices."
        , processStep "04" "Deploy" "Migrate to the new system with zero downtime, comprehensive testing, and full documentation handover."
        ]
    ]

-- PRICING ------------------------------------------------------------------

pricing =
  section "pricing" "Big first-week discount: $30/hour"
    [ HH.div [ HP.attr (H.AttrName "class") "pricing-layout" ]
        [ HH.div [ HP.attr (H.AttrName "class") "pricing-lede" ]
            [ HH.p [ HP.attr (H.AttrName "class") "lead" ]
                [ HH.text "Start with a heavily discounted first week at $30/hour. If the collaboration continues, we'll adjust the scope and rate around the longer-term plan." ]
            , HH.div [ HP.attr (H.AttrName "class") "pill-row" ]
                [ pill "Nix-first"
                , pill "Security & secrets"
                , pill "CI/CD + observability"
                , pill "Docs + handover"
                ]
            ]
        , HH.div [ HP.attr (H.AttrName "class") "pricing-cards" ]
            [ HH.div [ HP.attr (H.AttrName "class") "card pricing-card pricing-card--main" ]
                [ HH.div [ HP.attr (H.AttrName "class") "card-kicker" ] [ HH.text "First-week discount" ]
                , HH.h3 [ HP.attr (H.AttrName "class") "card-title" ] [ HH.text "Senior Infrastructure / FP" ]
                , HH.div [ HP.attr (H.AttrName "class") "pricing-amount" ]
                    [ HH.span [ HP.attr (H.AttrName "class") "pricing-currency" ] [ HH.text "$" ]
                    , HH.span [ HP.attr (H.AttrName "class") "pricing-number" ] [ HH.text "30" ]
                    , HH.span [ HP.attr (H.AttrName "class") "pricing-period" ] [ HH.text "/hour" ]
                    ]
                , HH.p [ HP.attr (H.AttrName "class") "muted" ]
                    [ HH.text "A low-risk way to audit, prioritize, and start delivering a stable, reproducible baseline before committing long term." ]
                , HH.div [ HP.attr (H.AttrName "class") "split" ]
                    [ HH.div_
                        [ HH.div [ HP.attr (H.AttrName "class") "split-title" ] [ HH.text "Typical outcomes" ]
                        , HH.ul [ HP.attr (H.AttrName "class") "list-compact" ]
                            [ HH.li_ [ HH.text "Hermetic dev shell & build" ]
                            , HH.li_ [ HH.text "Dev → staging → prod pipeline" ]
                            , HH.li_ [ HH.text "Observability + alerting" ]
                            , HH.li_ [ HH.text "Security & secrets management" ]
                            ]
                        ]
                    , HH.div_
                        [ HH.div [ HP.attr (H.AttrName "class") "split-title" ] [ HH.text "How we start" ]
                        , HH.ul [ HP.attr (H.AttrName "class") "list-compact" ]
                            [ HH.li_ [ HH.text "30–45 min consult" ]
                            , HH.li_ [ HH.text "Audit + prioritized plan" ]
                            , HH.li_ [ HH.text "First delivery in days, not weeks" ]
                            ]
                        ]
                    ]
                , HH.div [ HP.attr (H.AttrName "class") "card-actions" ]
                    [ HH.a
                        [ HP.attr (H.AttrName "class") "btn btn-primary btn-block"
                        , HP.href "mailto:hhefesto@rdataa.com?subject=Availability%20Inquiry"
                        ]
                        [ HH.text "Ask about availability" ]
                    ]
                ]
            ]
        ]
    ]

pill txt =
  HH.span [ HP.attr (H.AttrName "class") "pill" ] [ HH.text txt ]

-- TESTIMONIAL / PROOF ------------------------------------------------------

testimonial =
  section "proof" "Selected Work"
    [ HH.div [ HP.attr (H.AttrName "class") "proof-grid" ]
        [ HH.figure [ HP.attr (H.AttrName "class") "card quote-card" ]
            [ HH.blockquote [ HP.attr (H.AttrName "class") "quote" ]
                [ HH.text "“From initial concept through production deployment, we architected and built "
                , HH.a [ HP.href "https://xpsoasis.org", HP.attr (H.AttrName "target") "_blank" ] [ HH.text "xpsoasis.org" ]
                , HH.text " and "
                , HH.a [ HP.href "https://xesoasis.org", HP.attr (H.AttrName "target") "_blank" ] [ HH.text "xesoasis.org" ]
                , HH.text " end-to-end: infra, CI/CD, reliability, and delivery. This isn’t marketing—these are running systems.”"
                ]
            , HH.figcaption [ HP.attr (H.AttrName "class") "quote-author" ]
                [ HH.div [ HP.attr (H.AttrName "class") "author-title" ]
                    [ HH.text "— Live projects shipped by our team" ]
                , HH.div [ HP.attr (H.AttrName "class") "muted" ]
                    [ HH.text "Production deployments • reproducible environments • documented handover" ]
                ]
            ]
        , HH.div [ HP.attr (H.AttrName "class") "card proof-card" ]
            [ HH.div [ HP.attr (H.AttrName "class") "card-kicker" ] [ HH.text "What this looks like" ]
            , HH.h3 [ HP.attr (H.AttrName "class") "card-title" ] [ HH.text "Concrete deliverables" ]
            , HH.ul [ HP.attr (H.AttrName "class") "list-compact" ]
                [ HH.li_ [ HH.text "Nix flake with hermetic builds (CI matches local)" ]
                , HH.li_ [ HH.text "Immutable servers + atomic deploys + rollback" ]
                , HH.li_ [ HH.text "Secrets managed (age/sops), no plaintext drift" ]
                , HH.li_ [ HH.text "Dashboards + alerts with actionable SLOs" ]
                ]
            , HH.div [ HP.attr (H.AttrName "class") "card-actions" ]
                [ HH.a
                    [ HP.attr (H.AttrName "class") "btn btn-secondary btn-block"
                    , HP.href "#contact"
                    ]
                    [ HH.text "Let’s map your setup" ]
                ]
            ]
        ]
    ]

-- CONTACT ------------------------------------------------------------------

contact =
  section "contact" "Ready to bulletproof your infrastructure?"
    [ HH.div [ HP.attr (H.AttrName "class") "contact-content" ]
        [ HH.p [ HP.attr (H.AttrName "class") "contact-subtitle" ]
            [ HH.text "Tell me about your current setup and where you want to be. I'll create a custom plan to get you there with Nix-powered reproducibility." ]
        , HH.div [ HP.attr (H.AttrName "class") "contact-methods" ]
            [ HH.a
                [ HP.attr (H.AttrName "class") "btn btn-primary btn-large"
                , HP.href "mailto:hhefesto@rdataa.com?subject=DevOps%20Transformation%20Inquiry"
                ]
                [ HH.text "📧 Start the conversation" ]
            , HH.div [ HP.attr (H.AttrName "class") "contact-note" ]
                [ HH.text "Usually respond within 4 hours during UTC-6 business hours • Free consultation call" ]
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

stat number label =
  HH.div [ HP.attr (H.AttrName "class") "stat" ]
    [ HH.div [ HP.attr (H.AttrName "class") "stat-number" ] [ HH.text number ]
    , HH.div [ HP.attr (H.AttrName "class") "stat-label" ] [ HH.text label ]
    ]

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
