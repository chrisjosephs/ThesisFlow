users
-----
A registered user of the ThesisFlow platform.

+ id
+ username
+ email
+ password_hash
+ avatar_url
+ bio
+ created_at
+ updated_at


theses
-------
The primary domain object. Represents a proposition whose confidence changes as evidence arrives.

+ id
+ owner_user_id
+ title
+ summary
+ description
+ status      ENUM [DRAFT, ACTIVE, ARCHIVED, RESOLVED]
              DRAFT    — being written; no monitoring, no revisions, not public
              ACTIVE   — live; monitoring runs, revisions tracked
              ARCHIVED — manually retired; no monitoring
              RESOLVED — question answered (or expires_at reached); final state
+ visibility
+ current_confidence
+ confidence_rationale
+ author_stated_confidence
+ ai_stated_confidence
+ ai_stated_rationale
+ relevance_score  SMALLINT 0–5 — how topically active this thesis is right now (0 = dormant/ignore, 5 = highly active)
+ original_author
+ original_source
+ monitoring_profile_id
+ default_evidence_weight
+ expires_at               TIMESTAMPTZ — when the question becomes unanswerable; triggers status → RESOLVED
+ resolution               TEXT        — what actually happened ("Argentina won 3–2", "Hypothesis confirmed")
+ created_at
+ updated_at


thesis_confidence_history
-------------------------
An immutable log of every confidence change on a thesis, capturing the delta, the reason, and what triggered it.

thesis_revisions
----------------
Records only the fields that changed on a thesis, not a full row copy. A single edit that touches three fields
produces one revision row containing exactly those three fields. Unchanged fields are absent.

    Example — user moves the expiry date:
    { "expires_at": { "from": null, "to": "2026-07-15T00:00:00Z" } }

    Example — user renames the thesis and updates the summary:
    { "title": { "from": "old title", "to": "new title" },
      "summary": { "from": "old summary", "to": "new summary" } }

+ id
+ thesis_id   → theses.id
+ changed_by  → users.id (nullable — system changes have no user)
+ changes     JSONB  { field: { from, to } }
+ created_at

+ id
+ thesis_id
+ confidence_before
+ confidence_after
+ change_reason
+ generated_by
+ created_at


documents
---------
A document is a piece of information ingested by the platform.

    Examples:
    
    - RSS article
    - Manual URL
    - Peer-reviewed journal
    - SEC filing
    - PDF
    - Blog post
    - Government publication
    - Social media post
    - YouTube transcript
    - Email
    - Book

+ id
+ source_id
+ document_type
+ title
+ url
+ published_at
+ summary
+ raw_text
+ credibility
+ content_hash
+ created_at


document_type
-------------
[
RSS_ARTICLE,
MANUAL_URL,
JOURNAL,
SEC_FILING,
PDF,
BLOG,
GOVERNMENT_PUBLICATION,
SOCIAL_POST,
YOUTUBE_TRANSCRIPT,
EMAIL,
BOOK,
OTHER
]


thesis_evidence
---------------
Represents the relationship between a Thesis and a Document.

A document becomes "evidence" only in the context of a thesis.

+ id
+ thesis_id
+ document_id

+ stance

Where stance is:

[
SUPPORTS,
CONTRADICTS,
NEUTRAL
]

+ relevance
+ confidence_impact

+ user_override
+ override_reason

+ created_at


sources
-------
Represents the publisher or origin.

    Examples:
    
    Reuters
    
    Nature
    
    NASA
    
    Micron Investor Relations
    
    United States SEC

+ id
+ name
+ source_type
+ homepage
+ credibility
+ platform_managed
+ created_at


source_type
-----------
[
GOVERNMENT,
COMPANY,
NEWS,
PEER_REVIEWED_JOURNAL,
SOCIAL,
BLOG,
FORUM,
INDIVIDUAL,
OTHER
]


source_endpoints
----------------

Represents the mechanism used to ingest information.

Examples:

RSS

Atom

REST API

Manual URL

Web Scraper

Webhook

+ id
+ source_id
+ endpoint_type
+ endpoint_url
+ enabled
+ last_checked
+ etag
+ last_modified


endpoint_type
-------------
[
RSS,
ATOM,
API,
SCRAPER,
MANUAL,
WEBHOOK
]


