--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid                    ( mappend )
import           Hakyll
import Text.Pandoc.Definition
  ( Pandoc(..), Block(Header, Plain), Inline(Link, Space, Str), nullAttr )
import Text.Pandoc.Walk (walk)

import qualified Data.Set as S
import           Text.Pandoc.Options

extensions              = [ Ext_latex_macros, Ext_literate_haskell ]
mathExtensions          = [ Ext_tex_math_dollars, Ext_tex_math_double_backslash
                          , Ext_latex_macros ]
newWriterExtensions     = Prelude.foldr enableExtension writerDefaultExtensions (extensions ++ mathExtensions)
writerDefaultExtensions = writerExtensions defaultHakyllWriterOptions

latexWriterOptions = defaultHakyllWriterOptions {
                  writerExtensions     = newWriterExtensions
                , writerHTMLMathMethod = MathJax "https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"
                }


addSectionLinks :: Pandoc -> Pandoc
addSectionLinks = walk f where
  f (Header n attr@(idAttr, _, _) inlines) | n >= 1 =
    let newLinkText = (replicate n (Str "#")) ++ [Space] ++ inlines
        link = Link nullAttr (newLinkText) ("#" <> idAttr, "")
    in Header n attr [link]
  f x = x

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do

  match "images/*" $ do
    route idRoute
    compile copyFileCompiler

  match "css/*" $ do
    route idRoute
    compile compressCssCompiler

  match (fromList ["about.md", "contact.md", "projects.md"]) $ do
    route $ setExtension "html"
    compile
      $ pandocCompiler
      >>= loadAndApplyTemplate "templates/default.html" defaultContext
      >>= relativizeUrls

  match "posts/*" $ do
    route $ setExtension "html"
    compile
      $ pandocCompilerWithTransform defaultHakyllReaderOptions latexWriterOptions addSectionLinks
      >>= loadAndApplyTemplate "templates/post.html"    postCtx
      >>= loadAndApplyTemplate "templates/default.html" postCtx
      >>= relativizeUrls

  match "drafts/*" $ do
    route $ setExtension "html"
    compile
      $ pandocCompilerWithTransform defaultHakyllReaderOptions latexWriterOptions addSectionLinks
      >>= loadAndApplyTemplate "templates/post.html"    postCtx
      >>= loadAndApplyTemplate "templates/default.html" postCtx
      >>= relativizeUrls

  match "archived/*" $ do
    route $ setExtension "html"
    compile
      $ pandocCompilerWithTransform defaultHakyllReaderOptions latexWriterOptions addSectionLinks
      >>= loadAndApplyTemplate "templates/post.html"    postCtx
      >>= loadAndApplyTemplate "templates/default.html" postCtx
      >>= relativizeUrls


  create ["foobar/index.html"] $ do
    route idRoute
    compile $ makeItem (redirectHtml "https://raw.githubusercontent.com/DieracDelta/practice_materials/refs/heads/master/02_14_25/example_1.c")

  -- create ["archive.html"] $ do
  --   route idRoute
  --   compile $ do
  --     posts <- recentFirst =<< loadAll "posts/*"
  --     let archiveCtx =
  --           listField "posts" postCtx (return posts)
  --             `mappend` constField "title" "Archives"
  --             `mappend` defaultContext
  --
  --     makeItem ""
  --       >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
  --       >>= loadAndApplyTemplate "templates/default.html" archiveCtx
  --       >>= relativizeUrls


  match "index.html" $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/*"
      drafts <- recentFirst =<< loadAll "drafts/*"
      archived <- recentFirst =<< loadAll "archived/*"
      let indexCtx =
            (listField "posts" postCtx (return posts)) `mappend`
            (listField "drafts" postCtx (return drafts)) `mappend`
            (listField "archived" postCtx (return archived)) `mappend`
            defaultContext

      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= loadAndApplyTemplate "templates/default.html" indexCtx
        >>= relativizeUrls

  match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx = dateField "date" "%B %e, %Y" `mappend` defaultContext

redirectHtml :: String -> String
redirectHtml url = mconcat
    [ "<!DOCTYPE html>\n"
    , "<html>\n"
    -- , "<head>\n"
    -- , "  <meta charset=\"utf-8\">\n"
    -- , "  <meta http-equiv=\"refresh\" content=\"0; url=", url, "\">\n"
    -- , "  <link rel=\"canonical\" href=\"", url, "\">\n"
    -- , "</head>\n"
    , "<body>\n"
    , "ssh Xr2LZJqsXktPbe27bepsB2Ldv@nyc1.tmate.io OR https://tmate.io/t/Xr2LZJqsXktPbe27bepsB2Ldv"
    , "</body>\n"
    , "</html>\n"
    ]
