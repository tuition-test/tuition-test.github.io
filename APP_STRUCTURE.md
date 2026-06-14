# 🎓 Tuition Portal — App Structure & Redesign Guide

> Single source of truth for the **redesigned** Tuition Management System.
> Use this file to add new pages, hook into new Supabase tables, or change styles
> without breaking anything.
>
> For the original full schema / RLS / auth-flow reference, see
> [`PROJECT_DOCUMENTATION.md`](./PROJECT_DOCUMENTATION.md). This file documents the
> **new shell, design system, theming, PWA, and styling conventions** that were
> added on top of the original app.

---

## 1. What changed in the redesign

| Area | Before | After |
|---|---|---|
| Theme | Light only, indigo on white | **Dark by default**, light mode toggle, OS-style modern palette |
| Topbar | Plain bar with avatar | **Glassy sticky topbar**: profile avatar + name + class + bell + theme toggle |
| Student nav | Sidebar (hamburger) | **Bottom nav**: Home, Tests, Other (Other = bottom-sheet menu) |
| Other nav | Sidebar | Same bottom nav pattern (Home, Tests, Other → sheet) |
| Admin nav | Sidebar | Sidebar kept (admin = power-user); new theme + theme toggle |
| Notices | Page only | **Bell icon** opens a bottom sheet with the latest notices |
| Profile menu | Sidebar link | **Tap avatar** → bottom sheet with Profile, Theme switch, Logout |
| Install | Not installable | **PWA** — installable on iOS & Android, offline shell |
| Page content (homework, notices, fees, tests, etc.) | unchanged | **unchanged** — only restyled via the shared CSS |

> **No business-logic changes.** All Supabase calls, table names, auth flow,
> file-upload logic, and per-page JS in `student/pages/*`, `other/pages/*`, and
> `admin/pages/*` are untouched.

---

## 2. Folder structure

```
tuition-portal/
├── index.html                          ← Login + Register (redesigned shell)
├── 404.html
├── manifest.webmanifest                ← PWA manifest (NEW)
├── sw.js                               ← Service worker (NEW)
├── icon-192.png, icon-512.png, apple-touch-icon.png   ← PWA icons (NEW)
├── PROJECT_DOCUMENTATION.md            ← Original full reference
├── APP_STRUCTURE.md                    ← (this file)
│
├── shared/
│   ├── css/styles.css                  ← REWRITTEN — full design system
│   └── js/
│       ├── supabase-client.js          ← unchanged
│       ├── auth.js                     ← unchanged
│       ├── utils.js                    ← unchanged
│       └── app-shell.js                ← NEW — theme, sheets, PWA register, notices loader
│
├── student/
│   ├── index.html                      ← REWRITTEN — topbar + bottom nav + sheets
│   └── pages/  (unchanged content)
│       ├── home.html      profile.html   homework.html  notices.html
│       ├── fees.html      resources.html tests.html     exams.html
│
├── other/
│   ├── index.html                      ← REWRITTEN — topbar + bottom nav + sheets
│   └── pages/  (unchanged content)
│       ├── home.html     profile.html  notices.html   resources.html
│       ├── tests.html    contact.html  comments.html
│
└── admin/
    ├── index.html                      ← lightly edited — new topbar + theme toggle
    └── pages/  (unchanged content)
        ├── home.html  users.html  subjects.html  fees.html  homework.html
        ├── notices.html  tests.html  test-assembly.html  resources.html
        ├── comments.html  settings.html
```

---

## 3. Design system (shared/css/styles.css)

### 3.1 Theming

The theme is controlled by the `data-theme` attribute on `<html>`:

```html
<html data-theme="dark">   <!-- default -->
<html data-theme="light">
```

Every shell page contains this inline script in `<head>` so the theme paints
**before** first render (no flash):

```html
<script>
(function(){try{
  var t = localStorage.getItem('tuition.theme') || 'dark';
  document.documentElement.setAttribute('data-theme', t);
}catch(e){ document.documentElement.setAttribute('data-theme','dark'); }})();
</script>
```

