{{flutter_js}}
{{flutter_build_config}}

// Flutter's built-in service worker is deprecated (it only unregisters
// itself), so the app registers its own offline-capable worker (sw.js).
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  },
});

window.addEventListener('flutter-first-frame', function () {
  const splash = document.getElementById('splash');
  if (!splash) return;
  splash.style.opacity = '0';
  setTimeout(function () { splash.remove(); }, 300);
});

if ('serviceWorker' in navigator) {
  window.addEventListener('load', function () {
    navigator.serviceWorker
      .register('sw.js')
      .then(function () { return navigator.serviceWorker.ready; })
      .then(function (registration) {
        // Cache exactly what this browser loaded (renderer variant, fonts…)
        // so the next launch works offline.
        const urls = performance
          .getEntriesByType('resource')
          .map(function (e) { return e.name; })
          .filter(function (u) { return u.startsWith(location.origin); });
        urls.push(location.href.split('#')[0]);
        if (registration.active) {
          registration.active.postMessage({ type: 'cache-urls', urls: urls });
        }
      })
      .catch(function (e) { console.warn('Service worker registration failed', e); });
  });
}
