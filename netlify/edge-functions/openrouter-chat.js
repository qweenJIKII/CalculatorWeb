// Netlify Edge Function: OpenRouter proxy (JSON + SSE)
// Requires environment variable: OPENROUTER_API_KEY

export default async (request) => {
  if (request.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }
  const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';
  let body;
  try {
    body = await request.json();
  } catch (e) {
    return new Response('Bad Request', { status: 400 });
  }
  const stream = !!body?.stream;
  const apiKey = (typeof Deno !== 'undefined' && Deno.env && Deno.env.get) ? (Deno.env.get('OPENROUTER_API_KEY') || '') : '';
  if (!apiKey) {
    return new Response('Server not configured: OPENROUTER_API_KEY missing', { status: 500 });
  }

  const urlObj = new URL(request.url);
  const headers = {
    'Authorization': `Bearer ${apiKey}`,
    'Content-Type': 'application/json',
    'HTTP-Referer': urlObj.origin,
    'X-Title': 'Calculator Web Product Chat',
  };

  const upstream = await fetch(OPENROUTER_URL, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });

  if (!stream) {
    const text = await upstream.text();
    return new Response(text, {
      status: upstream.status,
      headers: {
        'content-type': 'application/json',
        'cache-control': 'no-store',
      },
    });
  }

  if (!upstream.ok) {
    const text = await upstream.text();
    return new Response(text, { status: upstream.status });
  }

  // SSE passthrough
  return new Response(upstream.body, {
    status: 200,
    headers: {
      'content-type': 'text/event-stream',
      'cache-control': 'no-cache, no-store, must-revalidate',
      'connection': 'keep-alive',
    },
  });
};
