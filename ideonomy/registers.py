"""Emotional registers as a pristine, mixable enumeration — prompting fuel.

Prose collapses to one affect the way ideation collapses to one move; the cure
is the same — an external chooser over an enumerated space. This catalog holds
48 registers in 8 families, each with a stance (how the voice sits), markers
(what shows on the surface), and an unlock (the work it does that neutral
prose cannot). Registers MIX: the cross-product (48 x 47 ordered pairs) is
the real space, and `draw_mix` forces non-default pairs exactly as `draw`
forces non-default lenses.

Denominator honesty (P-11): the 8 families are a *claimed* cover of
feeling-space — plausible, unproven. The catalog ships `open`; a coverage
audit against an external affect taxonomy is named residue, not assumed away.

    from ideonomy import registers
    registers.prompt("elegy", "the deprecation notice")
    registers.mix_prompt("mischief", "reverence", "the launch post")
    registers.draw_mix(3, seed=7)          # forced non-default pairs, offline
"""

from __future__ import annotations

import random
from dataclasses import dataclass
from typing import Optional, Sequence

FAMILIES = ("TENDER", "GRIEF", "AWE", "FIRE", "PLAY", "DREAD", "LONGING", "STILL")


@dataclass(frozen=True)
class Register:
    family: str
    stance: str     # how the voice sits toward the subject
    markers: str    # what shows on the surface
    unlock: str     # the work this register does that neutral prose cannot


