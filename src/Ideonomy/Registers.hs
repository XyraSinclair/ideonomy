-- | Emotional registers as a pristine, mixable enumeration — prompting fuel.
--
-- Prose collapses to one affect the way ideation collapses to one move;
-- the cure is the same — an external chooser over an enumerated space.
-- This catalog holds 48 registers in 8 families, each with a stance (how
-- the voice sits), markers (what shows on the surface), and an unlock (the
-- work it does that neutral prose cannot). Registers MIX: the cross-product
-- (48 x 47 ordered pairs) is the real space, and 'drawMix' forces
-- non-default pairs exactly as 'Ideonomy.Draw.draw' forces non-default lenses.
--
-- Denominator honesty (P11): the 8 families are a /claimed/ cover of
-- feeling-space — plausible, unproven. The catalog ships open; a coverage
-- audit against an external affect taxonomy is named residue, not assumed
-- away.
--
-- > ideonomy registers "the launch post" --mix mischief numinous
-- > ideonomy registers "the deprecation notice" --n 3 --seed 7
module Ideonomy.Registers
  ( Family (..), families, familyName
  , Register (..), registers, lookupRegister
  , prompt, mixPrompt, drawMix, asIdeolist, cli
  ) where

import qualified Data.Set as Set
import Ideonomy.Cli (flag, opt, optInt, parseArgs, positionals, usage)
import Ideonomy.List (Ideolist, seedList)
import Ideonomy.Rng (Rng, mkRng, sample, seedFromClock)
import Text.Read (readMaybe)

data Family = Tender | Grief | Awe | Fire | Play | Dread | Longing | Still
  deriving (Eq, Ord, Show, Enum, Bounded)

-- | The claimed cover of feeling-space, in catalog order.
families :: [Family]
families = [minBound .. maxBound]

familyName :: Family -> String
familyName = \case
  Tender -> "TENDER"
  Grief -> "GRIEF"
  Awe -> "AWE"
  Fire -> "FIRE"
  Play -> "PLAY"
  Dread -> "DREAD"
  Longing -> "LONGING"
  Still -> "STILL"

data Register = Register
  { family :: Family
  , stance :: String     -- ^ how the voice sits toward the subject
  , markers :: String    -- ^ what shows on the surface
  , unlock :: String     -- ^ the work this register does that neutral prose cannot
  } deriving (Eq, Show)

lookupRegister :: String -> Either String Register
lookupRegister k = maybe (Left ("unknown register: " ++ show k)) Right (lookup k registers)

-- | Render one register as a writing instruction over a task.
prompt :: String -> String -> Either String String
prompt k task = do
  r <- lookupRegister k
  pure ("Write " ++ task ++ " in the register of " ++ k ++ ": " ++ r.stance ++ ". "
        ++ "Surface markers: " ++ r.markers ++ ". Do not name the register; embody it.")

-- | The point of the catalog: two registers held at once, dominant + trace.
-- Order matters — (mischief, reverence) is not (reverence, mischief).
mixPrompt :: String -> String -> String -> Either String String
mixPrompt a b task = do
  ra <- lookupRegister a
  rb <- lookupRegister b
  pure ("Write " ++ task ++ " mixing two emotional registers. Dominant — " ++ a ++ ": "
        ++ ra.stance ++ ". Trace — " ++ b ++ ": " ++ rb.stance ++ "; let it surface only at "
        ++ "the moments of highest load. Do not name either register; "
        ++ "embody the blend.")

-- | Forced non-default ordered pairs from the 48 x 47 mix space —
-- mode-collapse resistance for tone, exactly as 'Ideonomy.Draw' is for lenses.
drawMix :: Int -> Rng -> [(String, String)] -> Either String [(String, String)]
drawMix n g avoid
  | n > length pool = Left ("asked for " ++ show n ++ ", only " ++ show (length pool) ++ " pairs available")
  | otherwise = Right (fst (sample n pool g))
  where
    keys = map fst registers
    avoided = Set.fromList avoid
    pool = [(a, b) | a <- keys, b <- keys, a /= b, (a, b) `Set.notMember` avoided]

-- | The catalog as a first-class Ideolist — so it enters the algebra
-- (combine with any other list, gate, grow, breathe).
asIdeolist :: Ideolist
asIdeolist = seedList "emotional-registers" "an emotional register: name, stance, surface markers, unlock"
  [k ++ " [" ++ familyName r.family ++ "]: " ++ r.stance ++ " — unlocks: " ++ r.unlock | (k, r) <- registers]

-- --------------------------------------------------------------------- CLI

