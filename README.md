# ThesisFlow Workspace

> The root workspace for the ThesisFlow ecosystem.

ThesisFlow is an AI-powered platform for creating, monitoring and evolving **theses**.

A thesis may be:

- An investment thesis
- A scientific hypothesis
- A historical claim
- A political prediction
- A business strategy
- Any proposition whose confidence changes as new evidence emerges

Rather than monitoring news directly, ThesisFlow monitors how incoming evidence affects confidence in a thesis.

---

# Repository Structure

```
ThesisFlow/
│
├── docs/
├── graphify/
├── CLAUDE.md
├── README.md
├── clone-all.sh
├── update-all.sh
│
├── thesisflow-web/
├── thesisflow-engine/
└── thesisflow-android/
```

---

# Repositories

## thesisflow-web

Next.js + PrimeReact frontend.

Responsibilities:

- User interface
- Authentication flows
- Thesis management
- Public thesis pages
- Dashboards
- Administration

---

## thesisflow-engine

NestJS backend.

Responsibilities:

- REST API
- AI orchestration
- RSS ingestion
- News aggregation
- Confidence scoring
- Monitoring scheduler
- Notifications
- Database access
- User management

This repository contains the business logic of ThesisFlow.

---

## thesisflow-android

Native Android application.

Responsibilities:

- Android wrapper around the web application
- Home Screen Widgets
- Push notifications
- Native Android integrations

Business logic remains inside the Engine.

---

# Core Principles

- Engine contains business logic.
- Clients are thin.
- Widgets contain no business logic.
- Everything communicates through the Engine API.
- A Thesis is the primary domain object.

---

# Core Domain

```
Thesis
│
├── Confidence
├── Confidence Rationale
├── Confidence History
├── Relevance Score
├── Evidence
├── Supporting Criteria
├── Falsification Criteria
├── Monitoring Profile
├── Alerts
├── Watch Signals
└── Comments
```

## Thesis Visibility

Every thesis has a visibility setting:

| Visibility | Who can see it |
|------------|---------------|
| **Public** | Everyone — listed in search and explore |
| **Unlisted** | Anyone with the direct link — not listed publicly |
| **Private** | Owner and approved followers only |

For private theses, followers have a status:

- **Active** — approved, full access
- **Pending** — requested access, awaiting owner approval
- **Invited** — owner sent an invite, awaiting acceptance

Existing followers retain access if a thesis is switched from public to private.

---

## Confidence vs Relevance

A thesis tracks two independent scores:

**Confidence** is the probability the thesis is true, updated automatically as evidence arrives.

**Relevance** (1–5) is how much the thesis still matters — whether the underlying question is still being actively contested. A thesis can be 3% likely to be true but 5/5 relevant because the scientific community is still actively debating it. A settled question scores 1/5 and should stop consuming monitoring credits.

Relevance is **set by the user**. The AI suggests a value alongside each monitoring run, but the user has final say.

---

# Monitoring Philosophy

Users allocate monitoring resources according to importance.

Examples:

| Profile | Interval | Typical Use |
|---------|----------|-------------|
| Continuous | 1 minute | AI stocks, breaking situations |
| Live | 15 minutes | Crypto, fast-moving markets |
| Active | Hourly | Major companies, active campaigns |
| Standard | Daily | General investing, business strategy |
| Slow | Weekly | Industry trends, policy |
| Cosmic | Bi-weekly | Scientific theories, long-horizon ideas |

Monitoring costs are shared across all followers of a thesis — the more followers, the lower the per-user cost of each run.

---

# Technology Stack

## Frontend

- Next.js
- React
- TypeScript
- PrimeReact

## Backend

- NestJS
- Fastify
- TypeScript

## Database

- PostgreSQL

## Cache / Queues

- Redis

## Mobile

- Kotlin
- Jetpack Compose
- Android Widgets (Glance)

---

# Long-Term Vision

ThesisFlow is not a speculation engine, nor an RSS reader.

It is an evidence engine.

Incoming information changes the confidence of theses.

Users follow, fork, improve and monitor theses over time.

The platform aims to become a living knowledge graph of evolving ideas, where every confidence change is supported by evidence.

---

# Getting Started

Clone the repositories:

```bash
./clone-all.sh
```

Update all repositories:

```bash
./update-all.sh
```

---

# Status

🚧 Early architecture phase.