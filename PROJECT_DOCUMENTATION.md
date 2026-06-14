# 🎓 Tuition Management System — Complete Project Documentation

> **This file is the single source of truth** for architecture, database schema,
> RLS policies, auth flow, API key setup, deployment, and future expansion
> (including the Tuition Student Portal).

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack & Credentials](#2-tech-stack--credentials)
3. [Folder Structure](#3-folder-structure)
4. [First-Time Setup Guide](#4-first-time-setup-guide)
5. [Authentication System](#5-authentication-system)
6. [Complete Database Schema](#6-complete-database-schema)
7. [Row Level Security (RLS)](#7-row-level-security-rls)
8. [Storage Buckets](#8-storage-buckets)
9. [User Roles & Access Matrix](#9-user-roles--access-matrix)
10. [Admin Portal Guide](#10-admin-portal-guide)
11. [Tuition Student Portal Guide](#11-tuition-student-portal-guide)
12. [Other Student Portal Guide](#12-other-student-portal-guide)
13. [Building New Modules (Expansion Guide)](#13-building-new-modules-expansion-guide)
14. [GitHub Pages Deployment](#14-github-pages-deployment)
15. [Known Limitations & Workarounds](#15-known-limitations--workarounds)

---

## 1. Project Overview

A full-featured tuition management system for a private tuition centre. It supports:

- 3 user roles: **Admin**, **Tuition Student**, **Other Student**
- Username + password authentication (no email verification)
- Admin portal for managing students, fees, homework, notices, tests, resources
- Tuition student portal for accessing assigned homework, notices, fees, tests, resources
- Other student portal for limited access to resources, tests, notices, and a comment/feedback system

**Hosting**: 100% static — runs directly on GitHub Pages  
**Backend**: Supabase (Postgres + Auth + Storage via CDN JS client)  
**No build tools, no Node.js server, no npm packages**

---

## 2. Tech Stack & Credentials

### CDN Libraries Used
```html
<!-- Supabase JS (required on every page) -->
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>

<!-- SheetJS for Excel upload (admin/pages/tests.html only) -->
<script src="https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js"></script>
```

### Supabase Project
```
URL:              https://pchastwhpbsvjdyivwoi.supabase.co
Publishable Key:  sb_publishable_dFu7RY5VsM3BbN1b_u6Lbg_s5caH2It
```

> ⚠️ **IMPORTANT — API KEY FORMAT**
>
> The key provided (`sb_publishable_...`) is Supabase's newer publishable key
> format. The `supabase-js` v2 library requires a **JWT anon key** that starts
> with `eyJ...`.
>
> **Get the correct key:**
> 1. Go to Supabase Dashboard → your project → **Project Settings** → **API**
> 2. Copy the **"anon / public"** key (starts with `eyJhbGciOiJIUzI1NiIs...`)
> 3. Replace `SUPABASE_ANON_KEY` in `shared/js/supabase-client.js` with it

### Admin Credentials
```
Username:  admin
Password:  Admin@1998
```

---

## 3. Folder Structure

```
tuition-system/
│
├── index.html                        # Landing page: Login + Register tabs
├── 404.html                          # GitHub Pages fallback
├── .nojekyll                         # Disables Jekyll processing on GitHub Pages
├── PROJECT_DOCUMENTATION.md          # ← this file
│
├── .github/
│   └── workflows/
│       └── deploy.yml                # GitHub Actions auto-deploy to Pages
│
├── sql/
│   └── schema.sql                    # Complete DB schema — run once in Supabase SQL Editor
│
├── shared/
│   ├── css/
│   │   └── styles.css                # Global design system (mobile-first, CSS variables)
│   └── js/
│       ├── supabase-client.js        # Supabase client init + usernameToEmail() helper
│       ├── auth.js                   # Auth.login(), register(), logout(), guard(), etc.
│       └── utils.js                  # Utils.toast(), formatDate(), boardClasses, etc.
│
├── admin/
│   ├── index.html                    # Admin shell: topbar + sidebar + iframe
│   └── pages/
│       ├── home.html                 # Dashboard: stat cards, recent registrations, fee collections
│       ├── users.html                # User table, view/edit/deactivate/delete, upgrade, create tuition student
│       ├── subjects.html             # Subject CRUD with board/class filter
│       ├── fees.html                 # Monthly fee generation + payment recording
│       ├── homework.html             # Homework create/delete with board/class/subject targeting
│       ├── notices.html              # Notices with 4 target types + read tracking
│       ├── tests.html                # Question bank: Excel upload, stats, CRUD
│       ├── test-assembly.html        # Assemble tests from question bank; manage test questions
│       ├── resources.html            # File upload (PDF/DOCX/ZIP/Image) with visibility control
│       ├── comments.html             # View, reply, delete comments from Other Students
│       └── settings.html             # Tuition address, contact, social links, admin password
│
├── student/                          # TUITION STUDENT PORTAL
│   ├── index.html                    # Shell with sidebar + iframe
│   └── pages/
│       ├── home.html                 # Dashboard: subjects, fee status, homework count, notice count
│       ├── profile.html              # Edit profile, profile picture, change password
│       ├── homework.html             # Active homework for own board/class
│       ├── notices.html              # Targeted notices with read tracking
│       ├── fees.html                 # Payment history + total outstanding
│       ├── resources.html            # Resources for own board/class with subject filter
│       └── tests.html                # Take tests; instant score + answer review
│
└── other/                            # OTHER STUDENT PORTAL
    ├── index.html                    # Shell with sidebar + iframe
    └── pages/
        ├── home.html                 # Welcome + recent notices + featured resources
        ├── profile.html              # Edit profile, picture, board/class (self-declared), password
        ├── notices.html              # Notices targeted to 'all', their board/class, or their user ID
        ├── resources.html            # Resources where visible_to_other_students = true
        ├── tests.html                # Tests where visible_to_other_students = true
        ├── contact.html              # Tuition address, map link, social media links
        └── comments.html             # Submit comment, view own comments + admin replies
```

---

## 4. First-Time Setup Guide

### Step 1 — Supabase Configuration

1. Open the Supabase project at https://pchastwhpbsvjdyivwoi.supabase.co
2. Go to **Authentication → Providers → Email**:
   - Turn **OFF** "Confirm email"
   - Turn **OFF** "Secure email change"
3. Go to **Project Settings → API** and copy the **anon/public** JWT key

### Step 2 — Update the API Key

Open `shared/js/supabase-client.js` and replace the value of `SUPABASE_ANON_KEY`
with the JWT key copied above.

### Step 3 — Run the SQL Schema

1. Go to **SQL Editor → New query**
2. Paste the entire contents of `sql/schema.sql`
3. Click **Run**
4. You should see: `NOTICE: Admin user created successfully. Login: admin / Admin@1998`

### Step 4 — Verify Storage Buckets

Go to **Storage** in Supabase Dashboard. You should see:
- `profile-pictures` (public)
- `resources` (public)
- `homework-images` (public)

If they don't appear, run just the storage section of `schema.sql` again.

### Step 5 — Deploy to GitHub Pages

See [Section 14](#14-github-pages-deployment).

### Step 6 — First Login

Go to `index.html` → Login tab → Username: `admin`, Password: `Admin@1998`

### Step 7 — Initial Configuration

1. **Admin → Settings** — fill in tuition name, address, contact, social links
2. **Admin → Subject Management** — verify/add subjects for your boards/classes
3. **Admin → Users** — create tuition students or upgrade existing Other Students

---

## 5. Authentication System

### How it works

Supabase Auth requires an email address. Since this system uses **username + password**
(no real email), usernames are mapped to synthetic emails:

```
username  →  username@tuition.local
```

This mapping happens in `shared/js/supabase-client.js`:
```js
function usernameToEmail(username) {
  return `${username.trim().toLowerCase()}@tuition.local`;
}
```

### Registration Flow (Other Student self-register)
```
1. User fills name, mobile, email(optional), username, password
2. Frontend checks username uniqueness in profiles table
3. sb.auth.signUp({ email: "username@tuition.local", password })
4. INSERT into profiles (auth_id, name, mobile, email, username, role='other_student')
5. Redirect to other/index.html
```

### Login Flow
```
1. User enters username + password
2. Frontend converts: "username@tuition.local"
3. sb.auth.signInWithPassword({ email, password })
4. SELECT from profiles WHERE auth_id = auth.uid()
5. Check status ≠ 'inactive'
6. Redirect based on role:
   admin           → admin/index.html
   tuition_student → student/index.html
   other_student   → other/index.html
```

### Route Guard
Every portal page calls `Auth.guard(requiredRole)` at load:
```js
const profile = await Auth.guard('tuition_student');
if (!profile) return; // already redirected
```
This handles: no session → login, wrong role → correct portal, inactive → login with message.

### Admin Creation
The admin user is inserted directly into `auth.users` via SQL (service-role context in
the SQL editor). Frontend JS cannot create other users without switching sessions.

### Password Reset Limitation
The anon-key JS client **cannot change another user's auth password**. Workarounds:
- **Admin generates a temporary password** (shown in UI) → tells the student offline
- **Admin sets the new password** in Supabase Dashboard → Auth → Users → "..." menu
- **Student changes their own password** via the profile page once they log in

---

## 6. Complete Database Schema

### `profiles` — Core identity table

| Column | Type | Description |
|---|---|---|
| `id` | uuid PK | Internal profile ID — **use this for all FK references** |
| `auth_id` | uuid FK → auth.users | Supabase Auth link |
| `name` | text | Full name |
| `mobile` | text | Mobile number |
| `email` | text | Optional, for communication only |
| `board` | text | `WBCHSE` or `CBSE` |
| `class` | text | `1st Semester`/`2nd Semester`/`3rd Semester`/`4th Semester` (WBCHSE) or `Class 11`/`Class 12` (CBSE) |
| `username` | text UNIQUE | Login username |
| `profile_picture` | text | Public URL from `profile-pictures` bucket |
| `role` | text | `admin` / `tuition_student` / `other_student` |
| `status` | text | `active` / `inactive` |
| `must_change_password` | boolean | True for new tuition students created by admin |
| `monthly_fee` | numeric(10,2) | Set when upgrading to tuition student |
| `admission_date` | date | Set when upgrading to tuition student |
| `created_at` | timestamptz | Auto-set |
| `updated_at` | timestamptz | Auto-updated via trigger |

### `subjects` — Subject catalogue

| Column | Type | Description |
|---|---|---|
| `id` | uuid PK | |
| `name` | text | e.g. "Accountancy" |
| `board` | text | `WBCHSE` / `CBSE` |
| `class` | text | Matches board's class values |
| `created_at` | timestamptz | |

**Seeded subjects** (22 combinations across both boards and all classes):
Accountancy, Economics, Business Studies, English, Mathematics

### `student_subjects` — Many-to-many: students ↔ subjects

| Column | Type | Description |
|---|---|---|
| `id` | uuid PK | |
| `student_id` | uuid FK → profiles.id | |
| `subject_id` | uuid FK → subjects.id | |
| `created_at` | timestamptz | |
| UNIQUE | (student_id, subject_id) | No duplicate assignments |

### `fee_records` — Monthly fee tracking

| Column | Type | Description |
|---|---|---|
| `id` | uuid PK | |
| `student_id` | uuid FK → profiles.id | |
| `month` | text | Format `YYYY-MM` e.g. `2026-06` |
| `amount_due` | numeric(10,2) | Copied from profiles.monthly_fee on generation |
| `amount_paid` | numeric(10,2) | Updated when payment recorded |
| `status` | text | `unpaid` / `partial` / `paid` (auto-computed on update) |
| `paid_on` | date | Date of payment |
| `remarks` | text | Admin notes |
| UNIQUE | (student_id, month) | One record per student per month |

**Future fields to add:** `late_fee`, `discount`, `receipt_number`, `payment_method`

### `homework` — Assigned homework

| Column | Type | Description |
|---|---|---|
| `id` | uuid PK | |
| `title` | text | |
| `description` | text | |
| `image_url` | text | From `homework-images` bucket |
| `board` | text | Target board |
| `class` | text | Target class |
| `subject_id` | uuid FK → subjects.id (nullable) | |
| `deadline` | timestamptz | Null = no deadline; past deadline = auto-hidden |
| `created_by` | uuid FK → profiles.id | Admin who created it |
| `created_at` | timestamptz | |

### `notices` — Announcements

| Column | Type | Description |
|---|---|---|
| `id` | uuid PK | |
| `title` | text | |
| `message` | text | |
| `target_type` | text | `all` / `board` / `class` / `user` |
| `target_board` | text | Used when type = `board` or `class` |
| `target_class` | text | Used when type = `class` |
| `target_user_id` | uuid FK → profiles.id | Used when type = `user` |
| `notice_date` | date | Display date |
| `created_by` | uuid FK → profiles.id | |
| `created_at` | timestamptz | |

### `notice_reads` — Read tracking

| Column | Type | Description |
|---|---|---|
| `id` | uuid PK | |
| `notice_id` | uuid FK → notices.id | |
| `user_id` | uuid FK → profiles.id | |
| `read_at` | timestamptz | |
| UNIQUE | (notice_id, user_id) | |

### `resources` — Uploaded files

| Column | Type | Description |
|---|---|---|
| `id` | uuid PK | |
| `title` | text | |
| `description` | text | |
| `file_url` | text | Public URL from `resources` bucket |
| `file_type` | text | MIME type or extension |
| `board` | text | |
| `class` | text | |
| `subject_id` | uuid FK → subjects.id (nullable) | |
| `visible_to_other_students` | boolean | If true, Other Students can access |
| `created_by` | uuid FK → profiles.id | |
| `created_at` | timestamptz | |

### `questions` — Question bank

| Column | Type | Description |
|---|---|---|
| `id` | uuid PK | |
| `question_code` | text UNIQUE | Auto-generated: `Q000001`, `Q000002`, … |
| `chapter` | text | Chapter name/number |
| `question` | text | Question text |
| `option_a` – `option_d` | text | Answer options |
| `correct_answer` | text | `A` / `B` / `C` / `D` |
| `explanation` | text | Shown after test submission |
| `subject_id` | uuid FK → subjects.id | |
| `class` | text | |
| `board` | text | |
| `created_at` | timestamptz | |

**Excel upload template columns (exact header names required):**
```
Question ID | Chapter | Question | Option A | Option B | Option C | Option D |
Correct Answer | Explanation | Subject | Class | Board
```
- `Question ID` — leave blank for auto-generation
- `Correct Answer` — must be exactly `A`, `B`, `C`, or `D`
- `Subject` — must match an existing `subjects.name` for the given `Board` + `Class`

### `tests` — Assembled test papers

| Column | Type | Description |
|---|---|---|
| `id` | uuid PK | |
| `title` | text | |
| `description` | text | |
| `board` | text | Target board |
| `class` | text | Target class |
| `subject_id` | uuid FK → subjects.id (nullable) | |
| `duration_minutes` | int | Timer hint (enforced in UI) |
| `visible_to_other_students` | boolean | |
| `created_by` | uuid FK → profiles.id | |
| `created_at` | timestamptz | |

### `test_questions` — Test ↔ Question join

| Column | Type | Description |
|---|---|---|
| `id` | uuid PK | |
| `test_id` | uuid FK → tests.id CASCADE | |
| `question_id` | uuid FK → questions.id CASCADE | |
| UNIQUE | (test_id, question_id) | |

### `test_attempts` — Student test submissions

| Column | Type | Description |
|---|---|---|
| `id` | uuid PK | |
| `test_id` | uuid FK → tests.id CASCADE | |
| `student_id` | uuid FK → profiles.id CASCADE | |
| `score` | numeric(6,2) | Percentage score |
| `answers` | jsonb | `{ "question_id": "A", ... }` |
| `submitted_at` | timestamptz | |

### `comments` — Feedback from Other Students

| Column | Type | Description |
|---|---|---|
| `id` | uuid PK | |
| `user_id` | uuid FK → profiles.id CASCADE | The Other Student |
| `message` | text | Student's comment |
| `reply` | text | Admin's reply |
| `replied_by` | uuid FK → profiles.id | Admin who replied |
| `replied_at` | timestamptz | |
| `created_at` | timestamptz | |

### `settings` — Singleton configuration row

| Column | Type | Description |
|---|---|---|
| `id` | int PK = 1 | Always 1 (singleton) |
| `tuition_address` | text | Full address |
| `contact_number` | text | Phone/WhatsApp number |
| `google_map_link` | text | Full maps.google.com URL |
| `facebook_link` | text | |
| `instagram_link` | text | |
| `youtube_link` | text | |
| `whatsapp_link` | text | e.g. `https://wa.me/91XXXXXXXXXX` |
| `updated_at` | timestamptz | |

---

## 7. Row Level Security (RLS)

All tables have RLS **enabled**. Security is enforced entirely in Postgres — the
frontend anon key cannot bypass these policies.

### Helper functions (used inside policies)
```sql
public.is_admin()          → boolean  (true if caller's profile.role = 'admin')
public.get_my_profile_id() → uuid     (caller's profiles.id)
public.get_my_role()       → text     (caller's profiles.role)
public.get_my_board()      → text     (caller's profiles.board)
public.get_my_class()      → text     (caller's profiles.class)
```

### Policy summary

| Table | Who can SELECT | Who can INSERT/UPDATE/DELETE |
|---|---|---|
| `profiles` | Own row OR admin | Own row (insert/update) · Admin (delete) |
| `subjects` | Everyone | Admin only |
| `student_subjects` | Own rows OR admin | Admin only |
| `fee_records` | Own rows OR admin | Admin only |
| `homework` | Admin OR matching board+class (non-expired) | Admin only |
| `notices` | Admin OR matching target | Admin only |
| `notice_reads` | Own rows OR admin | Own user_id only |
| `resources` | Admin OR matching board+class OR visible_to_other_students | Admin only |
| `questions` | Any authenticated user | Admin only |
| `tests` | Admin OR matching board+class OR visible_to_other_students | Admin only |
| `test_questions` | Any authenticated user | Admin only |
| `test_attempts` | Own rows OR admin | Own student_id only |
| `comments` | Own rows OR admin | Insert: own user_id · Update: admin · Delete: own OR admin |
| `settings` | Everyone | Admin only |

---

## 8. Storage Buckets

All three buckets are **public** (files are readable by anyone with the URL).

| Bucket | Max File Size | Allowed Types | Upload Permission |
|---|---|---|---|
| `profile-pictures` | 5 MB | JPEG, PNG, GIF, WEBP | Any authenticated user |
| `resources` | 50 MB | PDF, DOCX, DOC, ZIP, images | Admin only |
| `homework-images` | 10 MB | JPEG, PNG, GIF, WEBP | Admin only |

---

## 9. User Roles & Access Matrix

| Feature | Admin | Tuition Student | Other Student |
|---|---|---|---|
| Login (username/pwd) | ✅ | ✅ | ✅ |
| Self-registration | ❌ | ❌ | ✅ |
| View own profile | ✅ | ✅ | ✅ |
| Edit own profile/pic | ✅ | ✅ | ✅ |
| Change own password | ✅ | ✅ | ✅ |
| View all users | ✅ | ❌ | ❌ |
| Create/edit/delete users | ✅ | ❌ | ❌ |
| Upgrade Other → Tuition Student | ✅ | ❌ | ❌ |
| Manage subjects | ✅ | View only | View only |
| Generate / record fees | ✅ | ❌ | ❌ |
| View own fee history | — | ✅ | ❌ |
| Assign homework | ✅ | ❌ | ❌ |
| View homework | — | ✅ own board/class | ❌ |
| Post notices | ✅ | ❌ | ❌ |
| View notices | ✅ all | ✅ targeted | ✅ (all/user target only) |
| Upload resources | ✅ | ❌ | ❌ |
| View resources | ✅ | ✅ own board/class | ✅ if visible_to_other_students |
| Upload to question bank | ✅ (Excel) | ❌ | ❌ |
| Assemble/manage tests | ✅ | ❌ | ❌ |
| Take tests | — | ✅ own board/class | ✅ if visible_to_other_students |
| Submit comments | ❌ | ❌ | ✅ |
| View/reply/delete comments | ✅ | ❌ | Own only |
| Configure settings | ✅ | ❌ | ❌ |
| View tuition info/contact | ✅ | (add page if needed) | ✅ |

---

## 10. Admin Portal Guide

**URL**: `admin/index.html`  
**Shell**: Topbar + Hamburger sidebar + iframe content area  
**All pages load inside the iframe** — they are independent HTML files.

### Pages

| Menu Item | File | Key Features |
|---|---|---|
| Home | `pages/home.html` | 8 stat cards, recent registrations, recent fee collections |
| Users | `pages/users.html` | Full user table; view/edit/upgrade/deactivate/delete/reset password; create new tuition student |
| Subject Management | `pages/subjects.html` | Add/edit/delete subjects per board+class |
| Fee Management | `pages/fees.html` | Generate monthly fees for all tuition students; record payments |
| Homework | `pages/homework.html` | Create homework with board/class/subject targeting, optional image, deadline |
| Notice | `pages/notices.html` | Post to: all / board / class / specific user |
| Question Bank | `pages/tests.html` | Excel upload; per-subject/chapter stats; edit/delete individual questions |
| Test Assembly | `pages/test-assembly.html` | Create tests; select questions from bank; manage/remove questions; view test detail |
| Resource Upload | `pages/resources.html` | Upload files; control Other Student visibility |
| Comments | `pages/comments.html` | View all comments; reply; delete |
| Settings | `pages/settings.html` | Tuition info, social links, admin password change |

### Creating a Tuition Student

There are two paths:

**Path A — Upgrade an existing Other Student:**
1. Users → find the Other Student → click **Upgrade**
2. Fill in: Board, Class, Subjects (checkboxes), Monthly Fee, Admission Date
3. Click Upgrade — role changes to `tuition_student`

**Path B — Create a brand-new Tuition Student:**
1. Users → click **+ New Tuition Student**
2. Fill in: Name, Board, Class, Subjects, Monthly Fee, Admission Date, Username, Password
3. Click Create Student

> ⚠️ **Note on Path B**: `signUp()` switches the current session to the new student.
> After creating, you will be automatically logged out and must log back in as admin.
> This is a limitation of the anon-key-only approach. See Section 15 for the workaround.

### Generating Monthly Fees

1. Fee Management → select the month
2. Click **+ Generate This Month's Fees**
3. Creates one `fee_records` row per active tuition student (based on their `monthly_fee`)
4. Already-existing records for that month are skipped

---

## 11. Tuition Student Portal Guide

**URL**: `student/index.html`  
**Access**: After login with `role = tuition_student`

### First Login Experience
If `must_change_password = true` OR `mobile` is empty, the portal automatically
loads the **Profile** page with a banner prompting the student to complete their
profile and set a new password.

### Pages

| Menu Item | File | Key Features |
|---|---|---|
| Home | `pages/home.html` | Board/class display, this-month fee status, pending homework count, unread notice count, subjects list, recent notices preview |
| My Profile | `pages/profile.html` | Edit name/mobile/email, upload profile picture, change password, view assigned subjects |
| Homework | `pages/homework.html` | All non-expired homework for own board + class |
| Notices | `pages/notices.html` | Notices targeted to: all / own board / own class / this user; auto-marks as read |
| Fee Status | `pages/fees.html` | Monthly payment history table + total outstanding amount |
| Resources | `pages/resources.html` | Files for own board + class, filterable by subject |
| Tests | `pages/tests.html` | Available tests for own board + class; MCQ interface; instant score + explanation review |

---

## 12. Other Student Portal Guide

**URL**: `other/index.html`  
**Access**: After self-registration or login with `role = other_student`

### Pages

| Menu Item | File | Features |
|---|---|---|
| Home | `pages/home.html` | Welcome + all-target notices + visible resources |
| My Profile | `pages/profile.html` | Edit info, self-declare board/class, upload picture, change password |
| Notices | `pages/notices.html` | Notices for: all / their declared board+class / their user ID |
| Resources | `pages/resources.html` | Only resources with `visible_to_other_students = true` |
| Tests | `pages/tests.html` | Only tests with `visible_to_other_students = true` |
| Tuition Info | `pages/contact.html` | Address, phone, Google Maps link, social media buttons |
| Comments | `pages/comments.html` | Submit comments; view own comments + admin replies |

---

## 13. Building New Modules (Expansion Guide)

### How to add a new page to a portal

1. Create the file, e.g. `student/pages/attendance.html`
2. Copy this boilerplate header (adjust `base-path` depth):
```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<meta name="base-path" content="../../" />
<title>Attendance - Student</title>
<link rel="stylesheet" href="../../shared/css/styles.css" />
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
</head>
<body>
<div class="page">
  <h2>📅 Attendance</h2>
  <!-- your content here -->
</div>
<script src="../../shared/js/supabase-client.js"></script>
<script src="../../shared/js/auth.js"></script>
<script src="../../shared/js/utils.js"></script>
<script>
(async () => {
  const profile = await Auth.guard('tuition_student'); // or 'admin' / 'other_student'
  if (!profile) return;
  // your code here
})();
</script>
</body>
</html>
```

3. Add a sidebar link in `student/index.html`:
```html
<a data-page="pages/attendance.html"><span class="icon">📅</span> Attendance</a>
```

4. If you need a new table, add it to `sql/schema.sql` and run just that
   `CREATE TABLE` + RLS policy block in the Supabase SQL Editor.

### Board/Class values

These are defined in `shared/js/utils.js`:
```js
Utils.boardClasses = {
  WBCHSE: ["1st Semester", "2nd Semester", "3rd Semester", "4th Semester"],
  CBSE:   ["Class 11", "Class 12"]
};
```
To add a new board or class, update this object. It drives all dropdowns.

### Suggested future modules

| Module | Tables Needed | Notes |
|---|---|---|
| Attendance tracking | `attendance(id, student_id, date, status, created_by)` | Admin marks; student views |
| Fee receipts (PDF) | None | Generate from `fee_records` using jsPDF CDN |
| Test results dashboard | None (query test_attempts + profiles) | Per-subject/chapter analytics |
| Parent portal | `parent_students(parent_id, student_id)` | New role `parent` |
| Assignment submission | `submissions(homework_id, student_id, file_url, submitted_at)` | Students upload files |
| Push notifications | Supabase Edge Function | Requires server-side component |
| Live doubt session schedule | `sessions(id, title, date, link, board, class)` | Zoom/Google Meet links |

### Calling the Supabase API from pages

```js
// Select
const { data, error } = await sb
  .from('table_name')
  .select('*, foreign_table(col1, col2)')
  .eq('column', value)
  .order('created_at', { ascending: false })
  .limit(50);

// Insert
const { data, error } = await sb.from('table_name').insert({ col: val }).select().single();

// Update
const { error } = await sb.from('table_name').update({ col: val }).eq('id', id);

// Delete
const { error } = await sb.from('table_name').delete().eq('id', id);

// Upload file to storage
const { error } = await sb.storage.from('bucket-name').upload(fileName, file);
const { data } = sb.storage.from('bucket-name').getPublicUrl(fileName);
const url = data.publicUrl;
```

---

## 14. GitHub Pages Deployment

### Manual setup

1. Push the project to a GitHub repository (e.g. `main` branch, root `/`)
2. Go to **Settings → Pages → Source** → select branch `main`, folder `/ (root)` → Save
3. Wait ~2 minutes. GitHub provides: `https://<username>.github.io/<repo>/`
4. Test: `https://<username>.github.io/<repo>/index.html`

### Automatic deploy (GitHub Actions)

The file `.github/workflows/deploy.yml` is included. It auto-deploys on every
push to `main`. To enable:
1. Repo → **Settings → Pages → Source** → select **GitHub Actions**
2. Push any change to `main` — deployment runs automatically

### Supabase Auth allowed URLs

After deploying, go to Supabase Dashboard → **Authentication → URL Configuration**:
- **Site URL**: `https://<username>.github.io/<repo>`
- **Redirect URLs**: add `https://<username>.github.io/<repo>/**`

This is not strictly required for username/password auth (no email links are sent)
but is good practice for future-proofing.

### Important: disable email confirmation

Supabase → Authentication → Providers → Email:
- **Confirm email** → OFF
- **Secure email change** → OFF

Required because `@tuition.local` emails cannot receive real messages.

---

## 15. Known Limitations & Workarounds

### 1. Admin-created Tuition Students cause session switch

**Problem**: `sb.auth.signUp()` in the browser logs in as the newly created user,
logging out the admin.

**Current workaround**: After creating a student, the admin is logged out
automatically and must log back in.

**Future solution**: Create a Supabase Edge Function using the **service role key**
(never expose this in frontend code) that calls the Admin API to create users
without affecting the caller's session. Example:
```
POST /functions/v1/create-user
Body: { username, password, name, board, class, subjects, monthly_fee, admission_date }
Authorization: Bearer <user_jwt>  (function verifies caller is admin)
```

### 2. Password resets by admin require the Dashboard

**Problem**: The anon-key JS client cannot update another user's `auth.users` password.

**Workaround**:
- Admin uses the "Reset Password" UI → generates a temporary password → communicates
  it to the student offline
- Admin then goes to Supabase Dashboard → Auth → Users → find the user →
  "..." menu → set the new password manually
- The `must_change_password` flag is set on the profile to prompt the student
  to change it on next login

### 3. Excel upload requires CDN (SheetJS)

The question bank Excel upload depends on `https://cdn.jsdelivr.net/npm/xlsx@0.18.5`.
If this CDN is unavailable, the upload button won't work. The rest of the system
functions normally. Questions can still be added one by one through the edit
interface (future enhancement).

### 4. Test "duration" is advisory only

The `duration_minutes` field is stored and displayed but the test pages do not
enforce a countdown timer that auto-submits. Adding a countdown timer is a
straightforward future enhancement using `setInterval` and `sessionStorage`.

### 5. `notice_reads` upsert on revisit

When a student revisits the notices page, the code tries to insert read records
for notices that are already marked read (which would fail the `unique` constraint).
The code handles this with a `.catch(() => {})` — silent failure on duplicate inserts.
A cleaner solution uses `.upsert()` or filters out already-read IDs before inserting.

---

*Last updated: June 2026 — v2.0*
