module Main where

import Distribution.Gentoo.GHC
import Distribution.Gentoo.Packages
import Distribution.Gentoo.PkgManager

import System.Console.GetOpt
import System.Environment(getArgs, getProgName)
import System.Exit(ExitCode(..), exitWith)
import System.IO(hPutStrLn, stderr)
import Control.Monad(liftM, liftM2)

success     :: String -> IO a
success msg = do putStrLn msg
                 exitWith ExitSuccess

die     :: String -> IO a
die msg = do putErrLn msg
             exitWith (ExitFailure 1)

putErrLn :: String -> IO ()
putErrLn = hPutStrLn stderr

buildPkgsFrom       :: IO [Package] -> PkgManager ->  IO a
buildPkgsFrom ps pm = do ps' <- ps
                         if null ps'
                           then success "Nothing to build!"
                           else buildPkgs pm ps' >>= exitWith

ghcUpgrade    :: PkgManager -> IO a
ghcUpgrade pm = do putStrLn "Looking for packages from old GHC installs..."
                   buildPkgsFrom rebuildPkgs pm

ghcCheck    :: PkgManager -> IO a
ghcCheck pm = do putStrLn "Looking for packages that need to rebuilt..."
                 buildPkgsFrom brokenPkgs pm

ghcBoth    :: PkgManager -> IO a
ghcBoth pm = do putStrLn "Looking for packages from both old GHC \
                          \installs, and those that need to be rebuilt..."
                flip buildPkgsFrom pm $ liftM2 (++) brokenPkgs rebuildPkgs


data Flag = Help
          | Version
          | PM String
          | Check
          | Upgrade
          | Pretend
          deriving (Eq, Show)

help :: IO a
help = progInfo >>= success

err     :: String -> IO a
err msg = liftM addMsg progInfo >>= die
  where
    addMsg str = msg ++ "\n\n"++ str

progInfo :: IO String
progInfo = do name <- getProgName
              return $ usageInfo (header name) options
  where
    header name = name ++ " -- Find and rebuild packages broken due to either:\n\
                  \            * GHC upgrade\n\
                  \            * Haskell dependency upgrade\n\
                  \         Default action is to do both.\n\
                  \\n\
                  \Usage: " ++ name ++ " [Option]\n\
                  \\n\
                  \\n\
                  \Options:"


options :: [OptDescr Flag]
options =
  [ Option ['c']      ["dep-check"]       (NoArg Check)
            "Check dependencies of Haskell packages."
  , Option ['u']      ["upgrade"]         (NoArg Upgrade)
            "Rebuild Haskell packages after a GHC upgrade."
  , Option ['P']      ["package-manager"] (ReqArg PM "PM")
            "Use package manager PM, where PM can be one of:\n\
              \  * portage (default)\n\
              \  * pkgcore\n\
              \  * paludis"
  , Option ['p']      ["pretend"]         (NoArg Pretend)
            "Only pretend to build packages, currently ignored."
  , Option ['v']      ["version"]         (NoArg Version)
            "Version information."
  , Option ['h', '?'] ["help"]            (NoArg Help)
            "Print this help message."
  ]
