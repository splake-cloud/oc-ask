# 2026-09-11 — ES auction profile Study D (multi-horizon confluence) CLOSED / NO

Thread: pi session, `studies/es_auction_profile/`. Spec v10 FROZEN
(`specs/spec_v10_study_d_multi_horizon_confluence.md`, amended once @ f5cd286f
for the T4b pin correction 332→336).

## Verdict (operator closure ruling 2026-09-11)

**CLOSED / NO** — reach = no, dwell = no. Ruling's headline:
**"Multi-horizon VA overlap is geometrically real, but not behaviorally
robust over the next session."**

- Reach: 11 higher / 3 lower / 4 tied (17 constructible asofs) — visibly
  asymmetric, fails pre-registered uniformity. Operator: **pilot evidence
  of possible attraction, not "no attraction whatsoever"** → **BANKED as
  the replication candidate** (wider window / other horizons / sub-sessions).
- Dwell: 9/4/5 — weakest of the three.
- **Confluence-degree gradient FAILURE (sign reversals) = the study's
  strongest negative evidence.** Confluence count is NOT a monotonic
  strength score; future confluence designs must explain non-monotonicity.
- Structure side (readout-only): T4b 336 band×scale HVN co-location at all
  4 scales; T4a VPOC co-location (4/4 at 04-29). Confluence bands are
  genuinely volume-dense objects — the null is behavioral, not geometric.

**Binding framing correction (operator):** do NOT carry forward "the whole
'notable levels attract price' family keeps failing." What is established is
narrow: *neither single-point prominence nor multi-horizon VA overlap has
yet demonstrated a robust next-session attraction/stickiness effect against
the relevant frozen controls in this 19-session pilot window.* Implementation
confidence (gates/KASA, verifiable) and economic-hypothesis confidence (19
sessions) are **different statements**.

**Candidate meta-finding (UNCONFIRMED):** auction-profile structure may
describe **path topology** (C = YES: LVN traversal completeness) better than
**destination probability** (A/B/D = NO: no attraction). Needs a confirming
design before it's citable.

## Chain (all on master, Agent-Print pi/qwen3.8-27b-fp8)

f5cd286f spec+T4b fix → f433ef23 build (core+build) → c1587d15 check PASS +
2 spec-conformance fixes the check caught (rep-label = lex-min per §2.1;
control_window true-NULL per §3.5 — implementation was wrong, spec was not)
→ ddb0128f KASA 12/12 (0 BLOCKER/0 MAJOR, closure-eligible).
Deposits: verify/study_d_v1_check_pins.20260910T182213Z.txt,
verify/kasa_study_d_rederive_v1.20260911T120002Z.txt.

## Facts pinned (reusable)

- Window: 19 admitted asofs (2026-04-13→05-08, 04-28 refused 1379 bars);
  123 bands = 85 confluent + 38 single; 75/85 constructible; 0 split;
  12 degenerate asofs / 14 groups (session-set identity; VAs identical per
  group — D1 pin).
- Event labels = registry **profile_id** verbatim (spec §4.1 col 4 example
  `[["1D","MTD"]]` is shorthand only).
- Control (Option V): hosts = k=1 runs, candidate = same-width sub-band,
  center of [a,b) = (a+b)/2 exact Fraction, **candidate center =
  (2·cs+w)/2 — NOT (cs+w)/2** (that bug cost a KASA iteration), tie → smaller
  s.
- Outcome: touch = high4≥lo4 ∧ low4<hi4_excl (A verbatim); dwell =
  close-membership total (never NULL, 0 on nontouch); t_touch = only
  NULL-on-nontouch field.
- Study sequence now: **A NO → B NO → C YES(completion) → D NO.**
- RAG: `value_area_not_built` card → built-state; `respect-disproven-findings`
  extended with A+D (small root live; full root pending_seed on GPU policy —
  next `seed-pending --root full` when ≥28.6 GB free).
- Handoff updated: `studies/es_auction_profile/HANDOFF_2026-09-10.md`
  (closed-state brief; §3 + §12 + §13 all reflect D).

## Open / next

1. **D-replication of the 11/3/4 reach asymmetry** — operator-driven start.
2. **Path-topology meta-finding** — confirming design needed.
3. Studies E (developing VPOC migration), F (price discovery) — unstarted.
4. Full-root RAG seed (GPU-gated; verify with rag-search "confluence degree gradient").
5. FEATURE_REGISTRY.md `value_area_position` tier still says "infrastructure
   not yet built" (doctrine_clauses/feature_contracts wells, separate well
   harvested from the registry file) — re-tier is a design decision, NOT done
   unilaterally at closure.
