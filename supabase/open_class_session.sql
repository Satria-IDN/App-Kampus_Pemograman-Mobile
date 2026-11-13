-- ============================================================
-- Aturan buka sesi: hanya pada hari dan jam kuliah sesuai jadwal.
-- Jalankan SEKALI di Supabase SQL Editor (aman diulang).
-- Memakai jam server zona WIB (Asia/Jakarta), jadi tidak bisa
-- dilewati dengan mengubah jam HP dosen.
--
-- Sesi boleh dibuka mulai 15 menit sebelum jam mulai sampai jam selesai.
-- Untuk mengubah toleransi, ganti '15 minutes' di bawah.
-- ============================================================

create or replace function public.open_class_session(
  p_course_id uuid,
  p_lecturer_id uuid,
  p_session_type text default 'reguler'
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_course   record;
  v_room     record;
  v_existing record;
  v_session  record;
  v_now      timestamp := (now() at time zone 'Asia/Jakarta');
  v_dow      int       := extract(isodow from (now() at time zone 'Asia/Jakarta'))::int;
  v_time     time      := (now() at time zone 'Asia/Jakarta')::time;
  v_type     text      := lower(coalesce(p_session_type, 'reguler'));
  v_has_any  boolean;
  v_in_slot  boolean;
  v_slots    text;
begin
  select * into v_course from courses where id = p_course_id;
  if not found then
    return json_build_object('success', false, 'message', 'Mata kuliah tidak ditemukan.');
  end if;

  if v_course.lecturer_id is distinct from p_lecturer_id then
    return json_build_object('success', false, 'message', 'Anda bukan dosen pengampu mata kuliah ini.');
  end if;

  if v_type not in ('reguler', 'workshop', 'kuliah_tamu') then
    v_type := 'reguler';
  end if;

  -- Sesi yang masih aktif selalu boleh dilanjutkan (misalnya untuk menutupnya)
  select * into v_existing
  from class_sessions
  where course_id = p_course_id and is_active = true
  order by created_at desc
  limit 1;

  if found then
    return json_build_object('success', true, 'session', to_jsonb(v_existing));
  end if;

  -- Aturan hari + jam sesuai jadwal
  select exists(select 1 from course_schedules where course_id = p_course_id)
    into v_has_any;

  if not v_has_any then
    return json_build_object('success', false,
      'message', 'Jadwal mata kuliah belum diatur. Hubungi admin.');
  end if;

  select exists(
    select 1 from course_schedules s
    where s.course_id = p_course_id
      and s.day_of_week = v_dow
      and v_time >= (s.start_time - interval '15 minutes')
      and v_time <= s.end_time
  ) into v_in_slot;

  if not v_in_slot then
    select string_agg(
             format('%s %s-%s',
                    (array['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'])[s.day_of_week],
                    to_char(s.start_time, 'HH24:MI'),
                    to_char(s.end_time, 'HH24:MI')),
             ', ' order by s.day_of_week, s.start_time)
      into v_slots
    from course_schedules s
    where s.course_id = p_course_id;

    return json_build_object('success', false,
      'message', 'Di luar jadwal kuliah. Sesi hanya bisa dibuka pada ' || v_slots ||
                 ' (mulai 15 menit sebelum jam mulai).');
  end if;

  -- Ruangan harus sudah diatur dan aktif
  select * into v_room from rooms where id = v_course.room_id;
  if not found then
    return json_build_object('success', false,
      'message', 'Mata kuliah belum memiliki ruangan. Hubungi admin.');
  end if;
  if v_room.is_active is not true then
    return json_build_object('success', false,
      'message', 'Ruangan ' || v_room.room_name || ' sedang dinonaktifkan.');
  end if;

  insert into class_sessions
    (lecturer_id, course_id, course_code, course_name, room_id, room_name,
     session_type, target_lat, target_lng, radius_meter, is_active, started_at)
  values
    (p_lecturer_id, v_course.id, v_course.course_code, v_course.course_name,
     v_room.id, v_room.room_name, v_type, v_room.latitude, v_room.longitude,
     round(v_room.radius_meters)::int, true, now())
  returning * into v_session;

  return json_build_object('success', true, 'session', to_jsonb(v_session));
end;
$$;
