// Guarda cada itinerario y documento abierto para verlo sin internet. Con conexión trae siempre la versión más reciente
// (pregunta al servidor sin usar la copia guardada del navegador); sin conexión (o si tarda más de 6 s) muestra la guardada.
// Las librerías (lector de PDF, códigos QR, letras) se guardan la primera vez y después se usan desde el celular.
const CACHE = 'itinerarios-v2', LIBS = 'librerias-v1';
const DE_AFUERA = /^https:\/\/(cdnjs\.cloudflare\.com|cdn\.jsdelivr\.net|fonts\.googleapis\.com|fonts\.gstatic\.com)\//;
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE && k !== LIBS).map(k => caches.delete(k)))).then(() => self.clients.claim())));
self.addEventListener('fetch', e => {
  const r = e.request, url = new URL(r.url);
  if (r.method !== 'GET') return;
  if (DE_AFUERA.test(r.url)) {
    e.respondWith(caches.open(LIBS).then(c => c.match(r).then(m => m || fetch(r).then(res => { if (res.ok || res.type === 'opaque') c.put(r, res.clone()); return res; }))));
    return;
  }
  if (url.origin !== location.origin) return;
  const guardada = () => caches.match(url.pathname).then(m => m || caches.match(r));
  const red = fetch(url.href, { cache: 'no-cache', credentials: 'same-origin' }).then(res => { if (res.ok) { const copia = res.clone(); caches.open(CACHE).then(c => c.put(url.pathname, copia)); } return res; });
  e.respondWith(new Promise(listo => {
    let hecho = false;
    const dar = res => { if (!hecho && res) { hecho = true; listo(res); } };
    const t = setTimeout(() => guardada().then(dar), 6000);
    red.then(res => { clearTimeout(t); dar(res); }).catch(() => guardada().then(m => dar(m || Response.error())));
  }));
});
