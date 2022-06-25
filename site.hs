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

  match (fromList ["about.md", "contact.md"]) $ do
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

  create ["archive.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/*"
      let archiveCtx =
            listField "posts" postCtx (return posts)
              `mappend` constField "title" "Archives"
              `mappend` defaultContext

      makeItem ""
        >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
        >>= loadAndApplyTemplate "templates/default.html" archiveCtx
        >>= relativizeUrls


  match "index.html" $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/*"
      let indexCtx =
            listField "posts" postCtx (return posts) `mappend` defaultContext

      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= loadAndApplyTemplate "templates/default.html" indexCtx
        >>= relativizeUrls

  match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx = dateField "date" "%B %e, %Y" `mappend` defaultContext
