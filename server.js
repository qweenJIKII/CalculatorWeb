/*
  Express proxy for OpenRouter Chat Completions
  - Reads OPENROUTER_API_KEY from environment (or .env)
  - Endpoint: POST /api/openrouter-chat
  - Supports both JSON and SSE streaming (stream:true)
  - Also serves static files in this directory
*/

const path = require('path');
const express = require('express');
const cors = require('cors');
const fetch = require('node-fetch'); // v2 (CJS)
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors({ origin: true }));
app.use(express.json({ limit: '1mb' }));
app.use(express.static(__dirname));

const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';
const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY || '';

function getReferer(req){
  return req.headers['origin'] || req.headers['referer'] || `http://localhost:${PORT}`;
}

app.post('/api/openrouter-chat', async (req, res) => {
  try{
    if (!OPENROUTER_API_KEY){
      return res.status(500).json({ error: 'Server is not configured with OPENROUTER_API_KEY' });
    }
    const body = req.body || {};
    const stream = !!body.stream;

    const headers = {
      'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': getReferer(req),
      'X-Title': 'Calculator Web Product Chat',
    };

    const upstream = await fetch(OPENROUTER_URL, {
      method: 'POST',
      headers,
      body: JSON.stringify(body),
    });

    if (!stream){
      // Non-stream JSON path
      const text = await upstream.text();
      if (!upstream.ok){
        // Forward error with original status
        return res.status(upstream.status).send(text);
      }
      res.setHeader('Cache-Control', 'no-store');
      res.type('application/json').send(text);
      return;
    }

    // Streaming (SSE) path
    if (!upstream.ok){
      const text = await upstream.text();
      return res.status(upstream.status).send(text);
    }

    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders && res.flushHeaders();

    upstream.body.on('data', (chunk) => {
      res.write(chunk);
    });
    upstream.body.on('end', () => {
      res.end();
    });
    upstream.body.on('error', (err) => {
      console.error('Upstream stream error:', err);
      res.end();
    });

    req.on('close', () => {
      try{ upstream.body.destroy && upstream.body.destroy(); }catch(_){ /* noop */ }
    });
  }catch(err){
    console.error(err);
    res.status(500).json({ error: 'Proxy error', detail: String(err && err.message || err) });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log('Serving static files from', __dirname);
});
