-- | The subcommand registry. Each engine module owns its own @cli@.
module Ideonomy.Commands (commands, summaries) where

import qualified Ideonomy.Atlas as Atlas
import qualified Ideonomy.Canon as Canon
import qualified Ideonomy.Check as Check
import qualified Ideonomy.Climb as Climb
import qualified Ideonomy.Consult as Consult
import qualified Ideonomy.Demo as Demo
import qualified Ideonomy.Draw as Draw
import qualified Ideonomy.List as List
import qualified Ideonomy.Parley as Parley
import qualified Ideonomy.Registers as Registers
import qualified Ideonomy.Residue as Residue
import qualified Ideonomy.SeriateDrive as SeriateDrive
import qualified Ideonomy.Trial as Trial
import qualified Ideonomy.Triangulate as Triangulate
import qualified Ideonomy.Widen as Widen

commands :: [(String, [String] -> IO ())]
commands = [(n, run) | (n, _, run) <- table]

summaries :: [(String, String)]
summaries = [(n, d) | (n, d, _) <- table]

table :: [(String, String, [String] -> IO ())]
table =
  [ ("lists", "the persistent applicative list store", List.cli)
  , ("canon", "Gunkel's recovered lists, shipped as data", Canon.cli)
  , ("atlas", "build the offline catalog atlas (docs/catalog-map.html)", Atlas.cli)
  , ("check", "the typed gate a grown map record must pass", Check.cli)
  , ("consult", "the lists and maps a situation belongs to, as instruments", Consult.cli)
  , ("demo", "the respiratory engine over its own catalog, offline", Demo.cli)
  , ("draw", "forced non-default lenses: division x operator over a subject", Draw.cli)
  , ("residue", "the cross-session residue ledger", Residue.cli)
  , ("triangulate", "position a claim across many models without an oracle", Triangulate.cli)
  , ("parley", "a structured many-model debate to a labeled lean", Parley.cli)
  , ("trial", "adversarial trial of a claim: prosecutor, advocate, judge", Trial.cli)
  , ("registers", "48 mixable emotional registers; forced mixes for a task", Registers.cli)
  , ("climb", "grow the catalog one breath at a time (Gemini)", Climb.cli)
  , ("widen", "propose lists the catalog lacks, from the catalog (Gemini)", Widen.cli)
  , ("seriate", "embed, order, and score the catalog; build catalog-map.jsonl (Gemini)", SeriateDrive.cli)
  ]
