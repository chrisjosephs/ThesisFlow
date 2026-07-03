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
├── Confidence History
├── Evidence
├── Supporting Criteria
├── Falsification Criteria
├── Monitoring Profile
├── Alerts
├── Watch Signals
└── Comments
```

---

# Monitoring Philosophy

Users allocate monitoring resources according to importance.

Examples:

| Monitoring Profile | Typical Use |
|--------------------|-------------|
| Continuous | AI Stocks |
| Every 15 Minutes | Crypto |
| Hourly | Major Companies |
| Daily | General Investing |
| Weekly | Industry Trends |
| Monthly | Scientific Theories |
| Manual | Static Topics |

Future versions may implement a credit-based monitoring system where more frequent monitoring consumes more resources.

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