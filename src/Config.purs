module Config where

import Prelude

-- These are replaced at build time by Vite
foreign import apiUrl :: String
foreign import environment :: String
foreign import buildTime :: String
foreign import analyticsId :: String

isProduction :: Boolean
isProduction = environment == "production"

isDevelopment :: Boolean
isDevelopment = environment == "development"

-- Check if analytics should be loaded
hasAnalytics :: Boolean
hasAnalytics = analyticsId /= ""
