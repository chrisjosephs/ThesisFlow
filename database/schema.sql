-- =============================================================================
-- ThesisFlow Database Schema
-- PostgreSQL 16+
-- Generated: 2026-07-05
-- =============================================================================


-- =============================================================================
-- ENUM TYPES
-- =============================================================================

CREATE TYPE thesis_status AS ENUM (
    'DRAFT',
    'ACTIVE',
    'ARCHIVED',
    'FALSIFIED'
);

CREATE TYPE thesis_visibility AS ENUM (
    'PUBLIC',
    'PRIVATE',
    'UNLISTED'
);

CREATE TYPE document_type AS ENUM (
    'RSS_ARTICLE',
    'MANUAL_URL',
    'JOURNAL',
    'SEC_FILING',
    'PDF',
    'BLOG',
    'GOVERNMENT_PUBLICATION',
    'SOCIAL_POST',
    'YOUTUBE_TRANSCRIPT',
    'EMAIL',
    'BOOK',
    'OTHER'
);

CREATE TYPE evidence_stance AS ENUM (
    'SUPPORTS',
    'CONTRADICTS',
    'NEUTRAL'
);

CREATE TYPE source_type AS ENUM (
    'GOVERNMENT',
    'COMPANY',
    'NEWS',
    'PEER_REVIEWED_JOURNAL',
    'SOCIAL',
    'BLOG',
    'FORUM',
    'INDIVIDUAL',
    'OTHER'
);

CREATE TYPE endpoint_type AS ENUM (
    'RSS',
    'ATOM',
    'API',
    'SCRAPER',
    'MANUAL',
    'WEBHOOK'
);

CREATE TYPE criteria_type AS ENUM (
    'SUPPORT',
    'FALSIFY',
    'WATCH_SIGNAL'
);

CREATE TYPE alert_type AS ENUM (
    'CONFIDENCE_THRESHOLD',
    'FALSIFICATION_TRIGGERED',
    'WATCH_SIGNAL_FIRED',
    'NEW_EVIDENCE',
    'STALE_THESIS'
);

-- Separate generator types: confidence history allows SYSTEM; evidence does not.
CREATE TYPE history_generator AS ENUM ('AI', 'USER', 'SYSTEM');
CREATE TYPE evidence_generator AS ENUM ('AI', 'USER');

CREATE TYPE follow_status AS ENUM (
    'ACTIVE',
    'PENDING',
    'INVITED'
);

-- Reserved for the future knowledge-graph phase.
CREATE TYPE claim_relationship_type AS ENUM (
    'SUPPORTS',
    'CONTRADICTS',
    'DUPLICATES',
    'REFINES',
    'DEPENDS_ON'
);


-- =============================================================================
-- SHARED TRIGGER: auto-update updated_at columns
-- =============================================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- =============================================================================
-- TABLES (ordered by foreign-key dependency)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- users
-- -----------------------------------------------------------------------------
CREATE TABLE users (
    id              UUID         NOT NULL DEFAULT gen_random_uuid(),
    username        VARCHAR(50)  NOT NULL,
    email           VARCHAR(255) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    avatar_url      VARCHAR(500),
    bio             TEXT,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT users_pkey        PRIMARY KEY (id),
    CONSTRAINT users_username_uk UNIQUE (username),
    CONSTRAINT users_email_uk    UNIQUE (email)
);

CREATE TRIGGER users_set_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- -----------------------------------------------------------------------------
-- monitoring_profiles
-- -----------------------------------------------------------------------------
CREATE TABLE monitoring_profiles (
    id                       UUID          NOT NULL DEFAULT gen_random_uuid(),
    name                     VARCHAR(100)  NOT NULL,
    refresh_interval_seconds INTEGER       NOT NULL,
    estimated_cost           NUMERIC(10,4),
    description              VARCHAR(500),

    CONSTRAINT monitoring_profiles_pkey             PRIMARY KEY (id),
    CONSTRAINT monitoring_profiles_name_uk          UNIQUE (name),
    CONSTRAINT monitoring_profiles_interval_check   CHECK (refresh_interval_seconds > 0)
);

