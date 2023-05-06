{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

module Examples.Amm where

import Act.Execution
import Act.Prelude
import OpenGames
import OpenGames.Engine.OpenGames
import OpenGames.Engine.OpticClass
import OpenGames.Preprocessor

arity :: Address -> EVMType
arity = undefined

type Address = String

type EVMType = String

data Result = Swap0Out {g :: Double} | Swap1Out {g' :: Double} -- derived from act API
  deriving (Show)

data Strategy = Strategy Transaction
  deriving (Show)

proj :: Result -> Double
proj (Swap1Out n) = n
proj (Swap0Out n) = n

-- act questions :
--   - add gas?
--   - translate functions from act to OG and add gas to them

-- newtype GlobalState = GlobalState { getState :: Map String Double }

newtype Token = Token {getToken :: (String, Double)}
  deriving (Show) via (String, Double)

type ContractState = (Int, Int) -- derived from act Store

type MemPool = [Transaction] -- ????
-- type GlobalState = (Mempool, ContractState) -- ??????????????????

inRange :: a -> a -> Bool
inRange _ _ = True

ammManual :: ContractState -> Transaction -> ContractState
ammManual st@(reserve0, reserve1) (Transaction _ "swap0" [AbiIntType amt]) =
  if inRange amt reserve0 -- derived from preconditions
    then -- derived from implementation

      ( reserve0 + amt,
        (reserve0 * reserve1) `div` (reserve0 + amt) + 1
      )
    else st
ammManual st@(reserve0, reserve1) (Transaction _ "swap1" [AbiIntType amt]) =
  if inRange amt reserve1
    then
      ( (reserve0 * reserve1) `div` (reserve1 + amt) + 1,
        reserve1 + amt
      )
    else st

initAmm ::
  Double ->
  Double ->
  OpenGames.Engine.OpenGames.OpenGame
    OpenGames.Engine.OpticClass.StochasticStatefulOptic
    OpenGames.Engine.OpticClass.StochasticStatefulContext
    '[]
    '[]
    ()
    ()
    (Double, Double)
    ()
initAmm r1 r2 = forwardFunction (const (r1, r2))

combined :: [Transaction] -> (ContractState, ContractState) -> (ContractState, ContractState)
combined = combine (unionContracts ("amm1", ammManual) ("amm2", ammManual))
