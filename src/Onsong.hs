module Onsong
    ( Paragraph
    , splitParagraph
    , parseSongParagraph
    ) where

import Data.Text (Text, pack, unpack)
import Text.Parsec

import qualified Data.Text as T

-- create an alias for [Text]
type Paragraph = [Text]

splitParagraph :: [Text] -> [Paragraph]
splitParagraph songLines = splitAts (findParagraph songLines) songLines

splitAts xs text = split text (reverse xs)
    where split t [] = [t]
          split t (y:ys) = (split (take (y-1) t) ys) ++ [drop y t]

-- or the alternative:
{-
splitAts xs text = split text (diffList xs)
    where split t [] = [t]
          split t (y:ys) = (take y t):(split (drop y t) ys)

-- diffList subtracts the first item in the list from the rest for all elements
diffList = f . (0:)
    where f [_] = []
          f (a:b:xs) = (b-a):(f . (b:)) xs
-}

findParagraph = filter (/=0) . zipWith (*) [1..] . map (fromEnum . T.null)

-- or again the alternatives:
{-
findParagraph = filter (/=0) . map (\(i,x) -> i * (fromEnum . T.null) x) . zip [1..]

findParagraph = filter (/=0) . map (uncurry(*)) . zip [1..] . map (fromEnum . T.null)
-}

-- Functions to parse the 'tail' of the file or the actual song
-- this should work for both .onsong and .chopro files
-- Metadata is going to be parsed extra
parseParagraphHeader :: Parsec String () String
parseParagraphHeader = do
    header <- manyTill anyChar (try (char ':'))
    return (convertHeader header)
        where convertHeader h = "<h3>" ++ h ++ "</h3>\n<p>"

parseSongLine :: Text -> Text
parseSongLine line = (T.replace (pack "[") openingTag . T.replace (pack "]") closingTag) (T.append line (pack "<br>"))
    where openingTag = pack "<span class=\"chord\"><span class=\"text\">"
          closingTag = pack "</span></span>"

parseSongParagraph :: Paragraph -> Paragraph
parseSongParagraph p = (header p):(map (parseSongLine) (tail p)) ++ [pack "</p>\n"]
    where parsedHeader h = parse (parseParagraphHeader) "(source)" ((unpack . head) h)
          header h = case (parsedHeader h) of
                         Right text -> pack text
                         Left _ -> pack "error!!!"

