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

Design principles

- Engine contains business logic.
- Web/mobile are clients.
- Widgets never contain business logic.