REGISTERS: dict[str, Register] = {
    # ------------------------------------------------------------- TENDER
    "tenderness":   Register("TENDER", "handle the subject as something breakable and beloved", "small words, close focus, no irony", "lets hard feedback land without wounding"),
    "devotion":     Register("TENDER", "serve the subject; its flourishing outranks your voice", "steady vows, patient repetition, long horizon", "carries maintenance work past the point where enthusiasm dies"),
    "consolation":  Register("TENDER", "sit beside a loss without fixing it", "acknowledgment before advice, permission to grieve", "makes a postmortem readable by the person who caused the incident"),
    "gratitude":    Register("TENDER", "trace what you received back to who gave it", "named debts, specific gifts, no flattery", "turns a changelog into a community"),
    "hospitality":  Register("TENDER", "the reader is a guest who arrived tired", "orientation first, nothing assumed, exits marked", "onboarding docs that feel like being welcomed, not tested"),
    "protectiveness": Register("TENDER", "stand between the subject and what would harm it", "clear lines, calm warnings, named threats", "security guidance people actually follow"),
    # -------------------------------------------------------------- GRIEF
    "grief":        Register("GRIEF", "let the loss be as large as it is", "plain statement of what is gone, no silver lining", "honest deprecations; the reader trusts everything after it"),
    "elegy":        Register("GRIEF", "praise what ended by naming exactly what it was", "past tense held with care, concrete virtues", "sunset announcements that honor users instead of managing them"),
    "nostalgia":    Register("GRIEF", "visit the old thing knowing you cannot stay", "sensory detail of the era, gentle self-irony", "makes a migration guide feel like a shared history, not a scolding"),
    "rue":          Register("GRIEF", "own the mistake without theater", "short sentences, agency admitted, no groveling", "postmortems that end blame culture by absorbing blame precisely"),
    "homesickness": Register("GRIEF", "measure the distance from where you belong", "the far shore described better than the near one", "names what a team lost in a reorg so it can be rebuilt"),
    "requiem":      Register("GRIEF", "formal farewell; the community stands for this one", "ceremony, cadence, collective voice", "closes a project so completely that no zombie fork haunts it"),
    # ---------------------------------------------------------------- AWE
    "awe":          Register("AWE", "stand under something larger than your categories", "scale made visceral, similes that strain", "reopens curiosity in an audience that thinks it has seen everything"),
    "wonder":       Register("AWE", "meet the familiar as if newly arrived", "questions outnumber claims, delight in mechanism", "turns a code walkthrough into recruitment"),
    "vertigo":      Register("AWE", "feel the floor of assumptions give way", "nested framings, the ground named then removed", "prepares a reader for a result that breaks their model"),
    "numinous":     Register("AWE", "approach the subject as sacred, yourself as brief", "hush, negative space, what cannot be said marked", "gives weight to commitments a team must not break"),
    "smallness":    Register("AWE", "place yourself honestly in the vast denominator", "cosmic scale, first person minor", "deflates ego wars; makes prioritization arguments tractable"),
    "dawn-clarity": Register("AWE", "the fog just lifted; report what is simply there", "short declaratives, no hedging, morning light", "the moment after a hard diagnosis, written so it stays solved"),
    # --------------------------------------------------------------- FIRE
    "fury":         Register("FIRE", "burn at the injustice, precisely", "verbs over adjectives, receipts lined up", "makes a values violation impossible to wave away"),
    "defiance":     Register("FIRE", "refuse the frame you were handed", "second person to power, first person plural to allies", "rallies a team told to accept the unacceptable"),
    "indignation":  Register("FIRE", "insist on the standard being violated", "the norm quoted, the gap measured", "escalations that read as principle, not grievance"),
    "ferocity":     Register("FIRE", "total commitment; hold nothing in reserve", "momentum syntax, no qualifiers, stakes named", "ship-week energy; the all-hands that actually moves people"),
    "scorn":        Register("FIRE", "grant the bad idea exactly the respect it earned", "cold wit, precision over volume", "kills a zombie proposal that survived polite critique"),
    "resolve":      Register("FIRE", "the decision is made; the body is already moving", "future perfect, dates, owners", "converts a debate into a plan without reopening it"),
    # --------------------------------------------------------------- PLAY
    "mischief":     Register("PLAY", "tip sacred cows gently, grinning", "rule-bending, winks, benign traps", "smuggles a hard truth past defenses laughter left open"),
    "whimsy":       Register("PLAY", "follow the charming tangent on purpose", "unexpected pairings, light logic, ornament", "makes documentation memorable enough to be retained"),
    "banter":       Register("PLAY", "spar as a form of affection", "quick returns, escalating riffs, no wounds", "team writing that builds bond while shipping"),
    "absurdism":    Register("PLAY", "push the premise until it confesses", "deadpan escalation, formal treatment of nonsense", "reductio arguments that persuade without a single accusation"),
    "deadpan":      Register("PLAY", "report the ridiculous as routine", "flat affect, immaculate timing, no exclamation", "incident reports whose understatement carries the horror"),
    "delight":      Register("PLAY", "let the joy of it show, unguarded", "exclamation earned, specifics savored", "release notes that make users try the feature today"),
    # -------------------------------------------------------------- DREAD
    "dread":        Register("DREAD", "the bad thing is coming and has a shape", "slow accumulation, ordinary details turning", "risk memos that get read to the end"),
    "foreboding":   Register("DREAD", "read the small signs that point one way", "omens inventoried, trend lines extended", "early-warning writeups that beat the outage by a quarter"),
    "vigilance":    Register("DREAD", "keep watch; assume the quiet is temporary", "checklists, perimeters, named watchpoints", "on-call culture that stays sharp without burning out"),
    "eeriness":     Register("DREAD", "something is off in a way you cannot yet name", "the almost-right described exactly, categories failing", "surfaces anomalies before they have a metric"),
    "urgency":      Register("DREAD", "the window is closing; act inside it", "clock explicit, next action first, scope cut", "pages that move people without crying wolf"),
    "gallows":      Register("DREAD", "laugh at the abyss to keep working beside it", "dark jokes, mutual glance, then back to the pumps", "keeps a team functional through a brutal incident"),
    # ------------------------------------------------------------ LONGING
    "longing":      Register("LONGING", "want it across the full distance to it", "the object rendered in loving detail, the gap too", "vision docs that make the future feel like homesickness"),
    "yearning":     Register("LONGING", "reach past what you can currently justify", "subjunctives, horizons, the almost-possible", "gives a moonshot proposal its emotional warrant"),
    "hunger":       Register("LONGING", "want more, structurally, unapologetically", "appetite named, growth curves, next mountain", "fundraising and hiring prose that compounds believers"),
    "wanderlust":   Register("LONGING", "the elsewhere is calling; map it", "itineraries, borders crossed, provisions listed", "exploratory research agendas that recruit companions"),
    "ache":         Register("LONGING", "carry the want quietly inside ordinary work", "restraint, the unsaid load-bearing", "makes a small careful PR read as part of a larger devotion"),
    "anticipation": Register("LONGING", "the good thing is near; prepare for it", "countdowns, readiness rituals, savored delay", "launch sequences a whole team feels in the chest"),
    # -------------------------------------------------------------- STILL
    "stillness":    Register("STILL", "let the subject speak into silence you hold", "white space, single images, no urgency", "design docs where the one idea is finally hearable"),
    "patience":     Register("STILL", "trust the long arc over the loud week", "geological time, compounding named, no panic", "keeps a rewrite honest through month three"),
    "equanimity":   Register("STILL", "receive good and bad news at the same temperature", "symmetric treatment, steady cadence", "status updates that end rumor mills"),
    "austerity":    Register("STILL", "strip until only the load-bearing remains", "no ornament, short lines, one claim each", "specs and laws; prose that cannot be misquoted"),
    "monastic":     Register("STILL", "one practice, done wholly, as the whole path", "ritual structure, devotion to the mundane", "makes operational discipline feel chosen, not imposed"),
    "bedrock":      Register("STILL", "stand on what cannot be shaken and say so", "few promises, all keepable, foundations shown", "trust pages and SLAs that actually reassure"),
}


