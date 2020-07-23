module Document.Body.Holes (fill) where

import Document.Body.Fills as Fills
import Tree as Tree
import Xml as Xml
import Tree.Zipper as Zipper
import Data.Maybe as Maybe
import Foreign.Object as FObject
import Data.Array as Array
import Prelude
import Data.Map as Map

isHole :: Xml.Element -> Boolean
isHole element = case element of
  Xml.Element { name, attributes } -> name == "hole"
  _ -> false

fill :: Fills.Fills -> Tree.Tree Xml.Element -> Tree.Tree Xml.Element
fill fills body = fill' (body # Zipper.fromTree) fills

fill' :: Zipper.Zipper Xml.Element -> Fills.Fills -> Tree.Tree Xml.Element
fill' zipper fills =
  let
    newZipper = case zipper # Zipper.label of
      Xml.Element { name, attributes } ->
        if name == "hole" then case attributes # FObject.lookup "id" of
          Maybe.Just id -> case fills # Map.lookup id of
            Maybe.Just fill_ -> case zipper # Zipper.parent of
              Maybe.Just parentZipper ->
                let
                  newChildren =
                    parentZipper # Zipper.children
                      # Array.foldl
                          ( \acc tree ->
                              if tree # Tree.label # isHole then
                                acc <> fill_
                              else
                                Array.snoc acc tree
                          )
                          []
                in
                  parentZipper # Zipper.replaceTree (Tree.tree (parentZipper # Zipper.label) newChildren)
              Maybe.Nothing -> zipper # Zipper.replaceTree (Tree.tree Xml.Root fill_)
            Maybe.Nothing -> zipper
          Maybe.Nothing -> zipper
        else
          if name == "fill" then
            zipper # Zipper.replaceTree (Tree.singleton Xml.Blank)
          else
            zipper
      _ -> zipper
  in
    case newZipper # Zipper.forward of
      Maybe.Nothing -> newZipper # Zipper.toTree
      Maybe.Just newZipper2 -> fill' newZipper2 fills