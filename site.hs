{-# LANGUAGE OverloadedStrings #-}
--------------------------------------------------------------------------------
import              Data.Monoid (mappend)
import              Hakyll
import              Data.Functor ((<$>))
import              Data.List (sortBy, intercalate)
import              System.FilePath (takeFileName)
import              Data.Time.Format (parseTime)
import              System.Locale (defaultTimeLocale)
import              Data.Time.Clock (UTCTime)
import              Control.Applicative

--------------------------------------------------------------------------------

main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "pages/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= saveSnapshot "content"
            >>= relativizeUrls

    create ["index.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Billets"             `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls

    -- Render RSS feed
    create ["rss.xml"] $ do
        route idRoute
        compile $ do
            posts <- loadAllSnapshots "posts/*" "content"
            sorted <- take 10 <$> recentFirst posts
            renderRss feedConfiguration feedCtx (take 10 sorted)

    create ["atom.xml"] $ do
        route idRoute
        compile $ do
            posts <- loadAllSnapshots "posts/*" "content"
            sorted <- take 10 <$> recentFirst posts
            renderAtom feedConfiguration feedCtx sorted

    match "templates/*" $ compile templateCompiler

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%d/%m/%Y" `mappend`
    field "nextPost" nextPostUrl `mappend`
    field "prevPost" previousPostUrl `mappend`
    defaultContext

feedCtx :: Context String
feedCtx =
    bodyField "description" `mappend`
    postCtx


feedConfiguration :: FeedConfiguration
feedConfiguration = FeedConfiguration
    { feedTitle       = "Journal imaginaire de Raveline - RSS"
    , feedDescription = "Journal imaginaire"
    , feedAuthorName  = "Raveline"
    , feedAuthorEmail = "eraveline@gmail.com"
    , feedRoot        = "http://self.eraveline.eu"
    }

--------------------------------------------------------------------------------
-- Previous / next urls
postsGlob = "posts/*"

previousPostUrl :: Item String -> Compiler String
previousPostUrl post = do
    posts <- getMatches postsGlob
    let ident = itemIdentifier post
        sortedPosts = sortIdentifiersByDate posts
        ident' = itemBefore sortedPosts ident
    case ident' of
        Just i -> (fmap (maybe empty $ toUrl) . getRoute) i
        Nothing -> empty

nextPostUrl :: Item String -> Compiler String
nextPostUrl post = do
    posts <- getMatches postsGlob
    let ident = itemIdentifier post
        sortedPosts = sortIdentifiersByDate posts
        ident' = itemAfter sortedPosts ident
    case ident' of
        Just i -> (fmap (maybe empty $ toUrl) . getRoute) i
        Nothing -> empty

itemAfter :: Eq a => [a] -> a -> Maybe a
itemAfter xs x = lookup x $ zip xs (tail xs)

itemBefore :: Eq a => [a] -> a -> Maybe a
itemBefore xs x =
    lookup x $ zip (tail xs) xs

urlOfPost :: Item String -> Compiler String
urlOfPost = fmap (maybe empty $ toUrl) . getRoute . itemIdentifier

sortIdentifiersByDate :: [Identifier] -> [Identifier]
sortIdentifiersByDate identifiers =
    reverse $ sortBy byDate identifiers
        where
            byDate id1 id2 =
                let fn1 = takeFileName $ toFilePath id1
                    fn2 = takeFileName $ toFilePath id2
                    parseTime' fn = parseTime defaultTimeLocale "%Y-%m-%d" $ intercalate "-" $ take 3 $ splitAll "-" fn
                in compare ((parseTime' fn1) :: Maybe UTCTime) ((parseTime' fn2) :: Maybe UTCTime)
