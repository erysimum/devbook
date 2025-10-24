import express from 'express';

const app = express();

app.get('/api/health', (_req, res) => {
  res.json({ ok: true });
});

const port = 3000;

app.listen(port, () => {
  console.log(`Test server listening on http://localhost:${port}`);
});

setInterval(() => {
  console.log('Still alive:', new Date().toISOString());
}, 5000);
