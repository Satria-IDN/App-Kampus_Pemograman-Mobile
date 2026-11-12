-- ============================================================
-- Dispensasi (izin / sakit): tabel + penyimpanan lampiran privat
-- Jalankan SEKALI di Supabase SQL Editor.
-- ============================================================

create table if not exists public.dispensations (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  absence_date date not null,
  type text not null check (type in ('izin', 'sakit')),
  reason text not null,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  reviewer_note text,
  document_path text,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

-- Satu pengajuan aktif per mahasiswa, matkul, dan tanggal (yang ditolak boleh diajukan ulang)
create unique index if not exists dispensations_active_unique
  on public.dispensations (student_id, course_id, absence_date)
  where status <> 'rejected';

create index if not exists dispensations_course_status
  on public.dispensations (course_id, status);

-- Bucket privat untuk lampiran foto surat
insert into storage.buckets (id, name, public)
values ('dispensations', 'dispensations', false)
on conflict (id) do nothing;

drop policy if exists "dispensations_upload" on storage.objects;
create policy "dispensations_upload" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'dispensations');

drop policy if exists "dispensations_read" on storage.objects;
create policy "dispensations_read" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'dispensations');
