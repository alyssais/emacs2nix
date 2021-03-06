{-

emacs2nix - Generate Nix expressions for Emacs packages
Copyright (C) 2016 Thomas Tuegel

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

-}

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ViewPatterns #-}

module Distribution.Melpa.Melpa
  ( Melpa (..), packageBuildDir
  , ParseMelpaError (..)
  , Stable (..)
  ) where

import Control.Exception ( Exception )
import Data.Text ( Text )
import Data.Typeable ( Typeable )
import System.FilePath


data Melpa =
  Melpa
  { melpaDir :: FilePath
  , melpaCommit :: Text
  }

data ParseMelpaError = ParseMelpaError String
  deriving (Show, Typeable)

instance Exception ParseMelpaError


newtype Stable = Stable { stable :: Bool }


packageBuildDir :: Melpa -> FilePath
packageBuildDir Melpa {..} = melpaDir </> "package-build"
