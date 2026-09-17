# 2026-09-17 — gamma_large_node_corridor: idea ratified (D1–D4 + materiality) → blueprint CANDIDATE sealed, awaiting ratification

## What was built/decided

Research Agent study `gamma_large_node_corridor` (new; consumer of the
decision: classification of the `gamma_reconstruction` Cboe proxy pool).
Research question: is the price effect of material large 0DTE gamma nodes
carried by the **±5/±10 corridor** rather than the **exact node strike**?
This session ran the full idea → blueprint-candidate arc.

1. **Idea developed + gated.** Three-source grounding (M10; Avellaneda
   stock-pinning, Ni pervasive impact, Adams 0DTE; method_contracts
   zero-hit reported). Feasibility probed: certified UW pool = 184 sessions
   2025-12-12→2026-09-08, 5-pt strike grid, 51.4% of captures with a
   material node. PM ruled all four decisions + materiality (2026-09-17):
   **D1** cluster-level union corridor (constituent strikes = attributes);
   **D2** far-edge traversal primary (REJECTION / CORRIDOR_TRAVERSAL;
   NODE_CROSS / DOMINANT_NODE_CROSS secondary); **D3** floors 10 pp / 10 min
   ratified but inference repaired — C1 is an **equivalence bound** (ratio
   < 0.20 AND joint/bootstrap upper CI < 0.20; corridor effect positive and
   identified; no pass on nonsignificance), RMT for censored times,
   gate-clearing rule = floor + corrected OOS inference + same direction in
   declared stability splits, co-primary rule for persistence/dwell;
   **materiality retained** (pos primary γ ≥ 2,500; major |γ| ≥ 5,000;
   negative arm separate, never pooled — no threshold-mining); **D4** full
   184-session slice primary with mandatory era/grid stratification, C_43
   clean robustness.
2. **Blueprint CANDIDATE (12 sections) + sealed 115-card manifest.**
   `specs/blueprint.md` SHA256 `a69e3846eaf220643d75f2ecc236d56d53771bbd2444873bc8711e0e92e2f297`;
   `specs/method_applicability.yaml` sealed on that hash (66 on / 49 off);
   carry-forward audit: no contradictions, 4 explicitly-unresolved items =
   decision items DI-1…DI-4. **Awaiting PM ratification** — stop point.
3. **Key measured facts (new evidence this session):**
   * **Pool `spot` column NULL for all rows post-2026-06-30** → spx_1min is
     the single PIT spot source for the whole slice (A-1 convention: close
     of bar t−1). Pins: pool `3772fd41…` (1,634,105 rows); spx_1min
     `8bdfab49…` (1,859,818 rows; 184/184 slice days).
   * Grid classes: A_36 = 56 days, B_42 = 48, C_43 = 78, 2 PARTIAL days
     (2025-12-24: 26 caps; 2026-03-31: 40).
   * State census (major stratum, RTH): S_ISO5 ≈ 615, S_ISO10 ≈ 630,
     S_CLU5 ≈ 1,176, S_CLU10 ≈ 76, S_NONE ≈ 4,189 captures — dense in all
     three eras (a < 05-19, b 05-19→06-29, c ≥ 06-30).
   * Diagnostic-only dynamics (10-min, uncorrected, no matching):
     persistence UP vs matched-width control (+3…+11 pp @5, +3…+26 pp @10,
     era c largest), dwell DOWN (−58…−122 min) — close-concentrated; era
     interaction real → era stratification + {b,c} stability splits
     load-bearing.
4. **Decision queue at stop (DI-1…DI-4):** DI-1 OOS = last 74 sessions
   (consequence: OOS is C_43-era; A_36/B_42 = dev-only replication);
   DI-2 gate statistic = P(both-boundary-touch) + 4 reported categories;
   DI-3 persistence+dwell both co-primary in F1; DI-4 PARTIAL days retained
   as declared stratum.

## Where to resume

`/data/research_agent/studies/gamma_large_node_corridor/RESUME_BRIEF.md`
(exact resume point, branches after ratification, artifact map, sibling-study
checklist). HEAD research_agent `b92ba8a` (brief commit; blueprint `e0e2412`). Next lifecycle step after
ratification: explicit PM authorization → build specification
(`prompts/build_spec.md`) → STOP for build-spec ratification.

## Sibling thread (same maintenance window)

`gamma_node_price_pull_discovery` forward protocol v1.1 FROZEN
(`72323f84…`), logger armed, ledger at 8 setup-days. Post-maintenance:
verify 09-15/16/17 substrate back-fill, `forward_logger.py replay` per
confirmed day (09-17 = first pure-forward session), confirm 09-07 vendor
re-ingest, resume same-day EOD accrual. Final build adjudication still
PM-initiated.
