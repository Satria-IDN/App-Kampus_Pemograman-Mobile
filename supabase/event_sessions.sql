-- ============================================================
-- Event (workshop / kuliah tamu) sebagai sub-sesi mata kuliah.
-- Jalankan SEKALI di Supabase SQL Editor (aman diulang).
--
-- Perubahan:
--  1. Kolom judul event pada class_sessions.
--  2. open_class_session: aturan jadwal hanya berlaku untuk sesi
--     'reguler'. Workshop dan kuliah tamu boleh dibuka kapan saja
--     oleh dosen pengampu, dengan judul event wajib diisi.
-- ============================================================

alter table public.class_sessions
  add column if not exists event_title text;

-- Hapus versi lama (3 parameter) agar tidak ambigu dengan versi baru
drop function if exists public.open_class_session(uuid, uuid, text);

create or replace function public.open_class_session(
  p_course_id uuid,
  p_lecturer_id uuid,
  p_session_type text default 'reguler',
  p_event_title text default null
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
  v_dow      int  := extract(isodow from (now() at time zone 'Asia/Jakarta'))::int;
  v_time     time := (now() at time zone 'Asia/Jakarta')::time;
  v_type     text := lower(coalesce(p_session_type, 'reguler'));
  v_title    text := nullif(trim(coalesce(p_event_title, '')), '');
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

  -- Sesi yang masih aktif selalu boleh dilanjutkan
  select * into v_existing
  from class_sessions
  where course_id = p_course_id and is_active = true
  order by created_at desc
  limit 1;

  if found then
    return json_build_object('success', true, 'session', to_jsonb(v_existing));
  end if;

  if v_type = 'reguler' then
    -- Sesi reguler: hanya pada hari dan jam kuliah sesuai jadwal
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
        'message', 'Di luar jadwal kuliah. Sesi reguler hanya bisa dibuka pada ' || v_slots ||
                   ' (mulai 15 menit sebelum jam mulai).');
    end if;
  else
    -- Event: judul wajib, jadwal tidak dibatasi
    if v_title is null then
      return json_build_object('success', false, 'message', 'Judul event wajib diisi.');
    end if;
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
     session_type, event_title, target_lat, target_lng, radius_meter, is_active, started_at)
  values
    (p_lecturer_id, v_course.id, v_course.course_code, v_course.course_name,
     v_room.id, v_room.room_name, v_type,
     case when v_type = 'reguler' then null else v_title end,
     v_room.latitude, v_room.longitude,
     round(v_room.radius_meters)::int, true, now())
  returning * into v_session;

  return json_build_object('success', true, 'session', to_jsonb(v_session));
end;
$$;
