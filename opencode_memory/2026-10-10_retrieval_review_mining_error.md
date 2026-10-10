# 2026-10-10 — retrieval review: the v2 mining error, adjudicated

Thread: organic seeds v2 mining review (report `.ai/organic_seeds_retrieval_review_20261010.md`,
reviewed + claim-verified same day; review found the report's numbers mostly exact, one factual
error — the "nothing dated May–June" claim is contradicted by O36/O37 dated 2026-05-19 — and one
over-claim: 67 of the 447 empty captures DO have stub rows in the live opencode.db).

## The error, as adjudicated by PM (2026-10-10)

Two distinct failures, not one:

1. **Process gap (how the omission arose):** host-pi digest (672 ranked) built but never assigned
   to a worker (0 references in all four worker bundles — demonstrated by the assignment files);
   workers consumed the tops of rankings; no disposition ledger, so the unexamined tail was never
   reported. The unexamined remainder (e.g. captures: 776 ranked vs ~40 dispositioned) is a
   computable fact from the files on disk.
2. **Reporting failure (the separate, sharper one):** source checks verified the *authenticity of
   selected excerpts*; they did not establish that the *requested sources had been examined*; the
   completion report nonetheless described the search as complete. **Verified selected outputs
   stood in for verified coverage of the task** — a second instance of proxy substitution in this
   thread (after the attachment/provenance-hash matter).

## Corrections to the record

- **26/36 PM interventions ≠ 26/36 model errors.** W1's whole-session rejection of
  `ses_03ff16220` (26) and `ses_04469abdf` (36) may have been *appropriate*: if the interventions
  were largely new decisions/refinements, they are not error examples. The open question is whether
  individual passages contain usable comparisons — a per-passage eligibility assessment, NOT a
  forced decomposition, and NOT an escalation to the PM. The two sessions are "unassessed for
  comparison content," not "confirmed missed cards."
- **Causal language bounded to what artifacts demonstrate.** The orphaned digest + disposition
  counts are demonstrable. "Strong local checks made the pipeline feel audited" is a retrospective
  interpretation, not an established mechanism — not to be stated as cause.

## The durable lesson (PM wording)

> Before claiming completion, reconcile the requested scope with the work actually examined.
> Report unexamined material explicitly. Checks on selected outputs support those outputs, not
> completeness of the search.

Corrected invariants (PM-tightened; these replace my five):
1. Disposition ledger is accounting, not achievement: report examined and unexamined SEPARATELY;
   marking everything not-examined satisfies accounting without satisfying the request.
2. Thresholds prioritize; they do not silently narrow scope. State per source what was examined and
   what remains.
3. No pre-banking coverage gate: valid cards save incrementally; reconcile coverage before
   claiming the pool is complete or drawing total-yield conclusions.
4. (kept) Recording format ≠ selection criterion; compound sessions get local eligibility
   assessment, decomposition where warranted.

**Status: PM is holding the remediation. No mining resumes on the strength of the account.**
Pools as inventoried in the retrieval review (A = intervention bank 94 VPP-predicate lines, PM's
`training_data/poolA/` v1 already materialized 158 graded candidates — untracked; B = host pi
672; C = captures tail 44; D = the two seed-author sessions; E = pax (unopened); F/H = gen-1
side-cars; G = codex 31 rollouts). Both WIP artifacts (retrieval review + poolA) uncommitted.

## Pointer

- Verified review of the report: in-conversation, 2026-10-10 (claim-by-claim table; exact hits:
  bank 383/94/11-of-15, digests 776/672/100/49/6, 447=353+94 ≤8 msgs, gen-1 286/521/213/20,
  codex 31 files 05-31→09-03, rulings 159; errors: May–June claim, db-stub claim).
