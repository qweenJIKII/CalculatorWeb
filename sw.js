/*
  Simple Service Worker for Calculator PWA
  - Precaches core assets
  - Network-first for navigation, fallback to cache, then offline page
  - Stale-while-revalidate for static assets
*/
const VERSION = 'v1.1.3';
const CACHE_NAME = `calc-cache-${VERSION}`;
const CORE_ASSETS = [
  './',
  './index.html',
  './manifest.webmanifest',
  './offline.html',
  './help.html',
  './memo.html',
  './qr.html'
];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    await cache.addAll(CORE_ASSETS.map((u) => new Request(u, { cache: 'reload' })));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)));
    await self.clients.claim();
  })());
});

// Navigation requests: network-first with cache fallback
async function handleNavigation(request) {
  try {
    const network = await fetch(request);
    const cache = await caches.open(CACHE_NAME);
    cache.put(request, network.clone());
    return network;
  } catch (e) {
    const cacheMatch = await caches.match(request);
    if (cacheMatch) return cacheMatch;
    return caches.match('./offline.html');
  }
}

// Static assets: stale-while-revalidate
async function handleAsset(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);
  const networkPromise = fetch(request).then((res) => {
    cache.put(request, res.clone());
    return res;
  }).catch(() => null);
  return cached || networkPromise || fetch(request);
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  const url = new URL(req.url);

  // Only handle GET
  if (req.method !== 'GET') return;

  // Same-origin only; ignore cross-origin requests
  if (url.origin !== location.origin) return;

  // HTML navigation
  if (req.mode === 'navigate') {
    event.respondWith(handleNavigation(req));
    return;
  }

  // Assets
  event.respondWith(handleAsset(req));
});
