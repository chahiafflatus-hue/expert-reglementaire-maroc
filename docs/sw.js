// Service worker : rend l'application disponible hors connexion.
// Changer CACHE à chaque mise à jour publiée n'est pas nécessaire : chaque fichier
// est servi depuis le cache puis rafraîchi en arrière-plan (stale-while-revalidate).
var CACHE = 'carte-acg-v1';
var FILES = [
  './', 'index.html', 'app.js', 'vendor/qrcode.js', 'manifest.webmanifest',
  'assets/logo-blanc.png', 'assets/brcgs.png', 'assets/icon-192.png', 'assets/icon-512.png',
  'assets/montserrat-latin-500-normal.woff2', 'assets/montserrat-latin-500-italic.woff2',
  'assets/montserrat-latin-600-normal.woff2', 'assets/montserrat-latin-700-normal.woff2'
];

self.addEventListener('install', function (e) {
  e.waitUntil(caches.open(CACHE).then(function (c) { return c.addAll(FILES); }).then(function () { return self.skipWaiting(); }));
});

self.addEventListener('activate', function (e) {
  e.waitUntil(caches.keys().then(function (keys) {
    return Promise.all(keys.filter(function (k) { return k !== CACHE; }).map(function (k) { return caches.delete(k); }));
  }).then(function () { return self.clients.claim(); }));
});

self.addEventListener('fetch', function (e) {
  var req = e.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== location.origin) return;
  e.respondWith(caches.open(CACHE).then(function (cache) {
    return cache.match(req, { ignoreSearch: true }).then(function (hit) {
      var net = fetch(req).then(function (res) {
        if (res.ok) cache.put(req, res.clone());
        return res;
      });
      if (hit) { net.catch(function () {}); return hit; }
      return net;
    });
  }));
});
