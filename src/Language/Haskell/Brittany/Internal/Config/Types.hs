{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE DeriveDataTypeable #-}

module Language.Haskell.Brittany.Internal.Config.Types
  ( module Language.Haskell.Brittany.Internal.Config.Types
  , cMap
  )
where



#include "prelude.inc"

import Data.Yaml
import qualified Data.Aeson.Types as Aeson
import GHC.Generics

import Data.Data ( Data )

import Data.Coerce ( Coercible, coerce )

import Data.Semigroup.Generic
import Data.Semigroup ( Last, Option )

import Data.CZipWith



confUnpack :: Coercible a b => Identity a -> b
confUnpack (Identity x) = coerce x

data CDebugConfig f = DebugConfig
  { _dconf_dump_config                :: f (Semigroup.Last Bool)
  , _dconf_dump_annotations           :: f (Semigroup.Last Bool)
  , _dconf_dump_ast_unknown           :: f (Semigroup.Last Bool)
  , _dconf_dump_ast_full              :: f (Semigroup.Last Bool)
  , _dconf_dump_bridoc_raw            :: f (Semigroup.Last Bool)
  , _dconf_dump_bridoc_simpl_alt      :: f (Semigroup.Last Bool)
  , _dconf_dump_bridoc_simpl_floating :: f (Semigroup.Last Bool)
  , _dconf_dump_bridoc_simpl_par      :: f (Semigroup.Last Bool)
  , _dconf_dump_bridoc_simpl_columns  :: f (Semigroup.Last Bool)
  , _dconf_dump_bridoc_simpl_indent   :: f (Semigroup.Last Bool)
  , _dconf_dump_bridoc_final          :: f (Semigroup.Last Bool)
  , _dconf_roundtrip_exactprint_only  :: f (Semigroup.Last Bool)
  }
  deriving (Generic)

data CLayoutConfig f = LayoutConfig
  { _lconfig_cols         :: f (Last Int) -- the thing that has default 80.
  , _lconfig_indentPolicy :: f (Last IndentPolicy)
  , _lconfig_indentAmount :: f (Last Int)
  , _lconfig_indentWhereSpecial :: f (Last Bool) -- indent where only 1 sometimes (TODO).
  , _lconfig_indentListSpecial  :: f (Last Bool) -- use some special indentation for ","
                                                 -- when creating zero-indentation
                                                 -- multi-line list literals.
  , _lconfig_importColumn    :: f (Last Int)
    -- ^ for import statement layouting, column at which to align the
    -- elements to be imported from a module.
    -- It is expected that importAsColumn >= importCol.
  , _lconfig_importAsColumn  :: f (Last Int)
    -- ^ for import statement layouting, column at which put the module's
    -- "as" name (which also affects the positioning of the "as" keyword).
    -- It is expected that importAsColumn >= importCol.
  , _lconfig_altChooser      :: f (Last AltChooser)
  , _lconfig_columnAlignMode :: f (Last ColumnAlignMode)
  , _lconfig_alignmentLimit  :: f (Last Int)
    -- roughly speaking, this sets an upper bound to the number of spaces
    -- inserted to create horizontal alignment.
    -- More specifically, if 'xs' are the widths of the columns in some
    -- alignment-block, then the block will be aligned with the width
    -- maximum [ x | x <- xs, x < minimum xs + alignmentLimit ].
  , _lconfig_alignmentBreakOnMultiline :: f (Last Bool)
    -- stops alignment between items that are not layouted as a single line.
    -- e.g. for single-line alignment, things remain unchanged:
    --   do
    --     short       <- stuff
    --     loooooooong <- stuff
    -- but not in cases such as:
    --   do
    --     short <- some more stuff
    --       that requires two lines
    --     loooooooong <- stuff
  , _lconfig_hangingTypeSignature :: f (Last Bool)
    -- Do not put "::" in a new line, and use hanging indentation for the
    -- signature, i.e.:
    -- func :: SomeLongStuff
    --      -> SomeLongStuff
    -- instead of the usual
    -- func
    --   :: SomeLongStuff
    --   -> SomeLongStuff
    -- As usual for hanging indentation, the result will be
    -- context-sensitive (in the function name).
  , _lconfig_reformatModulePreamble :: f (Last Bool)
    -- whether the module preamble/header (module keyword, name, export list,
    -- import statements) are reformatted. If false, only the elements of the
    -- module (everything past the "where") are reformatted.
  , _lconfig_allowSingleLineExportList :: f (Last Bool)
    -- if true, and it fits in a single line, and there are no comments in the
    -- export list, the following layout will be used:
    -- > module MyModule (abc, def) where
    -- > [stuff]
    -- otherwise, the multi-line version is used:
    -- > module MyModule
    -- >   ( abc
    -- >   , def
    -- >   )
    -- > where
  , _lconfig_allowHangingQuasiQuotes :: f (Last Bool)
    -- if false, the layouter sees any splices as infinitely big and places
    -- them accordingly (in newlines, most likely); This also influences
    -- parent nodes.
    -- if true, the layouter is free to start a quasi-quotation at the end
    -- of a line.
    --
    -- false:
    -- > let
    -- >   body =
    -- >     [json|
    -- >     hello
    -- >     |]
    --
    -- true:
    -- > let body = [json|
    -- >     hello
    -- >     |]
  }
  deriving (Generic)

data CForwardOptions f = ForwardOptions
  { _options_ghc :: f [String]
  }
  deriving (Generic)

data CErrorHandlingConfig f = ErrorHandlingConfig
  { _econf_produceOutputOnErrors   :: f (Semigroup.Last Bool)
  , _econf_Werror                  :: f (Semigroup.Last Bool)
  , _econf_ExactPrintFallback      :: f (Semigroup.Last ExactPrintFallbackMode)
    -- ^ Determines when to fall back on the exactprint'ed output when
    -- syntactical constructs are encountered which are not yet handled by
    -- brittany.
    -- Note that the "risky" setting is risky because even with the check of
    -- the syntactic validity of the brittany output, at least in theory there
    -- may be cases where the output is syntactically/semantically valid but
    -- has different semantics than the code pre-transformation.
  , _econf_omit_output_valid_check :: f (Semigroup.Last Bool)
  }
  deriving (Generic)

data CPreProcessorConfig f = PreProcessorConfig
  { _ppconf_CPPMode :: f (Semigroup.Last CPPMode)
  , _ppconf_hackAroundIncludes :: f (Semigroup.Last Bool)
  }
  deriving (Generic)

data CConfig f = Config
  { _conf_version       :: f (Semigroup.Last Int)
  , _conf_debug         :: CDebugConfig f
  , _conf_layout        :: CLayoutConfig f
  , _conf_errorHandling :: CErrorHandlingConfig f
  , _conf_forward       :: CForwardOptions f
  , _conf_preprocessor  :: CPreProcessorConfig f
  , _conf_roundtrip_exactprint_only :: f (Semigroup.Last Bool)
  , _conf_obfuscate     :: f (Semigroup.Last Bool)
    -- ^ this field is somewhat of a duplicate of the one in DebugConfig.
    -- It is used for per-declaration disabling by the inline config
    -- implementation. Could have re-used the existing field, but felt risky
    -- to use a "debug" labeled field for non-debug functionality.
  }
  deriving (Generic)

type DebugConfig = CDebugConfig Identity
type LayoutConfig = CLayoutConfig Identity
type ForwardOptions = CForwardOptions Identity
type ErrorHandlingConfig = CErrorHandlingConfig Identity
type Config = CConfig Identity

-- i wonder if any Show1 stuff could be leveraged.
deriving instance Show (CDebugConfig Identity)
deriving instance Show (CLayoutConfig Identity)
deriving instance Show (CErrorHandlingConfig Identity)
deriving instance Show (CForwardOptions Identity)
deriving instance Show (CPreProcessorConfig Identity)
deriving instance Show (CConfig Identity)

deriving instance Show (CDebugConfig Option)
deriving instance Show (CLayoutConfig Option)
deriving instance Show (CErrorHandlingConfig Option)
deriving instance Show (CForwardOptions Option)
deriving instance Show (CPreProcessorConfig Option)
deriving instance Show (CConfig Option)

deriving instance Data (CDebugConfig Identity)
deriving instance Data (CLayoutConfig Identity)
deriving instance Data (CErrorHandlingConfig Identity)
deriving instance Data (CForwardOptions Identity)
deriving instance Data (CPreProcessorConfig Identity)
deriving instance Data (CConfig Identity)

#if MIN_VERSION_ghc(8,2,0)
-- these instances break on earlier ghcs
deriving instance Data (CDebugConfig Option)
deriving instance Data (CLayoutConfig Option)
deriving instance Data (CErrorHandlingConfig Option)
deriving instance Data (CForwardOptions Option)
deriving instance Data (CPreProcessorConfig Option)
deriving instance Data (CConfig Option)
#endif

instance Semigroup.Semigroup (CDebugConfig Option) where
  (<>) = gmappend
instance Semigroup.Semigroup (CLayoutConfig Option) where
  (<>) = gmappend
instance Semigroup.Semigroup (CErrorHandlingConfig Option) where
  (<>) = gmappend
instance Semigroup.Semigroup (CForwardOptions Option) where
  (<>) = gmappend
instance Semigroup.Semigroup (CPreProcessorConfig Option) where
  (<>) = gmappend
instance Semigroup.Semigroup (CConfig Option) where
  (<>) = gmappend

instance Semigroup.Semigroup (CDebugConfig Identity) where
  (<>) = gmappend
instance Semigroup.Semigroup (CLayoutConfig Identity) where
  (<>) = gmappend
instance Semigroup.Semigroup (CErrorHandlingConfig Identity) where
  (<>) = gmappend
instance Semigroup.Semigroup (CForwardOptions Identity) where
  (<>) = gmappend
instance Semigroup.Semigroup (CPreProcessorConfig Identity) where
  (<>) = gmappend
instance Semigroup.Semigroup (CConfig Identity) where
  (<>) = gmappend

instance Monoid (CDebugConfig Option) where
  mempty = gmempty
  mappend = gmappend
instance Monoid (CLayoutConfig Option) where
  mempty = gmempty
  mappend = gmappend
instance Monoid (CErrorHandlingConfig Option) where
  mempty = gmempty
  mappend = gmappend
instance Monoid (CForwardOptions Option) where
  mempty = gmempty
  mappend = gmappend
instance Monoid (CPreProcessorConfig Option) where
  mempty = gmempty
  mappend = gmappend
instance Monoid (CConfig Option) where
  mempty = gmempty
  mappend = gmappend


data IndentPolicy = IndentPolicyLeft -- never create a new indentation at more
                                     -- than old indentation + amount
                  | IndentPolicyFree -- can create new indentations whereever
                  | IndentPolicyMultiple -- can create indentations only
                                         -- at any n * amount.
  deriving (Eq, Show, Generic, Data)

data AltChooser = AltChooserSimpleQuick -- always choose last alternative.
                                        -- leads to tons of sparsely filled
                                        -- lines.
                | AltChooserShallowBest -- choose the first matching alternative
                                        -- using the simplest spacing
                                        -- information for the children.
                | AltChooserBoundedSearch Int
                                        -- choose the first matching alternative
                                        -- using a bounded list of recursive
                                        -- options having sufficient space.
  deriving (Show, Generic, Data)

data ColumnAlignMode
  = ColumnAlignModeDisabled
    -- ^ Make no column alignments whatsoever
  | ColumnAlignModeUnanimously
    -- ^ Make column alignments only if it does not cause overflow for any of
    -- the affected lines.
  | ColumnAlignModeMajority Float
    -- ^ If at least (ratio::Float) of the aligned elements have sufficient
    -- space for the alignment, act like ColumnAlignModeAnimously; otherwise
    -- act like ColumnAlignModeDisabled.
  | ColumnAlignModeAnimouslyScale Int
    -- ^ Scale back columns to some degree if their sum leads to overflow.
    -- This is done in a linear fashion.
    -- The Int specifies additional columns to be added to column maximum for
    -- scaling calculation purposes.
  | ColumnAlignModeAnimously
    -- ^ Decide on a case-by-case basis if alignment would cause overflow.
    -- If it does, cancel all alignments for this (nested) column description.
  -- ColumnAlignModeAnimouslySome -- potentially to implement
  | ColumnAlignModeAlways
    -- ^ Always respect column alignments, even if it makes stuff overflow.
  deriving (Show, Generic, Data)

data CPPMode = CPPModeAbort  -- abort program on seeing -XCPP
             | CPPModeWarn   -- warn about CPP and non-roundtripping in its
                             -- presence.
             | CPPModeNowarn -- silently allow CPP, if possible (i.e. input is
                             -- file.)
  deriving (Show, Generic, Data)

data ExactPrintFallbackMode
  = ExactPrintFallbackModeNever  -- never fall back on exactprinting
  | ExactPrintFallbackModeInline -- fall back only if there are no newlines in
                                 -- the exactprint'ed output.
  | ExactPrintFallbackModeRisky  -- fall back even in the presence of newlines.
                                 -- THIS MAY THEORETICALLY CHANGE SEMANTICS OF
                                 -- A PROGRAM BY TRANSFORMING IT.
  deriving (Show, Generic, Data)

instance CFunctor CDebugConfig
instance CFunctor CLayoutConfig
instance CFunctor CErrorHandlingConfig
instance CFunctor CForwardOptions
instance CFunctor CPreProcessorConfig
instance CFunctor CConfig

-- deriveCZipWith ''CDebugConfig
-- deriveCZipWith ''CLayoutConfig
-- deriveCZipWith ''CErrorHandlingConfig
-- deriveCZipWith ''CForwardOptions
-- deriveCZipWith ''CPreProcessorConfig
-- deriveCZipWith ''CConfig


instance CZipWith CDebugConfig where
      cZipWith
        f
        (DebugConfig x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12)
        (DebugConfig y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12)
        = (((((((((((DebugConfig ((f x1) y1)) ((f x2) y2)) ((f x3) y3))
                    ((f x4) y4))
                   ((f x5) y5))
                  ((f x6) y6))
                 ((f x7) y7))
                ((f x8) y8))
               ((f x9) y9))
              ((f x10) y10))
             ((f x11) y11))
            ((f x12) y12)

instance CZipWith CLayoutConfig where
      cZipWith
        f
        (LayoutConfig x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15)
        (LayoutConfig y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15)
        = ((((((((((((((LayoutConfig ((f x1) y1)) ((f x2) y2)) ((f x3) y3))
                       ((f x4) y4))
                      ((f x5) y5))
                     ((f x6) y6))
                    ((f x7) y7))
                   ((f x8) y8))
                  ((f x9) y9))
                 ((f x10) y10))
                ((f x11) y11))
               ((f x12) y12))
              ((f x13) y13))
             ((f x14) y14))
            ((f x15) y15)

instance CZipWith CErrorHandlingConfig where
      cZipWith
        f
        (ErrorHandlingConfig x1 x2 x3 x4)
        (ErrorHandlingConfig y1 y2 y3 y4)
        = (((ErrorHandlingConfig ((f x1) y1)) ((f x2) y2)) ((f x3) y3))
            ((f x4) y4)

instance CZipWith CForwardOptions where
      cZipWith f (ForwardOptions x1) (ForwardOptions y1)
        = ForwardOptions ((f x1) y1)

instance CZipWith CPreProcessorConfig where
      cZipWith f (PreProcessorConfig x1 x2) (PreProcessorConfig y1 y2)
        = (PreProcessorConfig ((f x1) y1)) ((f x2) y2)

instance CZipWith CConfig where
      cZipWith
        f
        (Config x1 x2 x3 x4 x5 x6 x7 x8)
        (Config y1 y2 y3 y4 y5 y6 y7 y8)
        = (((((((Config ((f x1) y1)) (((cZipWith f) x2) y2))
                 (((cZipWith f) x3) y3))
                (((cZipWith f) x4) y4))
               (((cZipWith f) x5) y5))
              (((cZipWith f) x6) y6))
             ((f x7) y7))
            ((f x8) y8)

