// Service worker for hjemskjermappen.
// Henter alltid nyeste versjon fra nettet (ingen utdatert kode). Bare hvis nettet er nede,
// vises siste lagrede utgave av selve appsiden. Kall til Supabase går aldri via cache.
const CACHE = 'tid-v1';
const APP_FILER = ['/', '/manifest.webmanifest', '/ikoner/ikon-192.png'];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(APP_FILER)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((nokler) => Promise.all(nokler.filter((n) => n !== CACHE).map((n) => caches.delete(n))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);
  if (e.request.method !== 'GET' || url.origin !== self.location.origin) return; // Supabase/CDN: rett til nettet
  e.respondWith(
    fetch(e.request)
      .then((svar) => {
        if (svar.ok && e.request.mode === 'navigate') {
          const kopi = svar.clone();
          caches.open(CACHE).then((c) => c.put('/', kopi));
        }
        return svar;
      })
      .catch(() => caches.match(e.request).then((t) => t || caches.match('/')))
  );
});
