import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
import { before, after, test } from 'node:test';
import { PGlite } from '@electric-sql/pglite';

const root = fileURLToPath(new URL('../', import.meta.url));
const queryFiles = {
  cohort: '07_cohort_retention.sql',
  curve: '08_retention_curve.sql',
  ltv: '10_ltv_fixed_cohorts.sql',
  fixed: '11_retention_revenue.sql',
};
let db;
let queries;
const numeric = value => value === null ? null : Number(value);
const isoDate = value => value instanceof Date ? value.toISOString().slice(0, 10) : String(value).slice(0, 10);

before(async () => {
  db = new PGlite();
  await db.exec(await readFile(resolve(root, 'sql/00_create_sales.sql'), 'utf8'));
  await db.exec(await readFile(new URL('./fixtures/retention.sql', import.meta.url), 'utf8'));
  queries = Object.fromEntries(await Promise.all(Object.entries(queryFiles).map(async ([key, name]) =>
    [key, await readFile(resolve(root, 'sql/customers', name), 'utf8')])));
});

after(async () => { await db?.close(); });

test('cohort grid includes observed zero months, excludes future months and deduplicates activity', async () => {
  const { rows } = await db.query(queries.cohort);
  assert.equal(rows.length, 37); // Jan 12 + Feb 11 + Jun 7 + Jul 6 + Dec 1.
  const jan = rows.filter(r => isoDate(r.cohort_month) === '2023-01-01');
  assert.deepEqual(jan.map(r => Number(r.month_number)), Array.from({ length: 12 }, (_, i) => i));
  assert.equal(numeric(jan[0].active_clients), 2);
  assert.equal(numeric(jan[0].retention_pct), 100);
  assert.equal(numeric(jan[1].active_clients), 0);
  assert.equal(numeric(jan[1].retention_pct), 0);
  assert.equal(numeric(jan[2].active_clients), 1);
  assert.equal(numeric(jan[2].retention_pct), 50);
  const december = rows.filter(r => isoDate(r.cohort_month) === '2023-12-01');
  assert.equal(december.length, 1);
  assert.equal(Number(december[0].month_number), 0);
});

test('weighted retention keeps inactive eligible cohorts in its denominator', async () => {
  const { rows } = await db.query(queries.curve);
  const m = index => rows.find(r => Number(r.month_number) === index);
  assert.equal(rows.length, 12);
  assert.equal(numeric(m(0).customers_at_start), 6);
  assert.equal(numeric(m(0).active_clients), 6);
  assert.equal(numeric(m(1).customers_at_start), 5); // December has no observed M1.
  assert.equal(numeric(m(1).active_clients), 1);
  assert.equal(numeric(m(1).retention_pct), 20); // 1/5, not 1/1.
  assert.equal(numeric(m(6).customers_at_start), 4); // July M6 would be in 2024.
  assert.equal(numeric(m(6).retention_pct), 25);
  assert.equal(numeric(m(11).customers_at_start), 2);
  assert.equal(numeric(m(11).retention_pct), 0);
});

test('fixed Jan-Jun cohorts use four original customers at all seven horizons', async () => {
  const { rows } = await db.query(queries.fixed);
  assert.deepEqual(rows.map(r => Number(r.month_number)), [0, 1, 2, 3, 4, 5, 6]);
  assert.deepEqual(rows.map(r => numeric(r.cohort_size)), [4, 4, 4, 4, 4, 4, 4]);
  assert.deepEqual(rows.map(r => numeric(r.active_clients)), [4, 1, 1, 0, 0, 0, 1]);
  assert.deepEqual(rows.map(r => numeric(r.retention_pct)), [100, 25, 25, 0, 0, 0, 25]);
  assert.deepEqual(rows.map(r => numeric(r.revenue_per_original_customer)), [135, 8, 15, 0, 0, 0, 10]);
  assert.deepEqual(rows.map(r => numeric(r.revenue_per_active_customer)), [135, 30, 60, null, null, null, 40]);
});

test('fixed-cohort revenue and existing cumulative LTV share the same customer base', async () => {
  const { rows } = await db.query(queries.ltv);
  assert.deepEqual(rows.map(r => numeric(r.customers_count)), [4, 4, 4, 4, 4, 4, 4]);
  assert.deepEqual(rows.map(r => numeric(r.cumulative_revenue_per_customer)), [135, 143, 158, 158, 158, 158, 168]);
});

test('empty input and a dataset containing only late cohorts do not fabricate observations', async () => {
  await db.exec('BEGIN;');
  try {
    await db.exec("DELETE FROM sales WHERE purchase_datetime < DATE '2023-07-01';");
    assert.equal((await db.query(queries.fixed)).rows.length, 0);
    await db.exec('TRUNCATE sales;');
    for (const key of ['cohort', 'curve', 'fixed']) {
      assert.equal((await db.query(queries[key])).rows.length, 0);
    }
  } finally {
    await db.exec('ROLLBACK;');
  }
});
