'use strict';

const fs      = require('fs');
const path    = require('path');
const bcrypt  = require('bcryptjs');
const { Client } = require('pg');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

// =============================================================================
// ThesisFlow — Seed Script
//
// Inserts example users and example theses into the database.
// Safe to run multiple times — skips anything that already exists.
//
// Usage:
//   node database/seed.js
//   make db-seed
// =============================================================================

const SEED_DIR   = path.join(__dirname, '..', 'seed');
const USERS_FILE = path.join(SEED_DIR, 'users.json');
const THESES_DIR = path.join(SEED_DIR, 'example-theses');

// System account that owns platform example theses.
// Not intended for login — password hash is a deliberate placeholder.
const SYSTEM_SEED_USER = {
  username:      'thesisflow_seed',
  email:         'seed@thesisflow.local',
  password_hash: 'SEED_ONLY_NOT_A_REAL_HASH',
};

// ---------------------------------------------------------------------------

async function main() {
  const client = new Client({ connectionString: process.env.DATABASE_URL_MIGRATOR });
  await client.connect();
  console.log('Connected to database.\n');

  try {
    await client.query('BEGIN');

    // 1. Seed example users (loginable dev accounts)
    await seedUsers(client);

    // 2. Ensure system seed account exists (owns example theses)
    const systemUserId = await upsertSystemSeedUser(client);

    // 3. Seed example theses
    await seedTheses(client, systemUserId);

    await client.query('COMMIT');
    console.log('\nSeed complete.');

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('\nSeed failed — rolled back.\n', err.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

// ---------------------------------------------------------------------------
// Users
// ---------------------------------------------------------------------------

async function seedUsers(client) {
  if (!fs.existsSync(USERS_FILE)) {
    console.log('No seed/users.json found — skipping example users.\n');
    return;
  }

  const users = JSON.parse(fs.readFileSync(USERS_FILE, 'utf-8'));
  console.log(`Seeding ${users.length} example user(s)...`);

  for (const user of users) {
    const existing = await client.query(
      'SELECT id FROM users WHERE email = $1',
      [user.email]
    );

    if (existing.rows.length > 0) {
      console.log(`  Skipped  — ${user.email} already exists`);
      continue;
    }

    const passwordHash = await bcrypt.hash(user.password, 10);

    await client.query(`
      INSERT INTO users (username, email, password_hash, bio, avatar_url)
      VALUES ($1, $2, $3, $4, $5)
    `, [
      user.username,
      user.email,
      passwordHash,
      user.bio       ?? null,
      user.avatar_url ?? null,
    ]);

    console.log(`  Inserted — ${user.email} (password: ${user.password})`);
  }

  console.log('');
}

// ---------------------------------------------------------------------------

async function upsertSystemSeedUser(client) {
  const result = await client.query(`
    INSERT INTO users (username, email, password_hash)
    VALUES ($1, $2, $3)
    ON CONFLICT (email) DO UPDATE SET username = EXCLUDED.username
    RETURNING id
  `, [
    SYSTEM_SEED_USER.username,
    SYSTEM_SEED_USER.email,
    SYSTEM_SEED_USER.password_hash,
  ]);

  console.log(`System seed user: ${SYSTEM_SEED_USER.email} (${result.rows[0].id})\n`);
  return result.rows[0].id;
}

// ---------------------------------------------------------------------------
// Theses
// ---------------------------------------------------------------------------

async function seedTheses(client, ownerId) {
  if (!fs.existsSync(THESES_DIR)) {
    console.log('No seed/example-theses/ directory found — skipping theses.\n');
    return;
  }

  const files = fs.readdirSync(THESES_DIR)
    .filter(f => f.endsWith('.json'))
    .sort();

  if (files.length === 0) {
    console.log('No .json files found in seed/example-theses/.\n');
    return;
  }

  console.log(`Seeding ${files.length} example thesis/theses...`);

  for (const file of files) {
    const data = JSON.parse(fs.readFileSync(path.join(THESES_DIR, file), 'utf-8'));
    await seedThesis(client, ownerId, data);
  }
}

async function seedThesis(client, ownerId, data) {
  const existing = await client.query(
    'SELECT id FROM theses WHERE title = $1',
    [data.title]
  );

  if (existing.rows.length > 0) {
    console.log(`  Skipped  — "${data.title}" already exists`);
    return;
  }

  // Resolve monitoring profile name → id
  let monitoringProfileId = null;
  if (data.monitoring_profile) {
    const profile = await client.query(
      'SELECT id FROM monitoring_profiles WHERE name = $1',
      [data.monitoring_profile]
    );
    if (profile.rows.length > 0) {
      monitoringProfileId = profile.rows[0].id;
    } else {
      console.warn(`  Warning  — monitoring profile "${data.monitoring_profile}" not found, leaving null`);
    }
  }

  // Insert thesis
  const thesisResult = await client.query(`
    INSERT INTO theses (
      owner_user_id,
      title,
      summary,
      description,
      status,
      visibility,
      current_confidence,
      confidence_rationale,
      author_stated_confidence,
      ai_stated_confidence,
      ai_stated_rationale,
      relevance_score,
      original_author,
      original_source,
      monitoring_profile_id
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15
    )
    RETURNING id
  `, [
    ownerId,
    data.title,
    data.summary                  ?? null,
    data.description              ?? null,
    data.status                   ?? 'ACTIVE',
    data.visibility               ?? 'PUBLIC',
    data.current_confidence       ?? 50.00,
    data.confidence_rationale     ?? null,
    data.author_stated_confidence ?? null,
    data.ai_stated_confidence     ?? null,
    data.ai_stated_rationale      ?? null,
    data.relevance_score          ?? null,
    data.original_author          ?? null,
    data.original_source          ?? null,
    monitoringProfileId,
  ]);

  const thesisId = thesisResult.rows[0].id;
  console.log(`  Inserted — "${data.title}"`);
  console.log(`             ${thesisId}`);

  // Insert criteria
  if (Array.isArray(data.criteria) && data.criteria.length > 0) {
    for (const criterion of data.criteria) {
      await client.query(`
        INSERT INTO criteria (
          thesis_id, description, rationale, type,
          weight, impact_if_confirmed, current_fulfillment
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      `, [
        thesisId,
        criterion.description,
        criterion.rationale           ?? null,
        criterion.type,
        criterion.weight              ?? null,
        criterion.impact_if_confirmed ?? null,
        criterion.current_fulfillment ?? 0,
      ]);
    }
    console.log(`             ${data.criteria.length} criteria inserted`);
  }

  // Upsert tags and link to thesis
  if (Array.isArray(data.tags) && data.tags.length > 0) {
    for (const tagName of data.tags) {
      const tagResult = await client.query(`
        INSERT INTO tags (name) VALUES ($1)
        ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
        RETURNING id
      `, [tagName]);

      await client.query(`
        INSERT INTO thesis_tags (thesis_id, tag_id)
        VALUES ($1, $2)
        ON CONFLICT DO NOTHING
      `, [thesisId, tagResult.rows[0].id]);
    }
    console.log(`             ${data.tags.length} tags linked`);
  }
}

// ---------------------------------------------------------------------------

main();
