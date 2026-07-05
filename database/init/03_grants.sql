-- =============================================================================
-- ThesisFlow — Role Grants
-- Runs after 02_schema.sql so all tables and sequences exist.
-- =============================================================================

-- Schema visibility for all app roles
GRANT USAGE ON SCHEMA public TO thesisflow_migrator;
GRANT USAGE ON SCHEMA public TO thesisflow_app;
GRANT USAGE ON SCHEMA public TO thesisflow_readonly;


-- -----------------------------------------------------------------------------
-- thesisflow_migrator — full DDL + DML
-- Used by the NestJS engine to run migrations. Never used at runtime.
-- -----------------------------------------------------------------------------
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA public TO thesisflow_migrator;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO thesisflow_migrator;

-- Apply to tables/sequences created by future migrations
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON TABLES    TO thesisflow_migrator;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON SEQUENCES TO thesisflow_migrator;


-- -----------------------------------------------------------------------------
-- thesisflow_app — DML only
-- Runtime user. Cannot DROP, TRUNCATE, or ALTER anything.
-- -----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES    IN SCHEMA public TO thesisflow_app;
GRANT USAGE, SELECT                  ON ALL SEQUENCES IN SCHEMA public TO thesisflow_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES    TO thesisflow_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT                  ON SEQUENCES TO thesisflow_app;


-- -----------------------------------------------------------------------------
-- thesisflow_readonly — SELECT only
-- Safe for analytics queries, debugging, and future read replicas.
-- -----------------------------------------------------------------------------
GRANT SELECT ON ALL TABLES IN SCHEMA public TO thesisflow_readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO thesisflow_readonly;
