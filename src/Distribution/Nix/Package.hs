{-# LANGUAGE DeriveGeneric #-}

module Distribution.Nix.Package where

import Data.Aeson ( FromJSON(..), ToJSON(..) )
import Data.Aeson.Types ( defaultOptions, genericParseJSON, genericToJSON )
import Data.Text (Text)
import GHC.Generics

import Distribution.Nix.Fetch

data Package build
  = Package
    { version :: !Text
    , fetch :: !Fetch
    , build :: !build
    , deps :: ![Text]
    }
  deriving Generic

instance FromJSON build => FromJSON (Package build) where
  parseJSON = genericParseJSON defaultOptions

instance ToJSON build => ToJSON (Package build) where
  toJSON = genericToJSON defaultOptions