-- Platform-defined cadence presets
INSERT INTO monitoring_profiles (name, refresh_interval_seconds, description) VALUES
    ('CONTINUOUS',  60,       'Real-time — AI stocks, breaking situations'),
    ('LIVE',        900,      'Every 15 minutes — crypto, fast-moving markets'),
    ('ACTIVE',      3600,     'Hourly — major companies, active campaigns'),
    ('STANDARD',    86400,    'Daily — general investing, business strategy'),
    ('SLOW',        604800,   'Weekly — industry trends, policy'),
    ('COSMIC',      1209600,  'Bi-weekly — scientific theories, long-horizon ideas');


-- -----------------------------------------------------------------------------
-- tags
-- -----------------------------------------------------------------------------
CREATE TABLE tags (
    id   UUID         NOT NULL DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,

    CONSTRAINT tags_pkey    PRIMARY KEY (id),
    CONSTRAINT tags_name_uk UNIQUE (name)
);


-- -----------------------------------------------------------------------------
-- sources
-- Represents a publisher or origin (e.g. Reuters, Nature, NASA).
-- Distinct from source_endpoints, which are the ingestion mechanisms.
-- -----------------------------------------------------------------------------
CREATE TABLE sources (
    id               UUID        NOT NULL DEFAULT gen_random_uuid(),
    name             VARCHAR(255) NOT NULL,
    source_type      source_type  NOT NULL,
    homepage         VARCHAR(2048),
    credibility      NUMERIC(5,2),
    platform_managed BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT sources_pkey             PRIMARY KEY (id),
    CONSTRAINT sources_credibility_chk  CHECK (credibility BETWEEN 0 AND 100)
);


