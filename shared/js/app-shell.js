// =====================================================================
// app-shell.js — Modern shell helpers used by all portals.
//   * Theme management (dark default, persisted, propagated to iframes)
//   * Sheet open/close
//   * PWA registration
//   * Notice bell loader
// Depends on: shared/js/supabase-client.js, auth.js, utils.js
// =====================================================================

const AppShell = (() => {
  const THEME_KEY = 'tuition.theme';

  // ---------- Theme ----------
  function getTheme() {
    try { return localStorage.getItem(THEME_KEY) || 'dark'; }
    catch { return 'dark'; }
  }
  function applyTheme(theme, root) {
    (root || document.documentElement).setAttribute('data-theme', theme);
  }
  function setTheme(theme) {
    try { localStorage.setItem(THEME_KEY, theme); } catch {}
    applyTheme(theme);
    // propagate to any iframes
    document.querySelectorAll('iframe').forEach(f => {
      try { applyTheme(theme, f.contentDocument && f.contentDocument.documentElement); } catch {}
    });
  }
  function toggleTheme() {
    setTheme(getTheme() === 'dark' ? 'light' : 'dark');
  }
  // Apply ASAP — call before DOMContentLoaded
  applyTheme(getTheme());

  // ---------- Sheet ----------
  function openSheet(id) {
    const sheet = document.getElementById(id);
    const overlay = document.getElementById(id + '-overlay');
    if (!sheet) return;
    sheet.classList.add('open');
    if (overlay) overlay.classList.add('open');
    document.body.style.overflow = 'hidden';
  }
  function closeSheet(id) {
    const sheet = document.getElementById(id);
    const overlay = document.getElementById(id + '-overlay');
    if (sheet) sheet.classList.remove('open');
    if (overlay) overlay.classList.remove('open');
    document.body.style.overflow = '';
  }
  function closeAllSheets() {
    document.querySelectorAll('.sheet.open').forEach(s => s.classList.remove('open'));
    document.querySelectorAll('.sheet-overlay.open').forEach(o => o.classList.remove('open'));
    document.body.style.overflow = '';
  }

  // ---------- Iframe content loader ----------
  function loadFrame(frameId, page) {
    const frame = document.getElementById(frameId);
    if (!frame) return;
    frame.src = page;
    frame.addEventListener('load', () => {
      try {
        applyTheme(getTheme(), frame.contentDocument.documentElement);
      } catch {}
    }, { once: true });
  }

  // ---------- Notices ----------
  // Best-effort fetch of recent notices for the user. Returns array.
  // Falls back gracefully if the table shape differs.
  async function fetchRecentNotices(profile, limit = 15) {
    if (typeof sb === 'undefined') return [];
    try {
      const { data, error } = await sb
        .from('notices')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(limit);
      if (error) { console.warn('notices fetch error', error); return []; }
      return data || [];
    } catch (e) {
      console.warn('notices fetch failed', e);
      return [];
    }
  }

  // ---------- PWA registration ----------
  function registerPWA(basePath) {
    if (!('serviceWorker' in navigator)) return;
    // Don't register inside iframes
    if (window.top !== window.self) return;
    const url = (basePath || './') + 'sw.js';
    navigator.serviceWorker.register(url, { scope: basePath || './' })
      .catch(err => console.warn('SW registration failed', err));
  }

  return {
    getTheme, setTheme, toggleTheme, applyTheme,
    openSheet, closeSheet, closeAllSheets,
    loadFrame, fetchRecentNotices, registerPWA,
  };
})();