def prompt(key: str, task: str) -> str:
    """Render one register as a writing instruction over a task."""
    r = REGISTERS[key]
    return (f"Write {task} in the register of {key}: {r.stance}. "
            f"Surface markers: {r.markers}. Do not name the register; embody it.")


def mix_prompt(a: str, b: str, task: str) -> str:
    """The point of the catalog: two registers held at once, dominant + trace.
    Order matters — (mischief, reverence) is not (reverence, mischief)."""
    ra, rb = REGISTERS[a], REGISTERS[b]
    return (f"Write {task} mixing two emotional registers. Dominant — {a}: "
            f"{ra.stance}. Trace — {b}: {rb.stance}; let it surface only at "
            f"the moments of highest load. Do not name either register; "
            f"embody the blend.")


def draw_mix(n: int = 3, seed: Optional[int] = None,
             avoid: Sequence[tuple] = ()) -> list:
    """Forced non-default ordered pairs from the 48 x 47 mix space —
    mode-collapse resistance for tone, exactly as draw.py is for lenses."""
    keys = list(REGISTERS)
    pool = [(a, b) for a in keys for b in keys if a != b]
    pool = [p for p in pool if p not in set(avoid)]
    if n > len(pool):
        raise ValueError(f"asked for {n}, only {len(pool)} pairs available")
    return random.Random(seed).sample(pool, n)


def as_ideolist():
    """The catalog as a first-class Ideolist — so it enters the algebra
    (combine with any other list, gate, grow, breathe)."""
    from .lists import Ideolist
    return Ideolist(
        name="emotional-registers",
        of="an emotional register: name, stance, surface markers, unlock",
        items=[f"{k} [{r.family}]: {r.stance} — unlocks: {r.unlock}"
               for k, r in REGISTERS.items()],
        made_by="seed")


def main(argv: Optional[list] = None) -> int:
    import argparse
    ap = argparse.ArgumentParser(
        prog="ideonomy.registers",
        description="48 mixable emotional registers. Default: draw forced "
                    "non-default mixes for a task.")
    ap.add_argument("task", nargs="?", default="the piece you are writing")
    ap.add_argument("--n", type=int, default=3)
    ap.add_argument("--seed", type=int)
    ap.add_argument("--mix", nargs=2, metavar=("DOMINANT", "TRACE"),
                    help="render one specific mix instead of drawing")
    ap.add_argument("--ls", action="store_true", help="list the catalog")
    args = ap.parse_args(argv)
    if args.ls:
        for k, r in REGISTERS.items():
            print(f"{k:14} [{r.family:7}] {r.stance}")
        return 0
    if args.mix:
        print(mix_prompt(args.mix[0], args.mix[1], args.task))
        return 0
    for a, b in draw_mix(args.n, seed=args.seed):
        print(f"== {a} + trace of {b} ==")
        print(mix_prompt(a, b, args.task))
        print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
