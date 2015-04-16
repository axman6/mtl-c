{-# LANGUAGE Trustworthy, Rank2Types, FlexibleInstances, FlexibleContexts, MultiParamTypeClasses #-}
module Control.Monad.State.CPS where
import Control.Monad.State.Class
import Control.Applicative
import Control.Monad.Identity
import Control.Monad.Trans
import Control.Monad.Morph
import Unsafe.Coerce

newtype StateT s m a = StateT { unStateT :: forall r. s -> (a -> s -> m r) -> m r }

runStateT :: Monad m => StateT s m a -> s -> m (a, s)
runStateT m s = unStateT m s (\a s -> return (a, s))
{-# INLINABLE runStateT #-}

evalStateT :: Monad m => StateT s m a -> s -> m a
evalStateT m s = unStateT m s $ \a _ -> return a
{-# INLINABLE evalStateT #-}

execStateT :: Monad m => StateT s m a -> s -> m s
execStateT m s = unStateT m s $ \_ s -> return s
{-# INLINABLE execStateT #-}

mapStateT :: (Monad m, Monad n) => (m (a, s) -> n (b, s)) -> StateT s m a -> StateT s n b
mapStateT t m = StateT $ \s c -> t (unStateT m s (\a s -> return (a, s))) >>= \(b, s') -> c b s'

instance Functor (StateT s m) where
    fmap f m = StateT $ \s c -> unStateT m s (c . f)
    {-# INLINABLE fmap #-}

instance Applicative (StateT s m) where
    pure x = StateT $ \s c -> c x s
    {-# INLINABLE pure #-}
    mf <*> ma = StateT $ \s c -> unStateT mf s (\f s' -> unStateT ma s' (c . f))
    {-# INLINABLE (<*>) #-}

instance Monad (StateT s m) where
    return x = StateT $ \s c -> c x s
    {-# INLINABLE return #-}
    m >>= k = StateT $ \s c -> unStateT m s (\a s' -> unStateT (k a) s' c)

instance MonadState s (StateT s m) where
    get = StateT $ \s c -> c s s
    {-# INLINABLE get #-}
    put s = StateT $ \_ c -> c () s
    {-# INLINABLE put #-}
    state f = StateT $ \s c -> uncurry c (f s)
    {-# INLINABLE state #-}

instance MonadTrans (StateT s) where
    lift m = StateT $ \s c -> m >>= \a -> c a s
    {-# INLINABLE lift #-}

type State s = StateT s Identity

runState :: State s a -> s -> (a, s)
runState = (unsafeCoerce `asTypeOf` (runIdentity.)) . runStateT
{-# INLINABLE runState #-}

evalState :: State s a -> s -> a
evalState = (unsafeCoerce `asTypeOf` (runIdentity.)) . evalStateT
{-# INLINABLE evalState #-}

execState :: State s a -> s -> s
execState = (unsafeCoerce `asTypeOf` (runIdentity.)) . execStateT
{-# INLINABLE execState #-}
