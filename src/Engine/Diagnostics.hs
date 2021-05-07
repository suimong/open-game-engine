{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE AllowAmbiguousTypes #-}


module Engine.Diagnostics
  ( DiagnosticInfoBayesian(..)
  , generateOutput
  , generateIsEq
  , generateContext
  , generateContextWType
  ) where

import Engine.OpticClass
import Engine.TLL


--------------------------------------------------------
-- Diagnosticinformation and processesing of information
-- for standard game-theoretic analysis

-- Defining the necessary types for outputting information of a BayesianGame
data DiagnosticInfoBayesian x y = DiagnosticInfoBayesian
  { equilibrium     :: Bool
  , player          :: String
  , optimalMove     :: y
  , strategy        :: Stochastic y
  , optimalPayoff   :: Double
  , context         :: (y -> Double)
  , payoff          :: Double
  , state           :: x
  , unobservedState :: String}


-- prepare string information for Bayesian game
showDiagnosticInfo :: (Show y, Ord y, Show x) => DiagnosticInfoBayesian x y -> String
showDiagnosticInfo info =  
     "\n"    ++ "Player: " ++ player info
     ++ "\n" ++ "Optimal Move: " ++ (show $ optimalMove info)
     ++ "\n" ++ "Current Strategy: " ++ (show $ strategy info)
     ++ "\n" ++ "Optimal Payoff: " ++ (show $ optimalPayoff info)
     ++ "\n" ++ "Current Payoff: " ++ (show $ payoff info)
     ++ "\n" ++ "Observable State: " ++ (show $ state info)
     ++ "\n" ++ "Unobservable State: " ++ (show $ unobservedState info)

-- extract context for a player with _name_
extractContext :: DiagnosticInfoBayesian x y -> (String, (y -> Double))
extractContext  info =  (player info, context info)

-- extract context for a player with _name_ for the whole output
extractContextL :: [DiagnosticInfoBayesian x y] -> [(String,(y -> Double))]
extractContextL  []  = []
extractContextL  xs  = fmap extractContext xs

-- extract context for a player with _name_ and _type_
extractContextWType ::Show x => DiagnosticInfoBayesian x y -> ((String, String), (y -> Double))
extractContextWType  info =  ((player info, show $ state info), context info)

-- extract context for a player with _name_ for the whole output
extractContextWTypeL :: Show x => [DiagnosticInfoBayesian x y] -> [((String, String), (y -> Double))]
extractContextWTypeL  []  = []
extractContextWTypeL  xs  = fmap extractContextWType xs



-- output string information for a subgame expressions containing information from several players - bayesian 
showDiagnosticInfoL :: (Show y, Ord y, Show x) => [DiagnosticInfoBayesian x y] -> String
showDiagnosticInfoL [] = "\n --No more information--"
showDiagnosticInfoL (x:xs)  = showDiagnosticInfo x ++ "\n --other game-- " ++ showDiagnosticInfoL xs 

-- checks equilibrium and if not outputs relevant deviations
checkEqL :: (Show y, Ord y, Show x) => [DiagnosticInfoBayesian x y] -> String
checkEqL ls = let xs = fmap equilibrium ls
                  ys = filter (\x -> equilibrium x == False) ls
                  isEq = and xs
                  in if isEq == True then "\n Strategies are in equilibrium"
                                      else "\n Strategies are NOT in equilibrium. Consider the following profitable deviations: \n"  ++ showDiagnosticInfoL ys

----------------------------------------------------------
-- providing the relevant functionality at the type level
-- for show output

data ShowDiagnosticOutput = ShowDiagnosticOutput

instance (Show y, Ord y, Show x) => Apply ShowDiagnosticOutput [DiagnosticInfoBayesian x y] String where
  apply _ x = showDiagnosticInfoL x


data PrintIsEq = PrintIsEq

instance (Show y, Ord y, Show x) => Apply PrintIsEq [DiagnosticInfoBayesian x y] String where
  apply _ x = checkEqL x


data PrintOutput = PrintOutput

instance (Show y, Ord y, Show x) => Apply PrintOutput [DiagnosticInfoBayesian x y] String where
  apply _ x = showDiagnosticInfoL x


data Concat = Concat

instance Apply Concat String (String -> String) where
  apply _ x = \y -> x ++ "\n NEWGAME: \n" ++ y

-- for extracting Context

data ExtractContext = ExtractContext

instance Apply ExtractContext [DiagnosticInfoBayesian x y] [(String,(y -> Double))] where
  apply _ x = extractContextL  x

data ExtractContextWType = ExtractContextWType

instance Show x => Apply ExtractContextWType [DiagnosticInfoBayesian x y] [((String, String), (y -> Double))] where
  apply _ x = extractContextWTypeL  x



---------------------
-- main functionality

-- all information for all players
generateOutput :: forall xs.
               ( MapL   PrintOutput xs     (ConstMap String xs)
               , FoldrL Concat String (ConstMap String xs)
               ) => List xs -> IO ()
generateOutput hlist = putStrLn $
  "----Analytics begin----" ++ (foldrL Concat "" $ mapL @_ @_ @(ConstMap String xs) PrintOutput hlist) ++ "----Analytics end----\n"

-- output equilibrium relevant information
generateIsEq :: forall xs.
               ( MapL   PrintIsEq xs     (ConstMap String xs)
               , FoldrL Concat String (ConstMap String xs)
               ) => List xs -> IO ()
generateIsEq hlist = putStrLn $
  "----Analytics begin----" ++ (foldrL Concat "" $ mapL @_ @_ @(ConstMap String xs) PrintIsEq hlist) ++ "----Analytics end----\n"

-- generate context for a given player
generateContext :: forall xs y.
               ( MapL  ExtractContext xs (ConstMap [(String, (y -> Double))] xs)
               ) => List xs -> List (ConstMap [(String, (y -> Double))] xs)
generateContext hlist = mapL @_ @_ @(ConstMap [(String, (y -> Double))] xs) ExtractContext hlist 


-- generate context with type for a given player
generateContextWType :: forall xs y x.
               ( MapL  ExtractContextWType xs (ConstMap [((String, String), (y -> Double))] xs)
               ) => List xs -> List (ConstMap [((String, String), (y -> Double))] xs)
generateContextWType hlist = mapL @_ @_ @(ConstMap [((String, String), (y -> Double))] xs) ExtractContextWType hlist 

