/* Carte de visite digitale ACG.
 *
 * Aucune donnée personnelle n'est stockée sur un serveur :
 *  - la carte du consultant vit dans le localStorage de son téléphone ;
 *  - le QR code contient la fiche contact (vCard) complète ;
 *  - le lien partagé / écrit sur la puce NFC transporte la carte dans son fragment (#c=...).
 *
 * Fragments d'URL :
 *   #c=<données>  carte reçue : affichage pour l'interlocuteur (ne touche pas à la carte locale)
 *   #s=<données>  lien de configuration : enregistre la carte sur ce téléphone
 */
(function () {
  'use strict';

  var ORG = 'Afflatus Consulting Group';
  var SITE = 'https://afflatus.consulting';
  var CONTACT = 'contact@afflatusconsulting.com';
  var BESOIN = 'https://inspirra.tech/p/opportunite/5k_GzuVVqWbJtBlCY5idaXcaCAjeOJSkl7rYPD9xX6E';
  var KEY = 'acg-carte-v1';
  var FIELDS = ['p', 'n', 't', 'm', 'e']; // prénom, nom, poste, mobile, email

  var $ = function (id) { return document.getElementById(id); };
  var profile = null;
  var installEvent = null;

  /* ---------- données ---------- */

  function clean(o) {
    if (!o || typeof o !== 'object') return null;
    var out = {};
    for (var i = 0; i < FIELDS.length; i++) {
      var v = o[FIELDS[i]];
      if (typeof v !== 'string' || !v.trim()) return null;
      out[FIELDS[i]] = v.replace(/[\u0000-\u001f]/g, ' ').trim().slice(0, 80);
    }
    if (o.b) out.b = 1; // badge BRCGS Approved Consultant
    return out;
  }

  function encode(o) {
    var bytes = new TextEncoder().encode(JSON.stringify(o)), s = '';
    for (var i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
    return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  }

  function decode(s) {
    try {
      var bin = atob(s.replace(/-/g, '+').replace(/_/g, '/'));
      var bytes = new Uint8Array(bin.length);
      for (var i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
      return clean(JSON.parse(new TextDecoder().decode(bytes)));
    } catch (e) { return null; }
  }

  function load() {
    try { return clean(JSON.parse(localStorage.getItem(KEY))); } catch (e) { return null; }
  }

  function save(o) {
    try { localStorage.setItem(KEY, JSON.stringify(o)); } catch (e) { /* stockage indisponible : la carte reste affichée pour cette session */ }
  }

  function digits(tel) { return tel.replace(/[^\d+]/g, ''); }

  function vcard(o) {
    var esc = function (v) { return v.replace(/\\/g, '\\\\').replace(/([,;])/g, '\\$1'); };
    return [
      'BEGIN:VCARD', 'VERSION:3.0',
      'N:' + esc(o.n) + ';' + esc(o.p) + ';;;',
      'FN:' + esc(o.p + ' ' + o.n),
      'ORG:' + ORG,
      'TITLE:' + esc(o.t),
      'TEL;TYPE=CELL:' + digits(o.m),
      'EMAIL;TYPE=WORK:' + o.e,
      'EMAIL:' + CONTACT,
      'URL:' + SITE,
      'ADR;TYPE=WORK:;;;Rabat;;;Maroc',
      'END:VCARD', ''
    ].join('\r\n');
  }

  function link(o) {
    return location.origin + location.pathname + '#c=' + encode(o);
  }

  /* ---------- affichage ---------- */

  function qrSvg(text) {
    qrcode.stringToBytes = qrcode.stringToBytesFuncs['UTF-8'];
    var q = qrcode(0, 'M');
    q.addData(text, 'Byte');
    q.make();
    var n = q.getModuleCount(), d = '';
    for (var y = 0; y < n; y++) for (var x = 0; x < n; x++) if (q.isDark(y, x)) d += 'M' + x + ' ' + y + 'h1v1h-1z';
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ' + n + ' ' + n +
      '" shape-rendering="crispEdges" role="img" aria-label="QR code du contact"><path fill="#1f1f21" d="' + d + '"/></svg>';
  }

  function setLink(id, href, text) {
    var a = $(id);
    a.href = href;
    a.querySelector('span').textContent = text;
  }

  function render(o, guest) {
    var tel = digits(o.m);
    $('nom').textContent = o.p + ' ' + o.n;
    $('titre').textContent = o.t;
    $('brcgs').hidden = !o.b;
    setLink('l-tel', 'tel:' + tel, o.m);
    setLink('l-email', 'mailto:' + o.e, o.e);
    setLink('l-contact', 'mailto:' + CONTACT, CONTACT);
    $('site').href = SITE;
    $('qr').innerHTML = qrSvg(vcard(o)); // SVG construit uniquement à partir de coordonnées numériques
    document.title = o.p + ' ' + o.n + ' · ' + ORG;

    $('bar-owner').hidden = guest;
    $('bar-guest').hidden = !guest;
    if (guest) {
      var a = $('g-save');
      if (a.href.indexOf('blob:') === 0) URL.revokeObjectURL(a.href);
      a.href = URL.createObjectURL(new Blob([vcard(o)], { type: 'text/vcard' }));
      a.download = (o.p + '-' + o.n).toLowerCase().replace(/[^a-z0-9]+/g, '-') + '.vcf';
      $('g-call').href = 'tel:' + tel;
      $('g-wa').href = 'https://wa.me/' + tel.replace('+', '');
      $('g-besoin').href = BESOIN;
    }
    installHint(guest);
  }

  function installHint(guest) {
    var standalone = matchMedia('(display-mode: standalone)').matches || navigator.standalone;
    var ios = /iphone|ipad|ipod/i.test(navigator.userAgent);
    var box = $('install');
    if (guest || standalone || !(installEvent || ios)) { box.hidden = true; return; }
    box.hidden = false;
    $('b-install').hidden = !installEvent;
    $('install-txt').textContent = installEvent
      ? 'Installez la carte sur votre écran d\'accueil.'
      : 'Pour installer : bouton Partager de Safari, puis « Sur l\'écran d\'accueil ».';
  }

  /* ---------- édition ---------- */

  function openEdit(first) {
    var o = profile || {};
    FIELDS.forEach(function (f) { $('i-' + f).value = o[f] || ''; });
    $('edit-h').textContent = first ? 'Créez votre carte de visite' : 'Modifier ma carte';
    $('b-cancel').hidden = first;
    $('d-edit').showModal();
  }

  $('f-edit').addEventListener('submit', function () {
    var o = {};
    FIELDS.forEach(function (f) { o[f] = $('i-' + f).value; });
    if (profile && profile.b) o.b = 1;
    o = clean(o);
    if (!o) return;
    profile = o;
    save(o);
    render(o, false);
  });
  // Tant qu'aucune carte n'existe, la fenêtre de création ne peut pas être fermée avec Échap.
  $('d-edit').addEventListener('cancel', function (e) { if (!profile) e.preventDefault(); });
  $('b-cancel').onclick = function () { $('d-edit').close(); };
  $('b-edit').onclick = function () { openEdit(false); };

  /* ---------- partage ---------- */

  function copy(text, btn) {
    var done = function () { var t = btn.textContent; btn.textContent = 'Copié ✓'; setTimeout(function () { btn.textContent = t; }, 1600); };
    if (navigator.clipboard) navigator.clipboard.writeText(text).then(done, function () {});
    else { $('lien').select(); document.execCommand('copy'); done(); }
  }

  $('b-share').onclick = function () {
    var url = link(profile), name = profile.p + ' ' + profile.n;
    if (navigator.share) navigator.share({ title: name, text: name + ' – ' + ORG, url: url }).catch(function () {});
    else copy(url, this);
  };

  /* ---------- NFC ---------- */

  $('b-nfc').onclick = function () {
    var can = 'NDEFReader' in window;
    $('nfc-android').hidden = !can;
    $('nfc-other').hidden = can;
    $('b-write').hidden = !can;
    $('nfcmsg').textContent = '';
    $('lien').value = link(profile);
    $('d-nfc').showModal();
  };
  $('b-nfc-close').onclick = function () { $('d-nfc').close(); };
  $('b-copy').onclick = function () { copy($('lien').value, this); };
  $('b-write').onclick = function () {
    var btn = this, msg = $('nfcmsg');
    btn.disabled = true;
    msg.textContent = 'Approchez la puce NFC…';
    new NDEFReader().write({ records: [{ recordType: 'url', data: link(profile) }] }).then(function () {
      msg.textContent = 'Puce NFC écrite ✓ Elle ouvre maintenant votre carte.';
    }, function (err) {
      msg.textContent = err && err.name === 'NotAllowedError'
        ? 'Autorisation NFC refusée. Activez le NFC et réessayez.'
        : 'Écriture impossible. Vérifiez que le NFC est activé et que la puce n\'est pas verrouillée.';
    }).then(function () { btn.disabled = false; });
  };

  /* ---------- installation ---------- */

  window.addEventListener('beforeinstallprompt', function (e) {
    e.preventDefault();
    installEvent = e;
    if (profile) installHint(!$('bar-guest').hidden);
  });
  $('b-install').onclick = function () {
    if (!installEvent) return;
    installEvent.prompt();
    installEvent = null;
    $('install').hidden = true;
  };
  if ('serviceWorker' in navigator && location.protocol !== 'file:') navigator.serviceWorker.register('sw.js');

  /* ---------- démarrage ---------- */

  function start() {
    var m = /^#([cs])=(.+)$/.exec(location.hash), got = m && decode(m[2]);
    if (got && m[1] === 'c') { render(got, true); return; }
    if (got && m[1] === 's') {
      save(got);
      history.replaceState(null, '', location.pathname);
    }
    profile = load() || (got && m[1] === 's' ? got : null);
    if (profile) render(profile, false);
    else openEdit(true);
  }

  window.addEventListener('hashchange', start);
  start();
})();
