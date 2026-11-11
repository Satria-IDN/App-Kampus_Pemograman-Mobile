-- ============================================================
-- Seed demo dashboard mahasiswa (CampusPulse)
-- Jalankan di Supabase SQL Editor. Bagian A dan B aman diulang,
-- bagian C cukup dijalankan SATU KALI (membuat sesi riwayat).
-- ============================================================

-- A. KRS: semua mahasiswa mengambil 3 matkul uji
insert into public.enrollments (student_id, course_id)
select p.id, c.id
from public.profiles p
cross join public.courses c
where p.role = 'mahasiswa'
  and c.course_code in ('IF401', 'IF402', 'IF403')
on conflict do nothing;

-- B. Jadwal mingguan (day_of_week: 1 = Senin ... 7 = Minggu)
--    Sesuaikan hari/jam agar ada kuliah pada hari demo.
create unique index if not exists course_schedules_unique
  on public.course_schedules (course_id, day_of_week, start_time);

insert into public.course_schedules (course_id, day_of_week, start_time, end_time)
select c.id, v.dow, v.st::time, v.et::time
from public.courses c
join (values
  ('IF401', 6, '08:00', '10:30'),
  ('IF402', 1, '10:00', '12:30'),
  ('IF403', 3, '13:00', '15:30')
) as v(code, dow, st, et) on v.code = c.course_code
on conflict do nothing;

-- C. Skenario "Bahaya Alpa" untuk IF403: 3 pertemuan lalu sudah ditutup.
--    Mahasiswa 20240801248 hanya hadir 1x -> 2 alpa -> kartu merah.
--    Mahasiswa 20240801048 hadir 3x -> aman.
with s as (
  insert into public.class_sessions
    (course_id, course_code, course_name, room_name, session_type,
     target_lat, target_lng, radius_meter, is_active, started_at, ended_at, lecturer_id)
  select c.id, c.course_code, c.course_name, coalesce(r.room_name, '-'), 'reguler',
         coalesce(r.latitude, 0), coalesce(r.longitude, 0), 50, false,
         now() - make_interval(days => n),
         now() - make_interval(days => n) + interval '2 hours',
         c.lecturer_id
  from public.courses c
  left join public.rooms r on r.id = c.room_id
  cross join generate_series(7, 21, 7) as n
  where c.course_code = 'IF403'
  returning id, started_at
),
hadir_terakhir as (
  insert into public.attendance_logs (session_id, student_id, status, verified_distance, scanned_at)
  select s.id, p.id, 'Hadir', 12, s.started_at + interval '5 minutes'
  from s
  cross join public.profiles p
  where p.identifier_id = '20240801248'
    and s.started_at = (select max(started_at) from s)
  returning 1
)
insert into public.attendance_logs (session_id, student_id, status, verified_distance, scanned_at)
select s.id, p.id, 'Hadir', 10, s.started_at + interval '5 minutes'
from s
cross join public.profiles p
where p.identifier_id = '20240801048';