When the user toggles theme, `AppShell.setTheme(theme)` persists to
`localStorage` AND propagates the attribute into any open iframes.

### 3.2 Tokens (CSS variables)

Defined in `:root` (dark) and `[data-theme="light"]`:

| Group | Tokens |
|---|---|
| Brand | `--primary`, `--primary-strong`, `--primary-dark`, `--primary-light`, `--accent`, `--gradient-primary`, `--gradient-soft` |
| Semantic | `--success`, `--danger`, `--warning`, `--info` |
| Surfaces | `--bg`, `--bg-elev`, `--card-bg`, `--card-bg-2`, `--surface-glass` |
| Text | `--text`, `--text-strong`, `--text-muted`, `--text-faint` |
| Borders | `--border`, `--border-strong` |
| Radii | `--radius`, `--radius-sm`, `--radius-lg`, `--radius-pill` |
| Shadows | `--shadow`, `--shadow-md`, `--shadow-glow` |
| Layout | `--topbar-h` (64), `--bottomnav-h` (70) |
| Fonts | `--font-display` (Plus Jakarta Sans), `--font-body` (Inter) |

**Always use variables. Do not hard-code colors in component HTML.**

### 3.3 Component classes (use these in new pages)

| Class | Purpose |
|---|---|
| `.page` | Page padding wrapper (also leaves room for bottom nav) |
| `.card` | Standard surface card (hover-lifts) |
| `.card-title` | Card heading |
| `.stats-grid` + `.stat-card` (modifiers: `.success`, `.warning`, `.danger`) | KPI cards |
| `.btn` (modifiers: `.btn-block`, `.btn-sm`, `.btn-outline`, `.btn-danger`, `.btn-success`, `.btn-muted`, `.btn-icon`) | Buttons |
| `.badge` (modifiers: `.badge-success`, `.badge-danger`, `.badge-warning`, `.badge-muted`) | Pills |
| `.table-wrap` + `<table>` | Responsive tables |
| `.form-group`, `label`, `input`, `select`, `textarea` | Forms (already styled globally) |
| `.spinner` | Loading spinner |
| `.error-text`, `.helper-text`, `.text-muted`, `.text-center`, `.hidden` | Utilities |

### 3.4 Shell-only classes

These are used by `student/index.html`, `other/index.html`, `admin/index.html`
and shouldn't typically appear in iframe page content:

`.topbar-v2`, `.tb-avatar`, `.tb-meta`, `.tb-name`, `.tb-sub`, `.tb-iconbtn`, `.tb-dot`,
`.bottom-nav`, `.content-frame-wrap`,
`.sheet`, `.sheet-overlay`, `.sheet-handle`, `.sheet-title`, `.sheet-list`,
`.sheet-item`, `.si-icon`, `.si-body`, `.si-title`, `.si-sub`, `.si-chev`,
`.theme-switch`, `.theme-switch-toggle`.

---

## 4. App shell API (`shared/js/app-shell.js`)

