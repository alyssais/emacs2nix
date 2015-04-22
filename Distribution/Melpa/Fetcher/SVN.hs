{-# LANGUAGE DeriveGeneric #-}

module Distribution.Melpa.Fetcher.SVN where

import Data.Aeson
import Data.Aeson.Types (defaultOptions)
import Data.Text (Text)
import GHC.Generics

data SVN =
  Fetcher
  { url :: Text
  }
  deriving (Eq, Generic, Read, Show)

instance ToJSON SVN where
  toJSON = genericToJSON defaultOptions

instance FromJSON SVN where
  parseJSON = genericParseJSON defaultOptions
