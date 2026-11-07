# Design decisions

## Step 1 foundation

- The 15-level campaign in `assets/data/extra/campaign.json` is the campaign structure in `GAME_BRIEF.md`. The original `assets/data/levels.json` has six differently named planned levels. It remains unchanged as required; the new campaign supersedes it for campaign flow.
- `assets/data/sites.json` contains the legacy site descriptions and labels but does not encode the requested difficulty classification. `site_risk.json` is the authoritative provisional source for the requested EASY, MEDIUM, HARD, and EXTREME labels. Its descriptions and effects are game values; effects remain empty until balancing.
- The moved prologue keeps its inline landing-site cards to preserve behavior in this step. The new site-risk layer is authoritative for the campaign; connecting the prologue cards to the repository is still pending and must use the corrected GAME VALUE descriptions.
- Construction costs, timer durations, research rewards, resource rates, assignments, and star thresholds lack approved design values. The extra config files are versioned, clearly provisional schemas with no invented final balances.
- Real-world timer policy uses UTC start/deadline timestamps. On rollback, elapsed time is clamped at zero and saved deadlines remain; completion is idempotent. A trustworthy monotonic clock across process/device restarts is unavailable in ordinary local app code, so this defensive policy favors no duplicate rewards or corrupted save over granting early completion.
- The app stays local-only. `provider` and `shared_preferences` are added for upcoming state and simple saves; no cloud service is used. A future save exceeding small key/value storage needs should move to a local database with an explicit migration.
- Android's main/release manifest contains no INTERNET permission. The debug manifest currently includes INTERNET for Flutter debugging; it is debug-only and does not enter the release manifest.

## Unresolved supplied-material gaps

- No repository `docs/source/` or `docs/reference/` existed. The two supplied PDFs and the supplied story text were copied into `docs/source/`; no visual-reference assets were supplied in the external pack, so `docs/reference/` is empty.
- The data pack did not contain a separate video script. `docs/source/Base 67 Game design and story.txt` is the only supplied story text and is retained as-is.
- There is no separate code implementation of the deterministic RNG in the starter app. The data pack's `game_constants.json` specifies `mulberry32` and default seed `20261105`; the simulation implementation is deferred.