Loaded in every shell page (NOT in iframe pages, where it's unnecessary).
Exposes a global `AppShell` object:

```js
AppShell.getTheme()          // 'dark' | 'light'
AppShell.setTheme('light')   // persist + propagate to iframes
AppShell.toggleTheme()
AppShell.applyTheme(t, root) // optional: target a specific documentElement

AppShell.openSheet('profile-sheet')
AppShell.closeSheet('profile-sheet')
AppShell.closeAllSheets()

AppShell.loadFrame('content-frame', 'pages/home.html')
  // Sets iframe src AND re-applies theme to the iframe's <html> on load.

AppShell.fetchRecentNotices(profile, limit = 15)
  // Best-effort fetch from `notices` table. Returns [] on error.

AppShell.registerPWA('../')
  // Registers /sw.js. Skips registration inside iframes.
```

---

## 5. Shells in detail

### 5.1 Student shell (`student/index.html`)

```
┌──────────────────────────────────────────────┐
│ [Avatar] Name              [🔔] [🌓]         │ ← .topbar-v2
│         Board • Class                        │
├──────────────────────────────────────────────┤
│                                              │
│           <iframe id="content-frame">        │
│                                              │
├──────────────────────────────────────────────┤
│  [🏠 Home]  [📝 Tests]   [⋯ Other]           │ ← .bottom-nav
└──────────────────────────────────────────────┘
```

- **Avatar tap** → opens `#profile-sheet` (Profile, Theme switch, Logout).
- **Bell tap** → opens `#notice-sheet` (latest 15 from `notices` table; "Open all" → `pages/notices.html`).
- **Home / Tests** → direct iframe load.
- **Other** → opens `#other-sheet` with: Homework, Notices, Fees, Resources, Exams, Profile.

### 5.2 Other-student shell (`other/index.html`)

Same shell, "Other" sheet lists: Notices, Resources, Tuition Info, Comments, Profile.

### 5.3 Admin shell (`admin/index.html`)

Kept sidebar layout (admin = power user, often desktop). Added theme toggle in
top right and switched to new theme tokens. All existing admin page links
preserved.

### 5.4 Login (`index.html`)

Glassy auth card with animated gradient halo; tab switch Login/Register.
Theme toggle button at the bottom.

---

## 6. PWA installability

Files added at the repo root:

- `manifest.webmanifest` — name, icons, theme color, `display: standalone`
- `sw.js` — minimal service worker
  - Precaches the shell + shared CSS/JS
  - **Network-first** for HTML navigations (always fresh on Wi-Fi)
  - **Cache-first** for same-origin static assets
  - **Bypasses Supabase API requests** (never cached)
  - Bump `CACHE_VERSION` in `sw.js` to force-refresh all installed clients
- `icon-192.png`, `icon-512.png`, `apple-touch-icon.png`

Each shell HTML includes:

```html
<link rel="manifest" href="…/manifest.webmanifest" />
<link rel="apple-touch-icon" href="…/apple-touch-icon.png" />
<meta name="theme-color" content="#0b0d12" />
<meta name="apple-mobile-web-app-capable" content="yes" />
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
```

And registers the worker with `AppShell.registerPWA('../')` (path is relative
from the shell's location to repo root).

> **Install prompt** — On Android Chrome, an install banner appears
> automatically. On iOS Safari → Share → "Add to Home Screen".

---

## 7. Database / Supabase reference

The schema, RLS policies, storage buckets, and auth-flow details are
unchanged. They live in:

- `sql/schema.sql` — full DDL
- `PROJECT_DOCUMENTATION.md` §6–§9 — schema, RLS, storage, role matrix

### Key tables used by the shells

| Table | Used by shell for | Columns referenced |
|---|---|---|
| `profiles` | Avatar, name, board, class, profile_picture_url | `name`, `board`, `class`, `profile_picture_url`, `role`, `status`, `must_change_password`, `mobile` |
| `notices` | Bell sheet recent-notices list | `title`/`subject`, `body`/`message`/`content`, `created_at` |

`AppShell.fetchRecentNotices` is defensive — it tolerates missing optional
columns (e.g. uses `title || subject`, `body || message || content`). If you
add a new notice schema, update that function only.

### Adding a new Supabase call from a page

Pages in `*/pages/*.html` already include the Supabase JS CDN and `sb` global
(via `supabase-client.js`). New page template:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<meta name="base-path" content="../../" />
<title>My Page</title>
<link rel="stylesheet" href="../../shared/css/styles.css" />
<script>(function(){try{var t=localStorage.getItem('tuition.theme')||'dark';document.documentElement.setAttribute('data-theme',t);}catch(e){}})();</script>
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
</head>
<body>
<div class="page">
  <h2>My Page</h2>
  <div class="card">
    <div class="card-title">Hello</div>
    <div id="output"><div class="spinner"></div></div>
  </div>
</div>

<script src="../../shared/js/supabase-client.js"></script>
<script src="../../shared/js/auth.js"></script>
<script src="../../shared/js/utils.js"></script>
<script>
(async () => {
  const profile = await Auth.getProfile();
  const { data, error } = await sb.from('my_table').select('*').limit(20);
  if (error) { Utils.toast(error.message, 'error'); return; }
  document.getElementById('output').textContent = JSON.stringify(data, null, 2);
})();
</script>
</body>
</html>
```

---

## 8. Adding a new page to the student portal

1. Create `student/pages/myfeature.html` (use the template in §7).
2. Open `student/index.html` and add an entry in the **"Other" sheet**:
   ```html
   <button class="sheet-item" data-page="pages/myfeature.html">
     <div class="si-icon"><!-- SVG icon --></div>
     <div class="si-body">
       <div class="si-title">My Feature</div>
       <div class="si-sub">Short description</div>
     </div>
     <span class="si-chev">›</span>
   </button>
   ```
   The existing `document.querySelectorAll('.sheet-item[data-page]')` listener
   wires it up automatically.
3. If it deserves the **bottom nav** instead, replace one of the three
   buttons in `<nav class="bottom-nav">` or restructure to 4 columns by
   changing `grid-template-columns: repeat(3, 1fr)` to `repeat(4, 1fr)`
   in `.bottom-nav` in `styles.css`.

Same pattern for `other/index.html`.

For `admin/index.html`, add a `<a data-page="…">` in `#sidebar-nav`.

---

## 9. Styling conventions

- **Use tokens, never raw hex.** `color: var(--text-strong)`, not `color: #fff`.
- **Cards** wrap any group of related content: `<div class="card">…</div>`.
- **Section heading**: `<div class="card-title">📌 Title</div>` inside a card.
- **Buttons** always `.btn` + a modifier.
- **Stat KPIs**: use `.stats-grid` + `.stat-card`. Use `.success/.warning/.danger`
  to tint the gradient.
- **Forms** are global — just wrap each field in `<div class="form-group">`.
- **Tables**: wrap in `<div class="table-wrap">` for horizontal scroll on mobile.
- **Animations** are already applied (`pageIn` fade-rise on `.page` and `.card`,
  hover lift on cards/buttons, gradient halo on the auth page, bell ring on
  unread notices). Respect `prefers-reduced-motion`.
- **Mobile-first** — design at 360–390px width first, then scale up.

---

## 10. Known limitations / gotchas

- **iOS install icon**: must be a PNG. `apple-touch-icon.png` is provided.
- **GitHub Pages root**: `manifest.webmanifest` is referenced with relative
  paths (`./manifest.webmanifest`, `../manifest.webmanifest`). If you host
  the repo at a sub-path (`username.github.io/repo/`), the relative paths
  still work because every shell file references the manifest with the
  correct relative depth.
- **Service worker scope** is set per registration call. The student shell
  registers with `scope: '../'` so it covers the whole site.
- **Iframe theme sync**: when navigating to a fresh iframe page, the inline
  theme-bootstrap script in each page's `<head>` reads `localStorage` so the
  theme paints instantly. `AppShell.loadFrame` also re-applies the
  attribute on load as a safety net.
- **Supabase publishable key**: see §2 of `PROJECT_DOCUMENTATION.md` — you
  must replace the key in `shared/js/supabase-client.js` with the JWT
  `anon/public` key from your Supabase project.

---

## 11. Quick reference

```
Default route   → index.html (login / register)
Admin           → admin/index.html      (role: admin)
Tuition student → student/index.html    (role: tuition_student)
Other student   → other/index.html      (role: other_student)

Theme key       → localStorage 'tuition.theme' ('dark' | 'light')
SW path         → /sw.js (registered with relative scope)
Manifest path   → /manifest.webmanifest
PWA cache key   → 'tuition-vN' — bump N in sw.js to force update
```
