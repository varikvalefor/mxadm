{-# LANGUAGE TemplateHaskell #-}

module Rooms where
import qualified Data.Aeson as A;
import Data.Aeson.TH;

data Sync = Sync {
  rooms :: Rooms,
  next_batch :: Maybe String
}

data Rooms = Rooms {
  join :: [(String, JoinedRoom)]
} deriving (Show, Read);

data JoinedRoom = JoinedRoom {
  timeline :: Timeline
} deriving (Show, Read);

data Timeline = Timeline {
  events :: [ClientEventNoRoomId]
} deriving (Show, Read);

data ClientEventNoRoomId = ClientEventNoRoomId {
  xxcontent :: Content,
  xxsender :: String,
  xxtype :: String,
  xxevent_id :: String
} deriving (Show, Read);

data Content = Content {
  body :: Maybe String
} deriving (Show, Read);

deriveJSON defaultOptions ''Content;

deriveJSON defaultOptions {fieldLabelModifier = drop 2} ''ClientEventNoRoomId;

deriveJSON defaultOptions ''Timeline;

deriveJSON defaultOptions ''JoinedRoom;

deriveJSON defaultOptions ''Rooms;

deriveJSON defaultOptions ''Sync;
