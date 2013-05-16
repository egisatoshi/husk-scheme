{- |
Module      : Main
Copyright   : Justin Ethier
Licence     : MIT (see LICENSE in the distribution)

Maintainer  : github.com/justinethier
Stability   : experimental
Portability : portable

A front-end for an experimental compiler
-}

module Main where
import Paths_husk_scheme
import Language.Scheme.Compiler
import qualified Language.Scheme.Core
import Language.Scheme.Types     -- Scheme data types
import Language.Scheme.Variables -- Scheme variable operations
import Control.Monad.Error
import System.Cmd (system)
import System.Console.GetOpt
import System.FilePath (dropExtension)
import System.Environment
import System.Exit (ExitCode (..), exitWith, exitFailure)
import System.IO

main :: IO ()
main = do 

  putStrLn ""
  putStrLn "!!! This version of huskc is Experimental !!!"
  putStrLn ""
  putStrLn "You might want to consult the issue list before use:"
  putStrLn "https://github.com/justinethier/husk-scheme/issues"
  putStrLn ""

  -- Read command line args and process options
  args <- getArgs
  let (actions, nonOpts, msgs) = getOpt Permute options args
  opts <- foldl (>>=) (return defaultOptions) actions
  let Options {optOutput = output, optDynamic = dynamic, optCustomOptions = extra} = opts

  if null nonOpts
     then showUsage
     else do
        let inFile = nonOpts !! 0
            outHaskell = (dropExtension inFile) ++ ".hs"
            outExec = case output of
              Just inFile -> inFile
              Nothing -> dropExtension inFile
            extraOpts = case extra of
              Just args -> args
              Nothing -> ""
        process inFile outHaskell outExec dynamic extraOpts

-- 
-- For an explanation of the command line options code, see:
-- http://leiffrenzel.de/papers/commandline-options-in-haskell.html
--

-- |Data type to handle command line options that take parameters
data Options = Options {
    optOutput :: Maybe String, -- Executable file to write
    optDynamic :: Bool, -- Flag for dynamic linking of compiled executable
    optCustomOptions :: Maybe String -- Custom options to ghc
    }

-- |Default values for the command line options
defaultOptions :: Options
defaultOptions = Options {
    optOutput = Nothing,
    optDynamic = False,
    optCustomOptions = Nothing 
    }

-- |Command line options
options :: [OptDescr (Options -> IO Options)]
options = [
  Option ['V'] ["version"] (NoArg showVersion) "show version number",
  Option ['h', '?'] ["help"] (NoArg showHelp) "show usage information",
  Option [] ["debug"] (NoArg showDebug) "show debug information",
  Option ['o'] ["output"] (ReqArg writeExec "FILE") "output file to write",
  Option ['d'] ["dynamic"] (NoArg getDynamic) "use dynamic linking for the compiled executable",
  Option ['x'] ["extra"] (ReqArg getExtraArgs "Args") "extra arguments to ghc"
  ]

-- |Determine executable file to write. 
--  This version just takes a name from the command line option
writeExec arg opt = return opt { optOutput = Just arg }

getDynamic opt = return opt { optDynamic = True }

getExtraArgs arg opt = return opt { optCustomOptions = Just arg }

-- TODO: would nice to have this as well as a 'real' usage printout, perhaps via --help

-- |Print a usage message
showUsage :: IO ()
showUsage = do
  putStrLn "huskc: no input files"

showHelp :: Options -> IO Options
showHelp _ = do
  putStrLn "Usage: huskc [options] file"
  putStrLn ""
  putStrLn "Options:"
  putStrLn "  --help                Display this information"
  putStrLn "  --version             Display husk version information"
  putStrLn "  --output filename     Write executable to the given filename"
  putStrLn "  --dynamic             Use dynamic Haskell libraries, if available"
  putStrLn "                        (Requires libraries built via --enable-shared)"
  putStrLn "  --extra args          Pass extra arguments directly to ghc"
  putStrLn ""
  exitWith ExitSuccess

-- |Print debug information
showDebug :: Options -> IO Options
showDebug _ = do
  stdlib <- getDataFileName "lib/stdlib.scm"
  putStrLn $ "stdlib: " ++ stdlib
  putStrLn ""
  exitWith ExitSuccess

