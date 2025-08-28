# Summarization Method — Minto Pyramid + Chunked Streaming

This document describes the exact method used to turn very large notes into one cohesive, high‑quality Minto Pyramid summary table, while reading the source in manageable terminal chunks.

## Goals

- Bold: Single cohesive output: a master table (no per‑chunk notes)
- Bold: Minto structure: clear answer, MECE pillars, evidence patterns
- Bold: Scalability: process arbitrarily long files safely and repeatably
- Bold: Reusability: same method works for future notes files

## Input Constraints

- Bold: Chunk size: read 250 lines per iteration (CLI output cap). Do not run large-range filtered scans as a substitute; always advance in fixed 250-line windows.
- Bold: No network: rely solely on local file contents
- Bold: Large files: iterate until EOF; maintain state in memory/editor

## High‑Level Approach

- Bold: Stream: read file in 250‑line windows from start to end (strict)
- Bold: Extract: identify candidate concepts (patterns, strategies, techs)
- Bold: Synthesize: map into Minto table columns with MECE coverage
- Bold: Deduplicate: normalize names; merge synonyms; avoid repeats
- Bold: Enrich: add concise metrics, pitfalls, and search keywords
- Bold: Cohere: present as a single master table (no chunk references)

## Detailed Workflow

- Bold: 1) Initialize: create an empty master table with fixed columns
- Bold: 2) Scan: for window N..N+249, parse text and collect candidates
- Bold: 3) Normalize: canonicalize names (lowercase key; trim; unify hyphens)
- Bold: 4) Classify: assign Level/Category (Answer, Pillar, Pattern, etc.)
- Bold: 5) Reduce: one‑line, action‑oriented cells; avoid verbosity
- Bold: 6) Merge: if item exists, enrich cells (When, Pitfalls, Metrics)
- Bold: 7) Keywords: add high‑signal terms; dedupe; keep short, specific
- Bold: 8) Commit: update the table without chunk labels; track coverage

## Extraction Heuristics

- Bold: JSON‑ish cues: keys like `pattern_name`, `strategy_name`, `technique_name`, `field`, `title`
- Bold: Lexical cues: lines mentioning “pattern”, “anti‑pattern”, “consistency”, “replication”, “caching”, “CQRS”, “Saga”, “API Gateway”, “BFF”, etc.
- Bold: Support fields: “description”, “use_case(s)”, “pros_and_cons”, “challenges”, “metrics”
- Bold: Domain buckets: Architecture, Data, Distributed Systems, Reliability, Delivery/Ops, Security, Decision, Anti‑Patterns, Platforms

## Table Schema (columns)

- Bold: Level: Answer | Pillar | Pattern | Data Store | Streams | Decision | Migration | Security | Anti‑Patterns | Reference
- Bold: Category: Thematic bucket (e.g., Architecture, Data, Reliability)
- Bold: Item: Canonical name (e.g., Circuit Breaker, CQRS)
- Bold: Core Idea: One clear principle statement
- Bold: When to Use: Triggers/contexts where it fits
- Bold: Pitfalls / Anti‑Patterns: Common mistakes to avoid
- Bold: Metrics / Signals: How to know it’s working/regressing
- Bold: Keywords: Short, high‑signal tags for search/LLM retrieval

## Synthesis Rules

- Bold: MECE: ensure pillars cover content without overlap
- Bold: One‑liners: write concise, active‑voice, single‑line cells
- Bold: No chunk labels: final artifact never mentions chunks
- Bold: Merge synonyms: e.g., “Write‑Back” ≈ “Write‑Behind”; “Saga Pattern” ≈ “Saga”
- Bold: Prefer principles: lead with “what it is” then “when to use”
- Bold: Add metrics: choose observable, practical indicators (e.g., p95 latency, error budget burn)
- Bold: Anti‑patterns: include remediation intent in Pitfalls

## Keyword Curation

- Bold: Signal: prefer canonical, specific terms over generic buzzwords
- Bold: Dedupe: lowercase/trim; collapse variants; keep a short list
- Bold: Purpose: enable fast LLM retrieval and future cross‑reference

## Quality Gates

- Bold: Coverage: track processed line range (e.g., “1–N processed”). Only bump coverage after actually completing all 250‑line windows up to N.
- Bold: Remediation: if any non-windowed scan was used, re-process that range in 250‑line windows before updating coverage.
- Bold: Consistency: consistent tone, schema, and taxonomy
- Bold: Uniqueness: do not add near‑duplicates; enrich existing rows
- Bold: Relevance: table items must map to actual source content

## Operational Commands (local only)

- Bold: Count lines: `wc -l path/to/file.txt`
- Bold: Read window: `sed -n 'START,ENDp' path/to/file.txt`
- Bold: Grep patterns: `rg -n -o -P '"(pattern_name|strategy_name|technique_name)"\s*:\s*"[^"]+' file`
- Bold: Append/update: maintain table in a single Markdown; avoid chunk notes

## Example Mapping

- Bold: Input: “Retries with Exponential Backoff and Jitter … avoids thundering herd”
- Bold: Row: Level=Pattern | Category=Reliability | Item=Retries with Backoff + Jitter | Core Idea=Space out retries with randomness to reduce contention | When=Transient failures | Pitfalls=Retry storms | Metrics=Retry histograms, success‑after‑retry | Keywords=Exponential backoff, Jitter

## Maintenance

- Bold: Reuse: copy this method for other large notes
- Bold: Evolve: if schema changes, record rationale in an ADR
- Bold: Finalize: when EOF reached, freeze coverage marker and keywords
