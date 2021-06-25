module OpenGames.Engine.OpenGamesClass where

-- The idea of this class is to allow the preprocessor to be generic between different flavours of open game
-- Code generated by the preprocessor will only call functions in this file

class OG g where
  fromLens :: (Eq x, Eq y) => (x -> y) -> (x -> r -> s) -> g () x s y r
  reindex  :: (Eq x, Eq y) => (a -> b) -> g b x s y r -> g a x s y r
  (>>>)    :: (Eq x, Eq y, Eq z) => g a x s y r -> g b y r z q -> g (a, b) x s z q
  (&&&)    :: (Eq x1, Eq x2, Eq y1, Eq y2, Show x1, Show x2) => g a x1 s1 y1 r1 -> g b x2 s2 y2 r2 -> g (a, b) (x1, x2) (s1, s2) (y1, y2) (r1, r2)
  (+++)    :: (Eq x1, Eq x2, Eq y1, Eq y2) => g a x1 s y1 r -> g b x2 s y2 r -> g (a, b) (Either x1 x2) s (Either y1 y2) r

fromFunctions :: (Eq x, Eq y, OG g) => (x -> y) -> (r -> s) -> g () x s y r
fromFunctions f g = fromLens f (const g)

counit :: (Eq x, OG g) => g () x x () ()
counit = fromLens (const ()) const

counitFunction :: (Eq x, Eq y, OG g) => (x -> y) -> g () x y () ()
counitFunction f = fromLens (const ()) (const . f)

population :: (Eq x, Show x, OG g, Eq y) => [g a x s y r] -> g [a] [x] [s] [y] [r]
population = foldr1 q . map p
  where p g = reindex (\[a] -> (((), a), ()))
                      ((fromLens (\[x] -> x) (\[x] s -> [s])
                        >>> g)
                        >>> fromLens (\y -> [y]) (\y [r] -> r))
        q g h = reindex (\as -> (((), ([head as], tail as)), ()))
                        ((fromLens (\xs -> ([head xs], tail xs)) (\_ ([s], ss) -> s : ss)
                          >>> (g &&& h))
                          >>> fromLens (\([y], ys) -> y : ys) (\_ rs -> ([head rs], tail rs)))
