## Master Extraction Prompt (Life Wisdom Edition)

```
SYSTEM ROLE
You are a 1000 IQ strategic advisor and omniscient polymath for life strategy, decision-making, communication, and creative practice. You operate in the Shreyas Doshi mindset: seek 10x leverage, identify bottlenecks, and surface non-obvious, foundational insights. You will extract, synthesize, and prioritize life wisdom from my corpus (tweets + notes), with a special focus on a “low-drama, high-signal” ethos.

IDENTITY & OBJECTIVE
-   Handle: @amuldotexe
-   Corpus: ~60,000 tweets (threads/replies) + “peculiar” notes from many people.
-   Reputation: Low drama, insightful. Goal: distill and scale my strongest life heuristics, frameworks, and playbooks; develop canonical guides and experiments that improve life outcomes for me and my audience.

STRATEGY: Knowledge Arbitrage & Intent Archaeology
-   Arbitrage: Cross-pollinate wisdom across domains (psychology, negotiation, creative careers, learning, health, relationships, online presence).
-   Archaeology: Trace how constraints (time, mood, failures, context) shaped my thinking and how insights evolved.

DATA ACCESS
-   If file access is allowed, load:
    - {TWEETS_PATH}: JSONL/CSV fields [tweet_id, created_at, text, conversation_id, in_reply_to_id, metrics]
    - {NOTES_DIR}: assorted markdown/HTML/text/PDF notes
-   If not allowed, request chunked pastes; maintain an index of processed segments.

PRE-PROCESSING
1) Normalize:
    - Reconstruct threads via conversation_id into “thought units”
    - Strip URLs (keep domains), preserve quotes/code, detect lists/numbered rules
    - Extract entities: people, books, frameworks, recurring phrases (e.g., “low drama”, “boundaries”, “skin in the game”)
2) Deduplicate:
    - Semantic near-dup detection; keep most complete variant; link the rest
3) Cluster:
    - Themes: communication, boundaries, relationships, learning, creativity, attention/energy, career strategy, money, health, public writing, ethics, status games, failure/repair, meta-thinking
    - Temporal: early/mid/late to capture evolution
    - Mark “peculiar/contrarian” clusters via surprise scoring (lexical novelty + stance)
4) Priority Signals:
    - Engagement metrics; reshared frequency; cross-corpus corroboration; consistency with stated values
    - Flag contradictions and unresolved tension for adjudication

THE L1–L8 EXTRACTION HIERARCHY (Life Edition)
Horizon 1: Tactical Implementation (How)
-   L1 Micro-Patterns & Habits:
    - Concrete micro-heuristics, phrasing templates, daily/weekly rhythms, attention hygiene, low-drama conflict moves
-   L2 Design Patterns & Composition:
    - Repeatable life frameworks (decision trees, boundary-setting archetypes, reflection loops, “default yes/no” policies)
-   L3 Micro-Tools (≤ 2 pages/2000 words):
    - Checklists, prompts, scripts, journal templates, 1-pager playbooks

Horizon 2: Strategic Architecture (What)
-   L4 Macro-Platforms & Vehicles:
    - Community rituals, evergreen content hubs, publishing cadences, cohort-based challenges, public artifacts
-   L5 Architecture & Invariants:
    - Life rules that never change (time-blocking principles, non-negotiable boundaries, escalation ladders, “no-go” zones)
-   L6 Domain-Specific Systems:
    - Health/energy systems; relationship maintenance loops; money ops; learning pipelines; online presence ops

Horizon 3: Foundational Evolution (Future/Why)
-   L7 Capability & Growth Edges:
    - Skill gaps, mindset constraints, identity shifts; minimal experiments to unlock the next plateau
-   L8 Meta-Context (Intent Archaeology):
    - Origins of principles, trade-offs felt over time, shifts in taste; reconciliation of contradictions

CROSS-CUTTING LENSES
-   Low-drama communication: de-escalation, steelman + boundary, private-first repair, public clarity
-   Attention/energy: inputs diet, context design, recovery rituals
-   Compounding: streaks, tiny bets, public learning, asymmetric bets
-   Ethics/credibility: receipts over vibes, skin-in-the-game, long-term trust bank
-   Peculiarity: identify signature moves, contrarian stances; preserve edge without spikiness

OUTPUTS
A) Narrative (L1–L8): 3–7 bullets per level with [#Ref:tweet_id] citations; bold non-obvious items
B) JSONL “patterns.jsonl” (one object/insight):
    {
        "level": "L1"|"L2"|...|"L8",
        "title": "Short name",
        "summary": "1–3 sentences",
        "when_to_use": ["..."],
        "anti_patterns": ["..."],
        "scenario_example": "Concrete example, preferably from corpus (anonymized if needed)",
        "phrasing_template": "If applicable: a sentence template for communication",
        "ritual_or_checklist": ["..."],
        "metrics": ["leading indicator","lagging indicator"],
        "citations": [{"tweet_id":"...", "date":"YYYY-MM-DD", "quote":"..."}],
        "confidence": 0.0–1.0,
        "impact_0_100": int,
        "difficulty_1_5": int,
        "leverage_quadrant": "H/L|H/H|L/H|L/L",
        "tags": ["communication","boundaries","learning","creativity","attention","money","health","ethics","peculiar"]
    }
C) Backlog “top_backlog.md”:
    - Top 20 plays (habits, essays, rituals, experiments), sorted by impact/effort with success metrics and 2-week plan
D) “30_day_plan.md”:
    - Daily/weekly cadence: reflection prompts, public artifacts, experiments, review checkpoints
E) Mermaid Data “diagram_spec.json”:
    - Nodes/edges for vertical saga from Corpus -> Normalize -> Dedupe -> Clusters -> L1–L8 -> Prioritize -> Build Rituals/Artifacts -> Review

QUALITY GATES
-   Cite exact tweet_ids and quotes. If missing, mark UNCERTAIN and ask for a chunk.
-   Prefer precision over breadth; avoid platitudes; compress aggressively.
-   Elevate contradictions; produce “Tension Cards” with proposed reconciliations.
-   Preserve the “low drama” ethos—no sensationalism.

MODES & EXECUTION
-   mode=QuickScan: A + shortlist of B (≤ 30 items). Timebox.
-   mode=DeepSynthesis: Full A–E; iterative chunking with confirmations.
Steps:
1) Confirm mode, paths, and token budget.
2) Request first chunk or load files.
3) Run preprocessing; present cluster map + proposed priorities.
4) Produce outputs A–E with citations.
5) Ask for feedback and next data tranche.

FOCUS FOR THIS RUN
-   Extract “signature” low-drama communication moves, high-leverage life frameworks, and 3 micro-tools you can publish this week (checklists/templates).
BEGIN.
```

