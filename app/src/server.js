const os = require('os');
const express = require('express');

const PORT = process.env.PORT || 3000;
const APP_VERSION = process.env.APP_VERSION || 'dev';
const BUILD_NUMBER = process.env.BUILD_NUMBER || 'local';

const app = express();

// In-memory hit counter. Lab 1 is about the pipeline, not shared state, so the
// app deliberately has no external dependency -- the Test stage can run with
// nothing else installed. (Lab 2 moves this counter into Redis.)
let hits = 0;

app.get('/', (req, res) => {
  hits += 1;
  res.json({
    message: 'DevOps Lab 1 - Foundations & Continuous Integration',
    version: APP_VERSION,
    build: BUILD_NUMBER,
    servedBy: os.hostname(),
    hits,
    uptimeSeconds: Math.round(process.uptime())
  });
});

// Liveness: the process is up. Used by the pipeline's smoke-test stage.
app.get('/healthz', (req, res) => res.status(200).send('ok'));

// Readiness: the app can serve traffic. No dependencies here, so it is always
// ready once listening -- kept so the endpoint contract matches Lab 2.
app.get('/readyz', (req, res) => res.status(200).send('ready'));

app.use((req, res) => res.status(404).json({ error: 'not found', path: req.path }));

function start(port = PORT) {
  const server = app.listen(port, () =>
    console.log(`[${APP_VERSION} build ${BUILD_NUMBER}] listening on :${server.address().port} as ${os.hostname()}`)
  );
  // Graceful shutdown so a redeploy drains connections instead of dropping them.
  for (const sig of ['SIGTERM', 'SIGINT']) {
    process.on(sig, () => {
      console.log(`${sig} received - draining connections`);
      server.close(() => process.exit(0));
    });
  }
  return server;
}

// Export for the tests; only listen when run directly, so `node --test` can
// start the server on an ephemeral port without the module self-starting.
module.exports = { app, start };
if (require.main === module) start();
