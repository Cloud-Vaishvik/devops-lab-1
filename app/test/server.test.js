// Real HTTP tests, not a file-exists smoke check: the CI Test stage has to be
// able to actually fail. Uses node:test (built in, Node >= 20) so the pipeline
// needs no extra dev dependency.
const { test, before, after } = require('node:test');
const assert = require('node:assert');
const { start } = require('../src/server');

let server, base;

before(async () => {
  server = start(0);                       // port 0 = ephemeral, no port clashes in CI
  await new Promise((r) => server.once('listening', r));
  base = `http://127.0.0.1:${server.address().port}`;
});

after(() => server.close());

test('GET / returns 200 and the expected JSON contract', async () => {
  const res = await fetch(`${base}/`);
  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.match(body.message, /DevOps Lab 1/);
  assert.ok('version' in body, 'response must carry the build version');
  assert.ok('build' in body, 'response must carry the build number');
  assert.strictEqual(typeof body.hits, 'number');
});

test('the hit counter increments across requests', async () => {
  const first = await (await fetch(`${base}/`)).json();
  const second = await (await fetch(`${base}/`)).json();
  assert.strictEqual(second.hits, first.hits + 1);
});

test('GET /healthz reports liveness', async () => {
  const res = await fetch(`${base}/healthz`);
  assert.strictEqual(res.status, 200);
  assert.strictEqual(await res.text(), 'ok');
});

test('GET /readyz reports readiness', async () => {
  const res = await fetch(`${base}/readyz`);
  assert.strictEqual(res.status, 200);
  assert.strictEqual(await res.text(), 'ready');
});

test('an unknown route returns 404 rather than hanging', async () => {
  const res = await fetch(`${base}/does-not-exist`);
  assert.strictEqual(res.status, 404);
  assert.strictEqual((await res.json()).error, 'not found');
});