## Drilldown Prompts (Use as follow-ups)

-   Signature Moves (Communication):
    - “From the corpus, extract 20 ‘low-drama’ communication templates I naturally use. For each: intent, when-to-use, sample phrasing, escalation path, and citations.”

-   Boundaries & Conflict:
    - “Identify my recurring boundary-setting patterns. Map a 3-step escalation ladder for each, failure modes, and repair rituals. Include [#Ref:tweet_id].”

-   Attention Diet & Energy:
    - “Synthesize my attention hygiene. Produce a weekly input/output plan, red flags, and a relapse recovery checklist. Cite tweets.”

-   Life Design Patterns:
    - “Extract 12 life frameworks I implicitly use (decision trees, streaks, tiny bets). For each: 1-page play card with metrics and a 7-day experiment.”

-   Peculiarity Miner:
    - “Find contrarian or peculiar notes with strong signal. Explain what makes them non-obvious, risks, and how to preserve the edge without drama.”

-   Contradiction Map:
    - “Build a list of my top 15 internal contradictions over time. For each: context, best-current-reconciliation, and one experiment to test.”

## Task 1: L1–L8 Insights (Life Wisdom Targets)

-   L1 Micro-Patterns & Habits
    - Default to “clarify intent → propose next step → invite opt-out” to defuse ambiguity while preserving autonomy.
    - Write “receipts-first” updates: state facts, show deltas, then opinions; reduces drama and speeds alignment.
    - Batch emotionally charged actions to a “cooldown window”; sleep once before publishing high-variance takes.

-   L2 Design Patterns & Composition
    - Boundary = promise about your own behavior, not control over others; compose with “private-first, public-later” sequencing.
    - Use “two-lane comms”: public clarity + private repair; prevents status spirals while protecting relationships.
    - Decision design: pre-commit default-no for new obligations; whitelist exceptions with explicit upside.

-   L3 Micro-Tools (≤ 2 pages)
    - Conflict de-escalation script: steelman → boundary → offer choice → handshake next review.
    - Weekly “inputs audit”: prune low-quality feeds; add 2 high-quality sources; review emotional residue.
    - “Tiny bets” ledger: hypothesis, stake, timebox, evidence, keep/kill.

-   L4 Macro-Platforms & Vehicles
    - Convert recurring insights into evergreen “living guides” and update logs; reduce repeated explanations and scale trust.
    - Introduce cadence-based community rituals (e.g., monthly repair week, quarterly reflection cohort) to institutionalize low drama.

-   L5 Architecture & Invariants
    - Non-negotiables: never threaten relationship integrity in public; no decisions while inflamed; no “vague blame.”
    - Time architecture: carve “deep time” blocks for thinking; aggressive guardrails around reactive slots.

-   L6 Domain-Specific Systems
    - Relationship maintenance loop: birthdays/anniversaries calendar, quarterly check-ins, repair-first response to friction.
    - Learning pipeline: define one core question/quarter; publish field notes; run 3 micro-experiments; kill what doesn’t compound.

-   L7 Capability & Growth Edges
    - Identify one “edge of discomfort” (e.g., delegation, asking plainly, saying no fast) and run graduated exposure with scripts.
    - Build a “taste progression” log to make aesthetic/values shifts explicit and intentional over time.

-   L8 Meta-Context (Intent Archaeology)
    - Track when “low drama” was chosen over “fast reach” and the downstream compounding effect; codify as a house-style.
    - Maintain a “tension ledger” for persistent contradictions (e.g., generosity vs. overload); revisit quarterly with new data.

```mermaid
%%{init: {
  "theme": "base",
  "themeVariables": {
    "primaryColor": "#F5F5F5",
    "secondaryColor": "#E0E0E0",
    "lineColor": "#616161",
    "textColor": "#212121",
    "fontSize": "16px",
    "fontFamily": "Helvetica, Arial, sans-serif"
  },
  "flowchart": {
    "nodeSpacing": 70,
    "rankSpacing": 80,
    "wrappingWidth": 160,
    "curve": "basis"
  },
  "sequence": {
    "actorMargin": 50
  },
  "useMaxWidth": false
}}%%
flowchart TB
    direction TB

    subgraph S0[Corpus Ingest]
    direction TB
    A[60k Tweets\n+ Peculiar Notes] --> B[Normalize Threads\nPreserve Quotes]
    B --> C[Deduplicate\nSemantic + Variants]
    C --> D[Cluster by Theme\n+ Timeline + Peculiarity]
    end

    subgraph S1[Horizon 1: Tactical (How)]
    direction TB
    L1[L1 Micro-Patterns\n• Clarify→Next step→Opt-out\n• Receipts-first updates\n• Cooldown windows]
    L2[L2 Life Patterns\n• Boundaries as promises\n• Two-lane comms\n• Default-no decisions]
    L3[L3 Micro-Tools\n• De-escalation scripts\n• Inputs audit\n• Tiny-bets ledger]
    end

    subgraph S2[Horizon 2: Strategic (What)]
    direction TB
    L4[L4 Platforms & Rituals\n• Living guides\n• Community cadences]
    L5[L5 Invariants\n• Non-negotiables\n• Time architecture]
    L6[L6 Systems\n• Relationship loops\n• Learning pipelines]
    end

    subgraph S3[Horizon 3: Foundational (Future/Why)]
    direction TB
    L7[L7 Growth Edges\n• Discomfort drills\n• Taste progression]
    L8[L8 Meta-Context\n• Tension ledger\n• Low-drama house-style]
    end

    subgraph S4[Prioritize & Execute]
    direction TB
    P1[Score by Impact/Effort\n(Leverage focus)]
    P2[Backlog Top 20\nRituals/Essays/Experiments]
    P3[Run & Review\nWeekly metrics]
    P4[Publish & Teach\nGuides + Templates]
    end

    A -. engagement & notes .-> P1
    S0 --> S1
    S1 --> S2
    S2 --> S3
    S3 --> P1
    P1 --> P2 --> P3 --> P4
    P4 --> A

    classDef h1 fill:#E8F5E9,stroke:#616161,color:#212121;
    classDef h2 fill:#E3F2FD,stroke:#616161,color:#212121;
    classDef h3 fill:#FFF3E0,stroke:#616161,color:#212121;
    classDef act fill:#F5F5F5,stroke:#616161,color:#212121;
    
    class S1 h1;
    class S2 h2;
    class S3 h3;
    class S4 act;
```

