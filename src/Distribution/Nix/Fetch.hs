{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Distribution.Nix.Fetch where

import Control.Error
import Control.Monad.IO.Class
import Data.Aeson (FromJSON(..), ToJSON(..))
import Data.Aeson.Types
  ( Options(..), SumEncoding(..), defaultOptions
  , genericParseJSON, genericToJSON )
import qualified Data.Char as Char
import qualified Data.Map.Strict as M
import Data.Text (Text)
import qualified Data.Text as T
import GHC.Generics
import System.Environment (getEnvironment)
import qualified System.IO.Streams as S

import Util (runInteractiveProcess)

data Fetch = URL { url :: Text, sha256 :: Maybe Text }
           | Git { url :: Text, rev :: Text, branchName :: Maybe Text, sha256 :: Maybe Text }
           | Bzr { url :: Text, rev :: Text, sha256 :: Maybe Text }
           | CVS { url :: Text, cvsModule :: Maybe Text, sha256 :: Maybe Text }
           | Hg { url :: Text, rev :: Text, sha256 :: Maybe Text }
           | SVN { url :: Text, rev :: Text, sha256 :: Maybe Text }
           deriving Generic

fetchOptions :: Options
fetchOptions = defaultOptions
               { constructorTagModifier = ("fetch" ++) . map Char.toLower
               , sumEncoding = ObjectWithSingleField
               , omitNothingFields = True
               , fieldLabelModifier = fetchLabelModifier
               }
  where
    fetchLabelModifier field =
      case field of
        "cvsModule" -> "module"
        _ -> field

instance FromJSON Fetch where
  parseJSON = genericParseJSON fetchOptions

instance ToJSON Fetch where
  toJSON = genericToJSON fetchOptions

addToEnv :: MonadIO m => String -> String -> m [(String, String)]
addToEnv var val = liftIO $ M.toList . M.insert var val . M.fromList <$> getEnvironment

prefetch :: Text -> Fetch -> EitherT String IO (FilePath, Fetch)

prefetch _ fetch@(URL {..}) = do
  let args = [T.unpack url]
  env <- addToEnv "PRINT_PATH" "1"
  runInteractiveProcess "nix-prefetch-url" args Nothing (Just env) $ \out -> EitherT $ do
    hashes <- S.lines out >>= S.decodeUtf8 >>= S.toList
    case hashes of
      (hash:path:_) -> return (Right (T.unpack path, fetch { sha256 = Just hash }))
      _ -> return (Left "unable to prefetch")

prefetch _ fetch@(Git {..}) = do
  let args = ["--url", T.unpack url, "--rev", T.unpack rev]
             ++ fromMaybe [] (do name <- branchName
                                 return ["--branch-name", T.unpack name])
  env <- addToEnv "PRINT_PATH" "1"
  runInteractiveProcess "nix-prefetch-git" args Nothing (Just env) $ \out -> EitherT $ do
    hashes <- S.lines out >>= S.decodeUtf8 >>= S.toList
    case hashes of
      (_:_:hash:path:_) -> return (Right (T.unpack path, fetch { sha256 = Just hash }))
      _ -> return (Left "unable to prefetch")

prefetch _ fetch@(Bzr {..}) = do
  let args = [T.unpack url, T.unpack rev]
  env <- addToEnv "PRINT_PATH" "1"
  runInteractiveProcess "nix-prefetch-bzr" args Nothing (Just env) $ \out -> EitherT $ do
    hashes <- S.lines out >>= S.decodeUtf8 >>= S.toList
    case hashes of
      (_:hash:path:_) -> return (Right (T.unpack path, fetch { sha256 = Just hash }))
      _ -> return (Left "unable to prefetch")

prefetch _ fetch@(Hg {..}) = do
  let args = [T.unpack url, T.unpack rev]
  env <- addToEnv "PRINT_PATH" "1"
  runInteractiveProcess "nix-prefetch-hg" args Nothing (Just env) $ \out -> EitherT $ do
    hashes <- S.lines out >>= S.decodeUtf8 >>= S.toList
    case hashes of
      (_:hash:path:_) -> return (Right (T.unpack path, fetch { sha256 = Just hash }))
      _ -> return (Left "unable to prefetch")

prefetch name fetch@(CVS {..}) = do
  let args = [T.unpack url, T.unpack (fromMaybe name cvsModule)]
  runInteractiveProcess "nix-prefetch-cvs" args Nothing Nothing $ \out -> EitherT $ do
    hashes <- S.lines out >>= S.decodeUtf8 >>= S.toList
    case hashes of
      (hash:path:_) -> return (Right (T.unpack path, fetch { sha256 = Just hash }))
      _ -> return (Left "unable to prefetch")

prefetch _ fetch@(SVN {..}) = do
  let args = [T.unpack url, T.unpack rev]
  env <- addToEnv "PRINT_PATH" "1"
  runInteractiveProcess "nix-prefetch-svn" args Nothing (Just env) $ \out -> EitherT $ do
    hashes <- S.lines out >>= S.decodeUtf8 >>= S.toList
    case hashes of
      (_:hash:path:_) -> return (Right (T.unpack path, fetch { sha256 = Just hash }))
      _ -> return (Left "unable to prefetch")