-- -----------------------------------------------------------------------------
-- claims
-- Atomic units of reasoning stored as RDF-style triples.
-- Multiple documents may assert the same claim.
-- -----------------------------------------------------------------------------
CREATE TABLE claims (
    id                  UUID         NOT NULL DEFAULT gen_random_uuid(),
    canonical_statement TEXT         NOT NULL,
    subject             VARCHAR(500) NOT NULL,
    predicate           VARCHAR(500) NOT NULL,
    object              VARCHAR(500) NOT NULL,

    CONSTRAINT claims_pkey PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- theses
-- The primary domain object.
-- -----------------------------------------------------------------------------
CREATE TABLE theses (
    id                       UUID              NOT NULL DEFAULT gen_random_uuid(),
    owner_user_id            UUID              NOT NULL,
    title                    VARCHAR(255)      NOT NULL,
    summary                  VARCHAR(500),
    description              TEXT,
    status                   thesis_status     NOT NULL DEFAULT 'DRAFT',
    visibility               thesis_visibility NOT NULL DEFAULT 'PRIVATE',
    current_confidence       NUMERIC(5,2)      NOT NULL DEFAULT 50.00,
    confidence_rationale     TEXT,
    author_stated_confidence NUMERIC(5,2),
    ai_stated_confidence     NUMERIC(5,2),
    ai_stated_rationale      TEXT,
    relevance_score          SMALLINT,
    original_author          VARCHAR(255),
    original_source          VARCHAR(500),
    monitoring_profile_id    UUID,
    default_evidence_weight  NUMERIC(5,2)               DEFAULT 1.00,
    created_at               TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ       NOT NULL DEFAULT NOW(),

    CONSTRAINT theses_pkey                        PRIMARY KEY (id),
    CONSTRAINT theses_owner_fk                    FOREIGN KEY (owner_user_id)
                                                      REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT theses_monitoring_profile_fk       FOREIGN KEY (monitoring_profile_id)
                                                      REFERENCES monitoring_profiles (id) ON DELETE SET NULL,
    CONSTRAINT theses_confidence_chk              CHECK (current_confidence BETWEEN 0 AND 100),
    CONSTRAINT theses_author_stated_conf_chk      CHECK (author_stated_confidence BETWEEN 0 AND 100),
    CONSTRAINT theses_ai_stated_conf_chk          CHECK (ai_stated_confidence BETWEEN 0 AND 100),
    CONSTRAINT theses_relevance_chk               CHECK (relevance_score BETWEEN 1 AND 5)
);

CREATE INDEX theses_owner_idx              ON theses (owner_user_id);
CREATE INDEX theses_status_idx             ON theses (status);
CREATE INDEX theses_visibility_idx         ON theses (visibility);
CREATE INDEX theses_monitoring_profile_idx ON theses (monitoring_profile_id);

CREATE TRIGGER theses_set_updated_at
    BEFORE UPDATE ON theses
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- -----------------------------------------------------------------------------
-- thesis_confidence_history
-- Immutable log: one row per confidence change event.
-- -----------------------------------------------------------------------------
CREATE TABLE thesis_confidence_history (
    id                UUID             NOT NULL DEFAULT gen_random_uuid(),
    thesis_id         UUID             NOT NULL,
    confidence_before NUMERIC(5,2)     NOT NULL,
    confidence_after  NUMERIC(5,2)     NOT NULL,
    change_reason     TEXT,
    generated_by      history_generator NOT NULL,
    created_at        TIMESTAMPTZ      NOT NULL DEFAULT NOW(),

    CONSTRAINT thesis_confidence_history_pkey         PRIMARY KEY (id),
    CONSTRAINT thesis_confidence_history_thesis_fk    FOREIGN KEY (thesis_id)
                                                          REFERENCES theses (id) ON DELETE CASCADE,
    CONSTRAINT thesis_confidence_history_before_chk   CHECK (confidence_before BETWEEN 0 AND 100),
    CONSTRAINT thesis_confidence_history_after_chk    CHECK (confidence_after  BETWEEN 0 AND 100)
);

CREATE INDEX thesis_confidence_history_thesis_idx      ON thesis_confidence_history (thesis_id);
CREATE INDEX thesis_confidence_history_created_at_idx  ON thesis_confidence_history (created_at DESC);


-- -----------------------------------------------------------------------------
-- source_endpoints
-- The ingestion mechanism for a source (RSS feed, API, scraper, etc.)
-- -----------------------------------------------------------------------------
CREATE TABLE source_endpoints (
    id            UUID          NOT NULL DEFAULT gen_random_uuid(),
    source_id     UUID          NOT NULL,
    endpoint_type endpoint_type NOT NULL,
    endpoint_url  VARCHAR(2048) NOT NULL,
    enabled       BOOLEAN       NOT NULL DEFAULT TRUE,
    last_checked  TIMESTAMPTZ,
    etag          VARCHAR(255),
    last_modified VARCHAR(255),
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT source_endpoints_pkey      PRIMARY KEY (id),
    CONSTRAINT source_endpoints_source_fk FOREIGN KEY (source_id)
                                              REFERENCES sources (id) ON DELETE CASCADE
);

CREATE INDEX source_endpoints_source_idx  ON source_endpoints (source_id);
CREATE INDEX source_endpoints_enabled_idx ON source_endpoints (enabled) WHERE enabled = TRUE;

CREATE TRIGGER source_endpoints_set_updated_at
    BEFORE UPDATE ON source_endpoints
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- -----------------------------------------------------------------------------
-- documents
-- A piece of information ingested by the platform.
-- Becomes evidence only in the context of a thesis (see thesis_evidence).
-- -----------------------------------------------------------------------------
CREATE TABLE documents (
    id            UUID          NOT NULL DEFAULT gen_random_uuid(),
    source_id     UUID,
    document_type document_type NOT NULL,
    title         VARCHAR(500)  NOT NULL,
    url           VARCHAR(2048),
    published_at  TIMESTAMPTZ,
    summary       TEXT,
    raw_text      TEXT,
    credibility   NUMERIC(5,2),
    content_hash  VARCHAR(64),
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT documents_pkey             PRIMARY KEY (id),
    CONSTRAINT documents_source_fk        FOREIGN KEY (source_id)
                                              REFERENCES sources (id) ON DELETE SET NULL,
    CONSTRAINT documents_content_hash_uk  UNIQUE (content_hash),
    CONSTRAINT documents_credibility_chk  CHECK (credibility BETWEEN 0 AND 100)
);

CREATE INDEX documents_source_idx        ON documents (source_id);
CREATE INDEX documents_document_type_idx ON documents (document_type);
CREATE INDEX documents_published_at_idx  ON documents (published_at DESC);


-- -----------------------------------------------------------------------------
-- criteria
-- Supporting and falsification criteria belonging to a thesis.
-- -----------------------------------------------------------------------------
CREATE TABLE criteria (
    id                  UUID          NOT NULL DEFAULT gen_random_uuid(),
    thesis_id           UUID          NOT NULL,
    description         VARCHAR(1000) NOT NULL,
    rationale           TEXT,
    type                criteria_type NOT NULL,
    weight              SMALLINT,
    impact_if_confirmed NUMERIC(5,2),
    current_fulfillment NUMERIC(5,2)           DEFAULT 0.00,

    CONSTRAINT criteria_pkey              PRIMARY KEY (id),
    CONSTRAINT criteria_thesis_fk         FOREIGN KEY (thesis_id)
                                              REFERENCES theses (id) ON DELETE CASCADE,
    CONSTRAINT criteria_weight_chk        CHECK (weight BETWEEN 1 AND 10),
    CONSTRAINT criteria_impact_chk        CHECK (impact_if_confirmed BETWEEN -100 AND 100),
    CONSTRAINT criteria_fulfillment_chk   CHECK (current_fulfillment BETWEEN 0 AND 100)
);

CREATE INDEX criteria_thesis_idx ON criteria (thesis_id);
CREATE INDEX criteria_type_idx   ON criteria (type);


-- -----------------------------------------------------------------------------
-- thesis_evidence
-- Links a document to a thesis as evidence, with AI-scored delta and audit trail.
-- -----------------------------------------------------------------------------
CREATE TABLE thesis_evidence (
    id                UUID               NOT NULL DEFAULT gen_random_uuid(),
    thesis_id         UUID               NOT NULL,
    document_id       UUID               NOT NULL,
    criteria_id       UUID,
    stance            evidence_stance    NOT NULL,
    relevance         NUMERIC(5,2),
    confidence_impact NUMERIC(5,2),
    delta_applied     NUMERIC(5,2),
    generated_by      evidence_generator NOT NULL DEFAULT 'AI',
    reasoning         TEXT,
    user_override     BOOLEAN            NOT NULL DEFAULT FALSE,
    override_reason   TEXT,
    created_at        TIMESTAMPTZ        NOT NULL DEFAULT NOW(),

    CONSTRAINT thesis_evidence_pkey            PRIMARY KEY (id),
    CONSTRAINT thesis_evidence_thesis_fk       FOREIGN KEY (thesis_id)
                                                   REFERENCES theses (id)    ON DELETE CASCADE,
    CONSTRAINT thesis_evidence_document_fk     FOREIGN KEY (document_id)
                                                   REFERENCES documents (id) ON DELETE RESTRICT,
    CONSTRAINT thesis_evidence_criteria_fk     FOREIGN KEY (criteria_id)
                                                   REFERENCES criteria (id)  ON DELETE SET NULL,
    CONSTRAINT thesis_evidence_relevance_chk   CHECK (relevance BETWEEN 0 AND 100)
);

CREATE INDEX thesis_evidence_thesis_idx   ON thesis_evidence (thesis_id);
CREATE INDEX thesis_evidence_document_idx ON thesis_evidence (document_id);
CREATE INDEX thesis_evidence_criteria_idx ON thesis_evidence (criteria_id);


-- -----------------------------------------------------------------------------
-- alerts
-- -----------------------------------------------------------------------------
CREATE TABLE alerts (
    id         UUID        NOT NULL DEFAULT gen_random_uuid(),
    user_id    UUID        NOT NULL,
    thesis_id  UUID        NOT NULL,
    alert_type alert_type  NOT NULL,
    message    TEXT        NOT NULL,
    read_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT alerts_pkey      PRIMARY KEY (id),
    CONSTRAINT alerts_user_fk   FOREIGN KEY (user_id)
                                    REFERENCES users (id)  ON DELETE CASCADE,
    CONSTRAINT alerts_thesis_fk FOREIGN KEY (thesis_id)
                                    REFERENCES theses (id) ON DELETE CASCADE
);

CREATE INDEX alerts_user_idx   ON alerts (user_id);
CREATE INDEX alerts_thesis_idx ON alerts (thesis_id);
-- Partial index for fast unread queries
CREATE INDEX alerts_unread_idx ON alerts (user_id, created_at DESC) WHERE read_at IS NULL;


-- -----------------------------------------------------------------------------
-- comments
-- -----------------------------------------------------------------------------
CREATE TABLE comments (
    id         UUID        NOT NULL DEFAULT gen_random_uuid(),
    thesis_id  UUID        NOT NULL,
    user_id    UUID        NOT NULL,
    body       TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT comments_pkey      PRIMARY KEY (id),
    CONSTRAINT comments_thesis_fk FOREIGN KEY (thesis_id)
                                      REFERENCES theses (id) ON DELETE CASCADE,
    CONSTRAINT comments_user_fk   FOREIGN KEY (user_id)
                                      REFERENCES users (id)  ON DELETE RESTRICT
);

CREATE INDEX comments_thesis_idx ON comments (thesis_id);


-- -----------------------------------------------------------------------------
-- thesis_follows
-- Tracks which users follow a thesis.
-- Used to split monitoring costs across followers.
-- -----------------------------------------------------------------------------
CREATE TABLE thesis_follows (
    user_id    UUID          NOT NULL,
    thesis_id  UUID          NOT NULL,
    status     follow_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT thesis_follows_pkey      PRIMARY KEY (user_id, thesis_id),
    CONSTRAINT thesis_follows_user_fk   FOREIGN KEY (user_id)
                                            REFERENCES users (id)  ON DELETE CASCADE,
    CONSTRAINT thesis_follows_thesis_fk FOREIGN KEY (thesis_id)
                                            REFERENCES theses (id) ON DELETE CASCADE
);

CREATE INDEX thesis_follows_status_idx ON thesis_follows (thesis_id, status);

CREATE INDEX thesis_follows_thesis_idx ON thesis_follows (thesis_id);


-- -----------------------------------------------------------------------------
-- thesis_tags  (junction)
-- -----------------------------------------------------------------------------
CREATE TABLE thesis_tags (
    thesis_id UUID NOT NULL,
    tag_id    UUID NOT NULL,

    CONSTRAINT thesis_tags_pkey      PRIMARY KEY (thesis_id, tag_id),
    CONSTRAINT thesis_tags_thesis_fk FOREIGN KEY (thesis_id)
                                         REFERENCES theses (id) ON DELETE CASCADE,
    CONSTRAINT thesis_tags_tag_fk    FOREIGN KEY (tag_id)
                                         REFERENCES tags (id)   ON DELETE CASCADE
);


-- -----------------------------------------------------------------------------
-- thesis_forks  (junction)
-- -----------------------------------------------------------------------------
CREATE TABLE thesis_forks (
    parent_thesis_id UUID        NOT NULL,
    child_thesis_id  UUID        NOT NULL,
    forked_by        UUID        NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT thesis_forks_pkey          PRIMARY KEY (parent_thesis_id, child_thesis_id),
    CONSTRAINT thesis_forks_parent_fk     FOREIGN KEY (parent_thesis_id)
                                              REFERENCES theses (id) ON DELETE RESTRICT,
    CONSTRAINT thesis_forks_child_fk      FOREIGN KEY (child_thesis_id)
                                              REFERENCES theses (id) ON DELETE CASCADE,
    CONSTRAINT thesis_forks_forked_by_fk  FOREIGN KEY (forked_by)
                                              REFERENCES users (id)  ON DELETE RESTRICT,
    CONSTRAINT thesis_forks_no_self_fork  CHECK (parent_thesis_id <> child_thesis_id)
);


-- -----------------------------------------------------------------------------
-- document_claims  (junction)
-- Multiple documents may assert the same claim.
-- -----------------------------------------------------------------------------
CREATE TABLE document_claims (
    document_id UUID NOT NULL,
    claim_id    UUID NOT NULL,

    CONSTRAINT document_claims_pkey        PRIMARY KEY (document_id, claim_id),
    CONSTRAINT document_claims_document_fk FOREIGN KEY (document_id)
                                               REFERENCES documents (id) ON DELETE CASCADE,
    CONSTRAINT document_claims_claim_fk    FOREIGN KEY (claim_id)
                                               REFERENCES claims (id)    ON DELETE CASCADE
);


-- =============================================================================
-- FUTURE: claim_relationships
-- Not created in v0.1 — reserved for the knowledge-graph phase.
-- =============================================================================

-- CREATE TABLE claim_relationships (
--     id                UUID                    NOT NULL DEFAULT gen_random_uuid(),
--     claim_a_id        UUID                    NOT NULL,
--     claim_b_id        UUID                    NOT NULL,
--     relationship_type claim_relationship_type NOT NULL,
--
--     CONSTRAINT claim_relationships_pkey     PRIMARY KEY (id),
--     CONSTRAINT claim_relationships_a_fk     FOREIGN KEY (claim_a_id)
--                                                 REFERENCES claims (id) ON DELETE CASCADE,
--     CONSTRAINT claim_relationships_b_fk     FOREIGN KEY (claim_b_id)
--                                                 REFERENCES claims (id) ON DELETE CASCADE,
--     CONSTRAINT claim_relationships_no_self  CHECK (claim_a_id <> claim_b_id)
-- );