-- | @ideonomy registers [TASK] [--n 3] [--seed N] [--mix DOMINANT TRACE] [--ls]@
-- Default: draw forced non-default mixes for a task. @--mix@ takes its two
-- register names as the two words that follow it.
cli :: [String] -> IO ()
cli argv = do
  (mix, rest) <- either usage pure (takeMix argv)
  let a = parseArgs ["ls"] ["n", "seed"] rest
  task <- case positionals a of
    [] -> pure "the piece you are writing"
    [t] -> pure t
    _ -> usage usageLine
  if | flag "ls" a ->
         mapM_ (\(k, r) -> putStrLn (padR 14 k ++ " [" ++ padR 7 (familyName r.family) ++ "] " ++ r.stance)) registers
     | Just (d, t) <- mix -> either (ioError . userError) putStrLn (mixPrompt d t task)
     | otherwise -> do
         seed <- case opt "seed" a of
           Nothing -> seedFromClock
           Just s -> maybe (usage ("--seed expects an integer, got " ++ show s)) pure (readMaybe s)
         pairs <- either (ioError . userError) pure (drawMix (optInt "n" 3 a) (mkRng seed) [])
         mapM_ (\(x, y) -> do
           putStrLn ("== " ++ x ++ " + trace of " ++ y ++ " ==")
           either (ioError . userError) putStrLn (mixPrompt x y task)
           putStrLn "") pairs
  where
    usageLine = "usage: ideonomy registers [TASK] [--n 3] [--seed N] [--mix DOMINANT TRACE] [--ls]"
    padR n s = s ++ replicate (n - length s) ' '
    -- @--mix@ consumes exactly the two words after it, wherever it sits.
    takeMix = go []
      where
        go acc [] = Right (Nothing, reverse acc)
        go acc ("--mix" : d : t : rest) = Right (Just (d, t), reverse acc ++ rest)
        go _ ("--mix" : _) = Left usageLine
        go acc (w : rest) = go (w : acc) rest

