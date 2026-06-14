// =====================================================================
// sw.js — Tuition Portal service worker
// Minimal app-shell cache with network-first for navigations.
// Bump CACHE_VERSION to force clients to update.
// =====================================================================
const CACHE_VERSION = 'v3';
const CACHE_NAME = 'tuition-' + CACHE_VERSION;

const PRECACHE = [
  './',
  './index.html',
  './manifest.webmanifest',
  './shared/css/styles.css',
  './shared/js/supabase-client.js',
  './shared/js/auth.js',
  './shared/js/utils.js',
  './shared/js/app-shell.js',
  './icon-192.png',
  './icon-512.png',
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then(c => c.addAll(PRECACHE).catch(() => {}))
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  // Never cache Supabase API or auth calls
  if (url.host.includes('supabase.co') || url.host.includes('supabase.in')) return;
  // Skip non-http(s)
  if (!url.protocol.startsWith('http')) return;

  // Network-first for HTML navigations
  if (req.mode === 'navigate' || req.headers.get('accept')?.includes('text/html')) {
    event.respondWith((async () => {
      try {
        const fresh = await fetch(req);
        const cache = await caches.open(CACHE_NAME);
        cache.put(req, fresh.clone()).catch(() => {});
        return fresh;
      } catch {
        return (await caches.match(req)) || (await caches.match('./index.html')) ||
               new Response('Offline', { status: 503 });
      }
    })());
    return;
  }

  // Cache-first for same-origin static assets
  if (url.origin === self.location.origin) {
    event.respondWith((async () => {
      const cached = await caches.match(req);
      if (cached) return cached;
      try {
        const resp = await fetch(req);
        if (resp.ok && resp.type === 'basic') {
          const cache = await caches.open(CACHE_NAME);
          cache.put(req, resp.clone()).catch(() => {});
        }
        return resp;
      } catch {
        return new Response('', { status: 504 });
      }
    })());
  }
});
