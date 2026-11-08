# 04 Architecture map (intended; verify against the real repo before relying on it)

- **Stack:** Flutter (Dart), Android first, offline. Minimal dependencies: state management and local save only. Nothing that needs the internet at runtime.
- **Repository root:** the Git root is `H:\projects` and the Flutter project is the inner `base67` folder. After a clone, work in `base67\base67`.
- **Layout (from the brief):**

```
lib/app        routing, app state, campaign save
lib/data       models, repository, validator (reads assets/data)
lib/sim        simulation engine: pure Dart, NO Flutter imports
lib/ui         theme, widgets, characters, painters
lib/prologue   the 8-scene prologue
lib/game       Home Base, Campaign Map, level screens
assets/data            original data pack (read-only)
assets/data/extra      new GAME VALUE configuration files
docs                   living documents, vault, prompts, source, reference, archive
test                   unit and widget tests
```

## Layering rules
1. `lib/sim` never imports Flutter and never reads UI state. It is deterministic given a seed.
2. UI reads data only through the repository. UI never reads JSON directly.
3. Real-world timers are a separate service that stores UTC timestamps and never depends on the simulation clock.
4. Painters are cached and cheap. Nothing rebuilds the whole base every tick.
5. Debug-only screens (Data Check, Design Gallery) are gated by `kDebugMode` and absent from release.
