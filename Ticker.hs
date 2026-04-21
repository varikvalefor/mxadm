{-# LANGUAGE OverloadedStrings #-}

module Ticker where

import qualified Rooms as R;
import Rooms (Sync, ClientEventNoRoomId);

import Data.List;
import Data.Maybe;
import Control.Lens;
import Control.Monad;
import Data.Aeson.Lens;
import Network.HTTP.Simple;

import Control.Concurrent;

import qualified Data.Aeson as A;
import qualified Data.Aeson.Lens as A;

import qualified Data.Text as T;
import qualified Data.Text.Internal.Lazy as T;

import qualified Data.ByteString.Lazy as BSL;
import qualified Data.ByteString.Lazy.UTF8 as BSL;

import qualified Data.ByteString.Char8 as B8;



type FlibaC x = Either ErrorCode x;

type HttpDanfu = FlibaC (Response B8.ByteString);

type DanfuFancu = Cfg -> Msg -> HttpDanfu -> IO ();



data TFancu = TFancu {
  mapti :: Msg -> Bool,
  cpedu :: Cfg -> Msg -> Request,
  pensiPeha :: Maybe DanfuFancu
};

data ErrorCode = TolmaptiSync
               | NoAuth
               | NaCiksi String
               | HttpErr Integer
               deriving (Show, Eq, Read);

data Msg = Msg {
  evtId :: String,
  benji :: String,
  xbid :: String,
  body :: Maybe String
};

data Cfg = Cfg {
  rejgauCfg :: Cfg -> IO (),
  milsniduCoDenpa :: Int,
  homeserverUri :: String,
  accessToken :: String,
  filterId :: Maybe String,
  since :: Maybe String,
  fs :: [TFancu]
};



httpBS' :: Request -> IO HttpDanfu;
httpBS' = fmap ((\r -> f r $ getResponseStatusCode r)) . httpBS
  where
  {
    f :: Response B8.ByteString -> Int -> HttpDanfu;
    f r c = if c `mod` 100 /= 2 then Left $ HttpErr (fromIntegral c) else Right r;
  };



wAuth :: Cfg -> Request -> Request;
wAuth c = addRequestHeader "Authorization" ckiku
  where
  {
    ckiku = B8.pack $ "Bearer " ++ accessToken c;
  };



httpBSc :: Cfg -> Request -> IO HttpDanfu;
httpBSc c = httpBS' . wAuth c;



sGenturfahi :: Cfg -> String -> FlibaC (Cfg, [Msg]);
sGenturfahi c = maybe srera (Right . selbehi) . d
  where
  {
    d = A.decode . BSL.fromString;
  
    srera = Left TolmaptiSync;
  
    selbehi :: Sync -> (Cfg, [Msg]);
    selbehi s = (c' , concatMap (\(k,x) -> map (f k) $ e x) $ j s)
      where
      {
        j = R.join . R.rooms;
  
        e = R.events . R.timeline;
  
        f :: String -> ClientEventNoRoomId -> Msg;
        f k x = Msg {
          evtId = R.xxevent_id x,
          benji = R.xxsender x,
          xbid = k,
          body = R.body $ R.xxcontent x
        };
  
        c' = c {filterId = R.next_batch s};
      };
  };

sync :: Cfg -> IO (FlibaC (Cfg, [Msg]));
sync c = either Left (sGenturfahi c) <$> syncHttp
  where
  {
    syncHttp :: IO (FlibaC String);
    syncHttp = (maybe
                 (pure $ Left $ HttpErr 0)
                 (fmap (fmap $ B8.unpack . getResponseBody) . httpBSc c)
                 r)
      where
      {
        r :: Maybe Request;
        r = ((parseRequest . concat)
             [(homeserverUri c ++ "/_matrix/client/v3/sync"),
              (let sinceS = maybe "" (("?" ++) . ("since=" ++)) $ since c in
               let sf x = if null sinceS then [] else x ++ sinceS in
               maybe
                (sf "?")
                (\f -> "?filter=" ++ f ++ sf "&")
                (filterId c))]);
      };
  };



doit :: Cfg -> Msg -> IO ();
doit c m = case find (flip mapti m) $ fs c of
  Nothing -> pure ()
  Just x -> httpBS' (cpedu x c m) >>= ef' (pensiPeha x) c
  where
  {
    ef' :: Maybe DanfuFancu -> Cfg -> HttpDanfu -> IO ();
    ef' ef c = fromMaybe d ef c m
      where {
        d _ _ = either print $ \_ -> pure ();
      };
  };



ticker :: Cfg -> IO ();
ticker c = sync c >>= either (\x -> print x >> ticker c) (uncurry lp)
    where
    {
      lp :: Cfg -> [Msg] -> IO ();
      lp c' m = mapM_ (doit c') m >>
                rejgauCfg c' c' >>
                threadDelay (milsniduCoDenpa c') >>
                ticker c';
    };
