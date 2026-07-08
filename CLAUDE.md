# ThesisFlow

Repositories

- thesisflow-web: Next.js web UI.
- thesisflow-engine: API, AI orchestration, RSS ingestion, monitoring.
- thesisflow-android: Android wrapper and widget.

Core concepts

- Thesis
- Evidence
- Confidence
- Monitoring Profile
- Watch Signal
- Falsification Criteria

Product vocabulary

- Users are called **Contenders** everywhere in the product, UI, API, and code.
- The database table is `users` — do not rename it. Convention beats branding at the infrastructure level.
- The TypeORM entity class is `Contender` with `@Entity('users')`.
- Services, controllers, and DTOs use `Contender` / `Contenders` throughout.

Loading state language

Every async action has two phases, each with its own copy:
- Phase 1 — CMS / user-side work (saving, validating): **"Contenders, ready…"**
- Phase 2 — LLM / AI / external API work (scoring, monitoring): **"Gladiators, ready…"**

This mirrors the Gladiators TV show cadence and should be used consistently across web, mobile, and widget loading states.

Design principles

- Engine contains business logic.
- Web/mobile are clients.
- Widgets never contain business logic.