monitoring_profiles
-------------------
Defines how frequently a thesis is checked for new evidence, from real-time to bi-weekly. Seeded at startup; users choose one per thesis.

The monitoring tempo also governs how quickly community confidence votes decay. Faster monitoring
= faster decay, because evidence is arriving more frequently and opinions formed before it are
less trustworthy. Both parameters are calibrated per profile rather than being global constants.

+ id
+ name
+ refresh_interval_seconds
+ estimated_cost
+ description
+ community_half_life_days  — age at which a community vote carries half its original weight
+ community_stale_days      — days since most-recent vote beyond which average is flagged stale

| Profile    | Interval   | Half-life   | Stale after |
|------------|------------|-------------|-------------|
| CONTINUOUS | 1 min      | 0.25 days   | 1 day       |
| LIVE       | 15 min     | 1 day       | 3 days      |
| ACTIVE     | 1 hour     | 7 days      | 21 days     |
| STANDARD   | 1 day      | 30 days     | 60 days     |
| SLOW       | 1 week     | 90 days     | 180 days    |
| COSMIC     | 2 weeks    | 180 days    | 365 days    |


criteria
--------
A condition attached to a thesis that, if met, would meaningfully support it, falsify it, or trigger a watch signal.

+ id
+ thesis_id
+ description
+ rationale
+ type
+ weight
+ impact_if_confirmed
+ current_fulfillment

Where type is:

[
SUPPORT,
FALSIFY,
WATCH_SIGNAL
]


alerts
------
A notification delivered to a user when something notable happens on a thesis they own or follow.

+ id
+ user_id
+ thesis_id
+ alert_type
+ message
+ read_at
+ created_at


comments
--------
A user comment on a thesis, visible to anyone who can see the thesis.

+ id
+ thesis_id
+ user_id
+ body
+ created_at


tags
----
A label used to categorise and discover theses across the platform.

+ id
+ name


thesis_tags
-----------
Join table linking theses to their tags.

+ thesis_id
+ tag_id


user_confidence_submissions
---------------------------
Append-only log of user confidence estimates. Every submission creates a new row — full
history is preserved. Users can submit as many times as they like as evidence changes.

The community average is computed from the most-recent submission per user, decay-weighted
by age (60-day half-life: a 60-day-old vote counts half as much as a fresh one). This means
the average naturally responds to recent opinion shifts without requiring any manual expiry.

Only accumulates on public/unlisted theses — private theses receive no external submissions.

+ id
+ thesis_id                       → theses.id
+ user_id                         → users.id
+ confidence                      NUMERIC(5,2) — 0–100, the user's estimate
+ rationale                       TEXT (optional) — why they gave this rating
+ thesis_confidence_at_submission  NUMERIC(5,2) — snapshot of current_confidence at vote time
                                   Enables staleness detection: if current_confidence has drifted
                                   significantly from this value, the vote may no longer reflect
                                   the user's actual view given current evidence.
+ created_at
+ updated_at


thesis_follows
--------------

Tracks who follows a thesis. Status controls access to private theses.

+ user_id     → users.id
+ thesis_id   → theses.id
+ status      ENUM [ACTIVE, PENDING, INVITED]
+ created_at

Where status is:

[
ACTIVE,   -- approved follower, can see the thesis
PENDING,  -- requested access, awaiting owner approval
INVITED   -- owner sent invite, awaiting acceptance
]


thesis_forks
------------
Records when a user derives a new thesis from an existing one, preserving the lineage between the original and the fork.

+ parent_thesis_id
+ child_thesis_id
+ forked_by
+ created_at


claims
------

A document contains one or more claims.

Claims are the fundamental units of reasoning inside ThesisFlow.

+ id
+ canonical_statement
+ subject
+ predicate
+ object


document_claims
---------------

Many-to-many relationship between documents and claims.

Multiple documents may contain the same claim.

+ document_id
+ claim_id


claim_relationships (Future)
----------------------------

Allows claims to support, contradict or refine one another.

+ id
+ claim_a_id
+ claim_b_id
+ relationship_type


relationship_type
-----------------

[
SUPPORTS,
CONTRADICTS,
DUPLICATES,
REFINES,
DEPENDS_ON
]