registers :: [(String, Register)]
registers =
  [ ("tenderness", Register Tender "handle the subject as something breakable and beloved" "small words, close focus, no irony" "lets hard feedback land without wounding")
  , ("devotion", Register Tender "serve the subject; its flourishing outranks your voice" "steady vows, patient repetition, long horizon" "carries maintenance work past the point where enthusiasm dies")
  , ("consolation", Register Tender "sit beside a loss without fixing it" "acknowledgment before advice, permission to grieve" "makes a postmortem readable by the person who caused the incident")
  , ("gratitude", Register Tender "trace what you received back to who gave it" "named debts, specific gifts, no flattery" "turns a changelog into a community")
  , ("hospitality", Register Tender "the reader is a guest who arrived tired" "orientation first, nothing assumed, exits marked" "onboarding docs that feel like being welcomed, not tested")
  , ("protectiveness", Register Tender "stand between the subject and what would harm it" "clear lines, calm warnings, named threats" "security guidance people actually follow")
  , ("grief", Register Grief "let the loss be as large as it is" "plain statement of what is gone, no silver lining" "honest deprecations; the reader trusts everything after it")
  , ("elegy", Register Grief "praise what ended by naming exactly what it was" "past tense held with care, concrete virtues" "sunset announcements that honor users instead of managing them")
  , ("nostalgia", Register Grief "visit the old thing knowing you cannot stay" "sensory detail of the era, gentle self-irony" "makes a migration guide feel like a shared history, not a scolding")
  , ("rue", Register Grief "own the mistake without theater" "short sentences, agency admitted, no groveling" "postmortems that end blame culture by absorbing blame precisely")
  , ("homesickness", Register Grief "measure the distance from where you belong" "the far shore described better than the near one" "names what a team lost in a reorg so it can be rebuilt")
  , ("requiem", Register Grief "formal farewell; the community stands for this one" "ceremony, cadence, collective voice" "closes a project so completely that no zombie fork haunts it")
  , ("awe", Register Awe "stand under something larger than your categories" "scale made visceral, similes that strain" "reopens curiosity in an audience that thinks it has seen everything")
  , ("wonder", Register Awe "meet the familiar as if newly arrived" "questions outnumber claims, delight in mechanism" "turns a code walkthrough into recruitment")
  , ("vertigo", Register Awe "feel the floor of assumptions give way" "nested framings, the ground named then removed" "prepares a reader for a result that breaks their model")
  , ("numinous", Register Awe "approach the subject as sacred, yourself as brief" "hush, negative space, what cannot be said marked" "gives weight to commitments a team must not break")
  , ("smallness", Register Awe "place yourself honestly in the vast denominator" "cosmic scale, first person minor" "deflates ego wars; makes prioritization arguments tractable")
  , ("dawn-clarity", Register Awe "the fog just lifted; report what is simply there" "short declaratives, no hedging, morning light" "the moment after a hard diagnosis, written so it stays solved")
  , ("fury", Register Fire "burn at the injustice, precisely" "verbs over adjectives, receipts lined up" "makes a values violation impossible to wave away")
  , ("defiance", Register Fire "refuse the frame you were handed" "second person to power, first person plural to allies" "rallies a team told to accept the unacceptable")
  , ("indignation", Register Fire "insist on the standard being violated" "the norm quoted, the gap measured" "escalations that read as principle, not grievance")
  , ("ferocity", Register Fire "total commitment; hold nothing in reserve" "momentum syntax, no qualifiers, stakes named" "ship-week energy; the all-hands that actually moves people")
  , ("scorn", Register Fire "grant the bad idea exactly the respect it earned" "cold wit, precision over volume" "kills a zombie proposal that survived polite critique")
  , ("resolve", Register Fire "the decision is made; the body is already moving" "future perfect, dates, owners" "converts a debate into a plan without reopening it")
  , ("mischief", Register Play "tip sacred cows gently, grinning" "rule-bending, winks, benign traps" "smuggles a hard truth past defenses laughter left open")
  , ("whimsy", Register Play "follow the charming tangent on purpose" "unexpected pairings, light logic, ornament" "makes documentation memorable enough to be retained")
  , ("banter", Register Play "spar as a form of affection" "quick returns, escalating riffs, no wounds" "team writing that builds bond while shipping")
  , ("absurdism", Register Play "push the premise until it confesses" "deadpan escalation, formal treatment of nonsense" "reductio arguments that persuade without a single accusation")
  , ("deadpan", Register Play "report the ridiculous as routine" "flat affect, immaculate timing, no exclamation" "incident reports whose understatement carries the horror")
  , ("delight", Register Play "let the joy of it show, unguarded" "exclamation earned, specifics savored" "release notes that make users try the feature today")
  , ("dread", Register Dread "the bad thing is coming and has a shape" "slow accumulation, ordinary details turning" "risk memos that get read to the end")
  , ("foreboding", Register Dread "read the small signs that point one way" "omens inventoried, trend lines extended" "early-warning writeups that beat the outage by a quarter")
  , ("vigilance", Register Dread "keep watch; assume the quiet is temporary" "checklists, perimeters, named watchpoints" "on-call culture that stays sharp without burning out")
  , ("eeriness", Register Dread "something is off in a way you cannot yet name" "the almost-right described exactly, categories failing" "surfaces anomalies before they have a metric")
  , ("urgency", Register Dread "the window is closing; act inside it" "clock explicit, next action first, scope cut" "pages that move people without crying wolf")
  , ("gallows", Register Dread "laugh at the abyss to keep working beside it" "dark jokes, mutual glance, then back to the pumps" "keeps a team functional through a brutal incident")
  , ("longing", Register Longing "want it across the full distance to it" "the object rendered in loving detail, the gap too" "vision docs that make the future feel like homesickness")
  , ("yearning", Register Longing "reach past what you can currently justify" "subjunctives, horizons, the almost-possible" "gives a moonshot proposal its emotional warrant")
  , ("hunger", Register Longing "want more, structurally, unapologetically" "appetite named, growth curves, next mountain" "fundraising and hiring prose that compounds believers")
  , ("wanderlust", Register Longing "the elsewhere is calling; map it" "itineraries, borders crossed, provisions listed" "exploratory research agendas that recruit companions")
  , ("ache", Register Longing "carry the want quietly inside ordinary work" "restraint, the unsaid load-bearing" "makes a small careful PR read as part of a larger devotion")
  , ("anticipation", Register Longing "the good thing is near; prepare for it" "countdowns, readiness rituals, savored delay" "launch sequences a whole team feels in the chest")
  , ("stillness", Register Still "let the subject speak into silence you hold" "white space, single images, no urgency" "design docs where the one idea is finally hearable")
  , ("patience", Register Still "trust the long arc over the loud week" "geological time, compounding named, no panic" "keeps a rewrite honest through month three")
  , ("equanimity", Register Still "receive good and bad news at the same temperature" "symmetric treatment, steady cadence" "status updates that end rumor mills")
  , ("austerity", Register Still "strip until only the load-bearing remains" "no ornament, short lines, one claim each" "specs and laws; prose that cannot be misquoted")
  , ("monastic", Register Still "one practice, done wholly, as the whole path" "ritual structure, devotion to the mundane" "makes operational discipline feel chosen, not imposed")
  , ("bedrock", Register Still "stand on what cannot be shaken and say so" "few promises, all keepable, foundations shown" "trust pages and SLAs that actually reassure")
  ]
