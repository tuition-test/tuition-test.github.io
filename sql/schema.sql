-- =====================================================================
-- TUITION MANAGEMENT SYSTEM — COMPLETE SUPABASE SQL SCHEMA
-- Version: 2.0
-- =====================================================================
-- HOW TO RUN:
--   Supabase Dashboard → SQL Editor → New query → paste all → Run
--   This script is idempotent; safe to re-run.
--
-- BEFORE RUNNING:
--   1. Go to Auth → Providers → Email → DISABLE "Confirm email"
--   2. Go to Auth → Providers → Email → DISABLE "Secure email change"
--   This is required because we use synthetic emails (@tuition.local)
--   that cannot receive real confirmation messages.
-- =====================================================================

-- ---------------------------------------------------------------------
-- EXTENSIONS
-- ---------------------------------------------------------------------
create extension if not exists "pgcrypto";
create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------------------
-- HELPER: Updated-at trigger function
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =====================================================================
-- 1. PROFILES
-- =====================================================================
create table if not exists public.profiles (
  id               uuid primary key default gen_random_uuid(),
  auth_id          uuid unique references auth.users(id) on delete cascade,
  name             text not null,
  mobile           text,
  email            text,
  board            text check (board in ('WBCHSE','CBSE')),
  class            text,
  username         text unique not null,
  profile_picture  text,
  role             text not null default 'other_student'
                     check (role in ('admin','tuition_student','other_student')),
  status           text not null default 'active'
                     check (status in ('active','inactive')),
  must_change_password boolean not null default false,
  monthly_fee      numeric(10,2) default 0,
  admission_date   date,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index if not exists idx_profiles_role      on public.profiles(role);
create index if not exists idx_profiles_board_cls on public.profiles(board, class);
create index if not exists idx_profiles_username  on public.profiles(username);
create index if not exists idx_profiles_auth_id   on public.profiles(auth_id);

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- =====================================================================
-- 2. SUBJECTS
-- =====================================================================
create table if not exists public.subjects (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  board      text check (board in ('WBCHSE','CBSE')),
  class      text,
  created_at timestamptz not null default now()
);

create index if not exists idx_subjects_board_class on public.subjects(board, class);

-- =====================================================================
-- 3. STUDENT SUBJECTS (many-to-many)
-- =====================================================================
create table if not exists public.student_subjects (
  id         uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(student_id, subject_id)
);

-- =====================================================================
-- 4. FEE RECORDS
-- =====================================================================
create table if not exists public.fee_records (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid not null references public.profiles(id) on delete cascade,
  month       text not null,           -- 'YYYY-MM'
  amount_due  numeric(10,2) not null default 0,
  amount_paid numeric(10,2) not null default 0,
  status      text not null default 'unpaid'
                check (status in ('unpaid','partial','paid')),
  paid_on     date,
  remarks     text,
  created_at  timestamptz not null default now(),
  unique(student_id, month)
);

create index if not exists idx_fee_student on public.fee_records(student_id);
create index if not exists idx_fee_month   on public.fee_records(month);

-- =====================================================================
-- 5. HOMEWORK
-- =====================================================================
create table if not exists public.homework (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  description text,
  image_url   text,
  board       text check (board in ('WBCHSE','CBSE')),
  class       text,
  subject_id  uuid references public.subjects(id) on delete set null,
  deadline    timestamptz,
  created_by  uuid references public.profiles(id) on delete set null,
  created_at  timestamptz not null default now()
);

create index if not exists idx_homework_board_class on public.homework(board, class);
create index if not exists idx_homework_deadline    on public.homework(deadline);

-- =====================================================================
-- 6. NOTICES + READ TRACKING
-- =====================================================================
create table if not exists public.notices (
  id              uuid primary key default gen_random_uuid(),
  title           text not null,
  message         text not null,
  target_type     text not null default 'all'
                    check (target_type in ('all','board','class','user')),
  target_board    text check (target_board in ('WBCHSE','CBSE')),
  target_class    text,
  target_user_id  uuid references public.profiles(id) on delete cascade,
  notice_date     date not null default current_date,
  created_by      uuid references public.profiles(id) on delete set null,
  created_at      timestamptz not null default now()
);

create table if not exists public.notice_reads (
  id         uuid primary key default gen_random_uuid(),
  notice_id  uuid not null references public.notices(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  read_at    timestamptz not null default now(),
  unique(notice_id, user_id)
);

-- =====================================================================
-- 7. RESOURCES
-- =====================================================================
create table if not exists public.resources (
  id                         uuid primary key default gen_random_uuid(),
  title                      text not null,
  description                text,
  file_url                   text not null,
  file_type                  text,
  board                      text check (board in ('WBCHSE','CBSE')),
  class                      text,
  subject_id                 uuid references public.subjects(id) on delete set null,
  visible_to_other_students  boolean not null default false,
  created_by                 uuid references public.profiles(id) on delete set null,
  created_at                 timestamptz not null default now()
);

create index if not exists idx_resources_board_class    on public.resources(board, class);
create index if not exists idx_resources_visible_other  on public.resources(visible_to_other_students);

-- =====================================================================
-- 8. QUESTION BANK
-- =====================================================================
create sequence if not exists public.question_code_seq start 1;

create table if not exists public.questions (
  id              uuid primary key default gen_random_uuid(),
  question_code   text unique,         -- auto-generated as Q000001 …
  chapter         text,
  question        text not null,
  option_a        text,
  option_b        text,
  option_c        text,
  option_d        text,
  correct_answer  text check (correct_answer in ('A','B','C','D')),
  explanation     text,
  subject_id      uuid references public.subjects(id) on delete set null,
  class           text,
  board           text check (board in ('WBCHSE','CBSE')),
  created_at      timestamptz not null default now()
);

create index if not exists idx_questions_subject on public.questions(subject_id);
create index if not exists idx_questions_chapter on public.questions(chapter);
create index if not exists idx_questions_board   on public.questions(board, class);

create or replace function public.generate_question_code()
returns trigger language plpgsql as $$
begin
  if new.question_code is null or new.question_code = '' then
    new.question_code := 'Q' || lpad(nextval('public.question_code_seq')::text, 6, '0');
  end if;
  return new;
end;
$$;

drop trigger if exists trg_question_code on public.questions;
create trigger trg_question_code
before insert on public.questions
for each row execute function public.generate_question_code();

-- =====================================================================
-- 9. TESTS (assembled from question bank)
-- =====================================================================
create table if not exists public.tests (
  id                        uuid primary key default gen_random_uuid(),
  title                     text not null,
  description               text,
  board                     text check (board in ('WBCHSE','CBSE')),
  class                     text,
  subject_id                uuid references public.subjects(id) on delete set null,
  duration_minutes          int default 30,
  visible_to_other_students boolean not null default false,
  created_by                uuid references public.profiles(id) on delete set null,
  created_at                timestamptz not null default now()
);

create table if not exists public.test_questions (
  id          uuid primary key default gen_random_uuid(),
  test_id     uuid not null references public.tests(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  unique(test_id, question_id)
);

create table if not exists public.test_attempts (
  id           uuid primary key default gen_random_uuid(),
  test_id      uuid not null references public.tests(id) on delete cascade,
  student_id   uuid not null references public.profiles(id) on delete cascade,
  score        numeric(6,2),
  answers      jsonb,
  submitted_at timestamptz default now()
);

create index if not exists idx_test_attempts_student on public.test_attempts(student_id);
create index if not exists idx_test_attempts_test    on public.test_attempts(test_id);

-- =====================================================================
-- 10. COMMENTS
-- =====================================================================
create table if not exists public.comments (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  message     text not null,
  reply       text,
  replied_by  uuid references public.profiles(id) on delete set null,
  replied_at  timestamptz,
  created_at  timestamptz not null default now()
);

create index if not exists idx_comments_user on public.comments(user_id);

-- =====================================================================
-- 11. SETTINGS (single-row, key-value style)
-- =====================================================================
create table if not exists public.settings (
  id               int primary key default 1,
  tuition_address  text,
  contact_number   text,
  google_map_link  text,
  facebook_link    text,
  instagram_link   text,
  youtube_link     text,
  whatsapp_link    text,
  updated_at       timestamptz default now(),
  constraint settings_singleton check (id = 1)
);

insert into public.settings (id)
values (1)
on conflict (id) do nothing;

-- =====================================================================
-- HELPER FUNCTIONS (used inside RLS policies)
-- =====================================================================
create or replace function public.get_my_profile_id()
returns uuid language sql stable security definer as $$
  select id from public.profiles where auth_id = auth.uid() limit 1;
$$;

create or replace function public.get_my_role()
returns text language sql stable security definer as $$
  select role from public.profiles where auth_id = auth.uid() limit 1;
$$;

create or replace function public.get_my_board()
returns text language sql stable security definer as $$
  select board from public.profiles where auth_id = auth.uid() limit 1;
$$;

create or replace function public.get_my_class()
returns text language sql stable security definer as $$
  select class from public.profiles where auth_id = auth.uid() limit 1;
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer as $$
  select exists(
    select 1 from public.profiles
    where auth_id = auth.uid() and role = 'admin'
  );
$$;

-- =====================================================================
-- ROW LEVEL SECURITY
-- =====================================================================
alter table public.profiles         enable row level security;
alter table public.subjects         enable row level security;
alter table public.student_subjects enable row level security;
alter table public.fee_records      enable row level security;
alter table public.homework         enable row level security;
alter table public.notices          enable row level security;
alter table public.notice_reads     enable row level security;
alter table public.resources        enable row level security;
alter table public.questions        enable row level security;
alter table public.tests            enable row level security;
alter table public.test_questions   enable row level security;
alter table public.test_attempts    enable row level security;
alter table public.comments         enable row level security;
alter table public.settings         enable row level security;

-- ---------------------------------------------------------------
-- PROFILES
-- ---------------------------------------------------------------
drop policy if exists "profiles: select own or admin"  on public.profiles;
drop policy if exists "profiles: insert own or admin"  on public.profiles;
drop policy if exists "profiles: update own or admin"  on public.profiles;
drop policy if exists "profiles: delete admin only"    on public.profiles;

create policy "profiles: select own or admin"
  on public.profiles for select
  using ( auth_id = auth.uid() or public.is_admin() );

create policy "profiles: insert own or admin"
  on public.profiles for insert
  with check ( auth_id = auth.uid() or public.is_admin() );

create policy "profiles: update own or admin"
  on public.profiles for update
  using ( auth_id = auth.uid() or public.is_admin() )
  with check ( auth_id = auth.uid() or public.is_admin() );

create policy "profiles: delete admin only"
  on public.profiles for delete
  using ( public.is_admin() );

-- ---------------------------------------------------------------
-- SUBJECTS (public read; admin write)
-- ---------------------------------------------------------------
drop policy if exists "subjects: all can read"   on public.subjects;
drop policy if exists "subjects: admin insert"   on public.subjects;
drop policy if exists "subjects: admin update"   on public.subjects;
drop policy if exists "subjects: admin delete"   on public.subjects;

create policy "subjects: all can read"  on public.subjects for select using (true);
create policy "subjects: admin insert"  on public.subjects for insert with check ( public.is_admin() );
create policy "subjects: admin update"  on public.subjects for update using ( public.is_admin() );
create policy "subjects: admin delete"  on public.subjects for delete using ( public.is_admin() );

-- ---------------------------------------------------------------
-- STUDENT SUBJECTS
-- ---------------------------------------------------------------
drop policy if exists "student_subjects: select own or admin" on public.student_subjects;
drop policy if exists "student_subjects: admin insert"        on public.student_subjects;
drop policy if exists "student_subjects: admin update"        on public.student_subjects;
drop policy if exists "student_subjects: admin delete"        on public.student_subjects;

create policy "student_subjects: select own or admin"
  on public.student_subjects for select
  using ( public.is_admin() or student_id = public.get_my_profile_id() );

create policy "student_subjects: admin insert"  on public.student_subjects for insert with check ( public.is_admin() );
create policy "student_subjects: admin update"  on public.student_subjects for update using ( public.is_admin() );
create policy "student_subjects: admin delete"  on public.student_subjects for delete using ( public.is_admin() );

-- ---------------------------------------------------------------
-- FEE RECORDS
-- ---------------------------------------------------------------
drop policy if exists "fee_records: select own or admin" on public.fee_records;
drop policy if exists "fee_records: admin insert"        on public.fee_records;
drop policy if exists "fee_records: admin update"        on public.fee_records;
drop policy if exists "fee_records: admin delete"        on public.fee_records;

create policy "fee_records: select own or admin"
  on public.fee_records for select
  using ( public.is_admin() or student_id = public.get_my_profile_id() );

create policy "fee_records: admin insert" on public.fee_records for insert with check ( public.is_admin() );
create policy "fee_records: admin update" on public.fee_records for update using ( public.is_admin() );
create policy "fee_records: admin delete" on public.fee_records for delete using ( public.is_admin() );

-- ---------------------------------------------------------------
-- HOMEWORK
-- ---------------------------------------------------------------
drop policy if exists "homework: student select" on public.homework;
drop policy if exists "homework: admin insert"   on public.homework;
drop policy if exists "homework: admin update"   on public.homework;
drop policy if exists "homework: admin delete"   on public.homework;

create policy "homework: student select"
  on public.homework for select
  using (
    public.is_admin()
    or (
      board = public.get_my_board()
      and class = public.get_my_class()
      and (deadline is null or deadline >= now())
    )
  );

create policy "homework: admin insert" on public.homework for insert with check ( public.is_admin() );
create policy "homework: admin update" on public.homework for update using ( public.is_admin() );
create policy "homework: admin delete" on public.homework for delete using ( public.is_admin() );

-- ---------------------------------------------------------------
-- NOTICES
-- ---------------------------------------------------------------
drop policy if exists "notices: targeted select" on public.notices;
drop policy if exists "notices: admin insert"    on public.notices;
drop policy if exists "notices: admin update"    on public.notices;
drop policy if exists "notices: admin delete"    on public.notices;

create policy "notices: targeted select"
  on public.notices for select
  using (
    public.is_admin()
    or target_type = 'all'
    or (target_type = 'board'  and target_board = public.get_my_board())
    or (target_type = 'class'  and target_board = public.get_my_board()
                                and target_class = public.get_my_class())
    or (target_type = 'user'   and target_user_id = public.get_my_profile_id())
  );

create policy "notices: admin insert" on public.notices for insert with check ( public.is_admin() );
create policy "notices: admin update" on public.notices for update using ( public.is_admin() );
create policy "notices: admin delete" on public.notices for delete using ( public.is_admin() );

-- ---------------------------------------------------------------
-- NOTICE READS
-- ---------------------------------------------------------------
drop policy if exists "notice_reads: select own or admin" on public.notice_reads;
drop policy if exists "notice_reads: insert own"          on public.notice_reads;
drop policy if exists "notice_reads: update own"          on public.notice_reads;

create policy "notice_reads: select own or admin"
  on public.notice_reads for select
  using ( public.is_admin() or user_id = public.get_my_profile_id() );

create policy "notice_reads: insert own"
  on public.notice_reads for insert
  with check ( user_id = public.get_my_profile_id() );

create policy "notice_reads: update own"
  on public.notice_reads for update
  using ( user_id = public.get_my_profile_id() );

-- ---------------------------------------------------------------
-- RESOURCES
-- ---------------------------------------------------------------
drop policy if exists "resources: select filtered" on public.resources;
drop policy if exists "resources: admin insert"    on public.resources;
drop policy if exists "resources: admin update"    on public.resources;
drop policy if exists "resources: admin delete"    on public.resources;

create policy "resources: select filtered"
  on public.resources for select
  using (
    public.is_admin()
    or (visible_to_other_students = true and public.get_my_role() = 'other_student')
    or (board = public.get_my_board() and class = public.get_my_class())
  );

create policy "resources: admin insert" on public.resources for insert with check ( public.is_admin() );
create policy "resources: admin update" on public.resources for update using ( public.is_admin() );
create policy "resources: admin delete" on public.resources for delete using ( public.is_admin() );

-- ---------------------------------------------------------------
-- QUESTIONS (public read for authenticated users; admin write)
-- ---------------------------------------------------------------
drop policy if exists "questions: auth read"   on public.questions;
drop policy if exists "questions: admin insert" on public.questions;
drop policy if exists "questions: admin update" on public.questions;
drop policy if exists "questions: admin delete" on public.questions;

create policy "questions: auth read"    on public.questions for select using ( auth.uid() is not null );
create policy "questions: admin insert" on public.questions for insert with check ( public.is_admin() );
create policy "questions: admin update" on public.questions for update using ( public.is_admin() );
create policy "questions: admin delete" on public.questions for delete using ( public.is_admin() );

-- ---------------------------------------------------------------
-- TESTS
-- ---------------------------------------------------------------
drop policy if exists "tests: select filtered" on public.tests;
drop policy if exists "tests: admin insert"    on public.tests;
drop policy if exists "tests: admin update"    on public.tests;
drop policy if exists "tests: admin delete"    on public.tests;

create policy "tests: select filtered"
  on public.tests for select
  using (
    public.is_admin()
    or (visible_to_other_students = true)
    or (board = public.get_my_board() and class = public.get_my_class())
  );

create policy "tests: admin insert" on public.tests for insert with check ( public.is_admin() );
create policy "tests: admin update" on public.tests for update using ( public.is_admin() );
create policy "tests: admin delete" on public.tests for delete using ( public.is_admin() );

-- ---------------------------------------------------------------
-- TEST QUESTIONS
-- ---------------------------------------------------------------
drop policy if exists "test_questions: auth read"    on public.test_questions;
drop policy if exists "test_questions: admin insert" on public.test_questions;
drop policy if exists "test_questions: admin delete" on public.test_questions;

create policy "test_questions: auth read"    on public.test_questions for select using ( auth.uid() is not null );
create policy "test_questions: admin insert" on public.test_questions for insert with check ( public.is_admin() );
create policy "test_questions: admin delete" on public.test_questions for delete using ( public.is_admin() );

-- ---------------------------------------------------------------
-- TEST ATTEMPTS
-- ---------------------------------------------------------------
drop policy if exists "test_attempts: select own or admin" on public.test_attempts;
drop policy if exists "test_attempts: insert own"          on public.test_attempts;

create policy "test_attempts: select own or admin"
  on public.test_attempts for select
  using ( public.is_admin() or student_id = public.get_my_profile_id() );

create policy "test_attempts: insert own"
  on public.test_attempts for insert
  with check ( student_id = public.get_my_profile_id() );

-- ---------------------------------------------------------------
-- COMMENTS
-- ---------------------------------------------------------------
drop policy if exists "comments: select own or admin" on public.comments;
drop policy if exists "comments: insert own"          on public.comments;
drop policy if exists "comments: update admin"        on public.comments;
drop policy if exists "comments: delete own or admin" on public.comments;

create policy "comments: select own or admin"
  on public.comments for select
  using ( public.is_admin() or user_id = public.get_my_profile_id() );

create policy "comments: insert own"
  on public.comments for insert
  with check ( user_id = public.get_my_profile_id() );

create policy "comments: update admin"
  on public.comments for update using ( public.is_admin() );

create policy "comments: delete own or admin"
  on public.comments for delete
  using ( public.is_admin() or user_id = public.get_my_profile_id() );

-- ---------------------------------------------------------------
-- SETTINGS
-- ---------------------------------------------------------------
drop policy if exists "settings: all read"    on public.settings;
drop policy if exists "settings: admin write" on public.settings;

create policy "settings: all read"    on public.settings for select using (true);
create policy "settings: admin write" on public.settings for update using ( public.is_admin() );

-- =====================================================================
-- STORAGE BUCKETS
-- =====================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('profile-pictures', 'profile-pictures', true, 5242880,
   '{image/jpeg,image/png,image/gif,image/webp}'),
  ('resources', 'resources', true, 52428800,
   '{application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/zip,image/jpeg,image/png,image/gif,image/webp}'),
  ('homework-images', 'homework-images', true, 10485760,
   '{image/jpeg,image/png,image/gif,image/webp}')
on conflict (id) do nothing;

-- Storage RLS
drop policy if exists "profile_pictures: public read"  on storage.objects;
drop policy if exists "profile_pictures: auth upload"  on storage.objects;
drop policy if exists "profile_pictures: owner update" on storage.objects;
drop policy if exists "resources: public read"         on storage.objects;
drop policy if exists "resources: admin upload"        on storage.objects;
drop policy if exists "resources: admin delete"        on storage.objects;
drop policy if exists "homework_images: public read"   on storage.objects;
drop policy if exists "homework_images: admin upload"  on storage.objects;
drop policy if exists "homework_images: admin delete"  on storage.objects;

create policy "profile_pictures: public read"
  on storage.objects for select using ( bucket_id = 'profile-pictures' );
create policy "profile_pictures: auth upload"
  on storage.objects for insert
  with check ( bucket_id = 'profile-pictures' and auth.uid() is not null );
create policy "profile_pictures: owner update"
  on storage.objects for update
  using ( bucket_id = 'profile-pictures' and auth.uid() is not null );

create policy "resources: public read"
  on storage.objects for select using ( bucket_id = 'resources' );
create policy "resources: admin upload"
  on storage.objects for insert
  with check ( bucket_id = 'resources' and public.is_admin() );
create policy "resources: admin delete"
  on storage.objects for delete
  using ( bucket_id = 'resources' and public.is_admin() );

create policy "homework_images: public read"
  on storage.objects for select using ( bucket_id = 'homework-images' );
create policy "homework_images: admin upload"
  on storage.objects for insert
  with check ( bucket_id = 'homework-images' and public.is_admin() );
create policy "homework_images: admin delete"
  on storage.objects for delete
  using ( bucket_id = 'homework-images' and public.is_admin() );

-- =====================================================================
-- SEED: SUBJECTS
-- =====================================================================
insert into public.subjects (name, board, class) values
  -- CBSE
  ('Accountancy',     'CBSE', 'Class 11'),
  ('Accountancy',     'CBSE', 'Class 12'),
  ('Economics',       'CBSE', 'Class 11'),
  ('Economics',       'CBSE', 'Class 12'),
  ('Business Studies','CBSE', 'Class 11'),
  ('Business Studies','CBSE', 'Class 12'),
  ('English',         'CBSE', 'Class 11'),
  ('English',         'CBSE', 'Class 12'),
  ('Mathematics',     'CBSE', 'Class 11'),
  ('Mathematics',     'CBSE', 'Class 12'),
  -- WBCHSE
  ('Accountancy',     'WBCHSE', '1st Semester'),
  ('Accountancy',     'WBCHSE', '2nd Semester'),
  ('Accountancy',     'WBCHSE', '3rd Semester'),
  ('Accountancy',     'WBCHSE', '4th Semester'),
  ('Economics',       'WBCHSE', '1st Semester'),
  ('Economics',       'WBCHSE', '2nd Semester'),
  ('Economics',       'WBCHSE', '3rd Semester'),
  ('Economics',       'WBCHSE', '4th Semester'),
  ('Business Studies','WBCHSE', '1st Semester'),
  ('Business Studies','WBCHSE', '2nd Semester'),
  ('Business Studies','WBCHSE', '3rd Semester'),
  ('Business Studies','WBCHSE', '4th Semester'),
  ('English',         'WBCHSE', '1st Semester'),
  ('English',         'WBCHSE', '2nd Semester'),
  ('English',         'WBCHSE', '3rd Semester'),
  ('English',         'WBCHSE', '4th Semester'),
  ('Mathematics',     'WBCHSE', '1st Semester'),
  ('Mathematics',     'WBCHSE', '2nd Semester'),
  ('Mathematics',     'WBCHSE', '3rd Semester'),
  ('Mathematics',     'WBCHSE', '4th Semester')
on conflict do nothing;

-- =====================================================================
-- CREATE PRIMARY ADMIN USER
-- =====================================================================
-- Username: admin   Password: Admin@1998
-- Synthetic email:  admin@tuition.local
--
-- NOTE: This inserts directly into auth.users which is only possible
-- from the SQL editor (service role context). It will not work from
-- the frontend JS client.
-- =====================================================================
do $$
declare
  v_uid  uuid;
  v_now  timestamptz := now();
begin
  -- Skip if admin already exists
  if exists (select 1 from auth.users where email = 'admin@tuition.local') then
    raise notice 'Admin user already exists, skipping creation.';
    return;
  end if;

  v_uid := gen_random_uuid();

  insert into auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at,
    last_sign_in_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) values (
    v_uid,
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'admin@tuition.local',
    crypt('Admin@1998', gen_salt('bf')),
    v_now,
    '{"provider":"email","providers":["email"]}',
    '{}',
    false,
    v_now,
    v_now,
    v_now,
    '',
    '',
    '',
    ''
  );

  insert into auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at,
    provider_id
  ) values (
    gen_random_uuid(),
    v_uid,
    jsonb_build_object('sub', v_uid::text, 'email', 'admin@tuition.local'),
    'email',
    v_now,
    v_now,
    v_now,
    v_uid::text
  );

  insert into public.profiles (
    auth_id, name, username, role, status, must_change_password
  ) values (
    v_uid, 'Administrator', 'admin', 'admin', 'active', false
  );

  raise notice 'Admin user created successfully. Login: admin / Admin@1998';
end;
$$;

-- =====================================================================
-- END OF SCHEMA — Run complete, all objects created.
-- =====================================================================