-- |Print version information
showVersion :: Options -> IO Options
showVersion _ = do
  putStrLn Language.Scheme.Core.version
-- TODO: would be nice to be able to print the banner:  Language.Scheme.Core.showBanner
  exitWith ExitSuccess

-- |High level code to compile the given file
process :: String -> String -> String -> Bool -> String -> IO ()
process inFile outHaskell outExec dynamic extraArgs = do


-- TODO: how to integrate r5rsEnv and libraries?


  env <- Language.Scheme.Core.r5rsEnv
  stdlib <- getDataFileName "lib/stdlib.scm"
  srfi55 <- getDataFileName "lib/srfi/srfi-55.scm" -- (require-extension)
-- TODO: replace this with a command line option that will pass Nothing to
--       skip compilation of standard libraries
--  result <- (Language.Scheme.Core.runIOThrows $ liftM show $ compileSchemeFile env Nothing srfi55 inFile outHaskell)
  result <- (Language.Scheme.Core.runIOThrows $ liftM show $ compileSchemeFile env (Just stdlib) srfi55 inFile outHaskell)
  case result of
   Just errMsg -> putStrLn errMsg
   _ -> compileHaskellFile outHaskell outExec dynamic extraArgs

-- |Compile a scheme file to haskell
compileSchemeFile :: Env -> Maybe String -> String -> String -> String -> IOThrowsError LispVal
compileSchemeFile env stdlib srfi55 filename outHaskell = do
  let conv :: LispVal -> String
      conv (String s) = s
  (String nextFunc, libsC, libSrfi55C) <- case stdlib of
    Nothing -> return (String "run", [], [])
    Just stdlib' -> do
      -- TODO: it is only temporary to compile the standard library each time. It should be 
      --       precompiled and just added during the ghc compilation
      libsC <- compileLisp env stdlib' "run" (Just "exec55")
      libSrfi55C <- compileLisp env srfi55 "exec55" (Just "exec55_2")
      liftIO $ Language.Scheme.Core.registerExtensions env getDataFileName
      return (String "exec", libsC, libSrfi55C)

  -- Initialize the compiler module and begin
  _ <- initializeCompiler env
  execC <- compileLisp env filename nextFunc Nothing

  -- Append any additional import modules
  List imports <- getNamespacedVar env 't' {-"internal"-} "imports"
  let moreHeaderImports = map conv imports

  outH <- liftIO $ openFile outHaskell WriteMode
  _ <- liftIO $ writeList outH headerModule
  _ <- liftIO $ writeList outH $ map (\mod -> "import " ++ mod ++ " ") $ headerImports ++ moreHeaderImports
  filepath <- liftIO $ getDataFileName ""
  _ <- liftIO $ writeList outH $ header filepath
  _ <- liftIO $ case stdlib of
    Just _ -> do
      _ <- writeList outH $ map show libsC
      _ <- hPutStrLn outH " ------ END OF STDLIB ------"
      _ <- writeList outH $ map show libSrfi55C
      hPutStrLn outH " ------ END OF SRFI 55 ------"
    Nothing -> do
      hPutStrLn outH "exec _ _ _ _ = return $ Nil \"\"" -- Placeholder
  _ <- liftIO $ writeList outH $ map show execC
  _ <- liftIO $ hClose outH
  if not (null execC)
     then return $ Nil "" -- Dummy value
     else throwError $ Default "Empty file" --putStrLn "empty file"

-- |Compile the intermediate haskell file using GHC
compileHaskellFile :: String -> String -> Bool -> String -> IO() --ThrowsError LispVal
compileHaskellFile hsInFile objOutFile dynamic extraArgs = do
  let ghc = "ghc" -- Need to make configurable??
      dynamicArg = if dynamic then "-dynamic" else ""
  compileStatus <- system $ ghc ++ " " ++ dynamicArg ++ " " ++ extraArgs ++ " -cpp --make -package ghc -o " ++ objOutFile ++ " " ++ hsInFile

-- TODO: delete intermediate hs files if requested

  case compileStatus of
    ExitFailure _code -> exitWith compileStatus
    ExitSuccess -> return ()

-- |Helper function to write a list of abstract Haskell code to file
writeList outH (l : ls) = do
  hPutStrLn outH l
  writeList outH ls
writeList outH _ = do
  hPutStr outH ""


