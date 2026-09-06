-- P3NR V3 - MULTI DESA
-- Jalankan seluruh script ini di Supabase SQL Editor.
-- Setelah itu buat akun di Authentication > Users, lalu masukkan UUID user ke tabel profiles.

create extension if not exists pgcrypto;

create table if not exists public.villages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  kecamatan text,
  kabupaten text,
  provinsi text,
  kode text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null check (role in ('admin_kecamatan','petugas_desa')),
  village_id uuid references public.villages(id) on delete restrict,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint petugas_wajib_punya_desa check (role <> 'petugas_desa' or village_id is not null)
);

create table if not exists public.village_settings (
  village_id uuid primary key references public.villages(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);

create table if not exists public.registers (
  id text primary key,
  village_id uuid not null references public.villages(id) on delete restrict,
  nomor text not null,
  tanggal_daftar date not null,
  data jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(village_id, nomor)
);

create index if not exists idx_registers_village on public.registers(village_id);
create index if not exists idx_registers_tanggal on public.registers(tanggal_daftar desc);
create index if not exists idx_profiles_village on public.profiles(village_id);

create or replace function public.my_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid() and active = true limit 1;
$$;

create or replace function public.my_village_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select village_id from public.profiles where id = auth.uid() and active = true limit 1;
$$;

create or replace function public.is_admin_kecamatan()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.my_role() = 'admin_kecamatan', false);
$$;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_village_settings_updated on public.village_settings;
create trigger trg_village_settings_updated before update on public.village_settings
for each row execute function public.touch_updated_at();

drop trigger if exists trg_registers_updated on public.registers;
create trigger trg_registers_updated before update on public.registers
for each row execute function public.touch_updated_at();

alter table public.villages enable row level security;
alter table public.profiles enable row level security;
alter table public.village_settings enable row level security;
alter table public.registers enable row level security;

-- Profiles: user hanya membaca profilnya sendiri.
drop policy if exists profiles_select_self on public.profiles;
create policy profiles_select_self on public.profiles
for select to authenticated using (id = auth.uid());

-- Desa: admin melihat semua; petugas hanya desa yang ditugaskan.
drop policy if exists villages_select on public.villages;
create policy villages_select on public.villages
for select to authenticated
using (public.is_admin_kecamatan() or id = public.my_village_id());

drop policy if exists villages_insert_admin on public.villages;
create policy villages_insert_admin on public.villages
for insert to authenticated
with check (public.is_admin_kecamatan());

drop policy if exists villages_update_admin on public.villages;
create policy villages_update_admin on public.villages
for update to authenticated
using (public.is_admin_kecamatan())
with check (public.is_admin_kecamatan());

-- Pengaturan desa.
drop policy if exists settings_select on public.village_settings;
create policy settings_select on public.village_settings
for select to authenticated
using (public.is_admin_kecamatan() or village_id = public.my_village_id());

drop policy if exists settings_insert on public.village_settings;
create policy settings_insert on public.village_settings
for insert to authenticated
with check (public.is_admin_kecamatan() or village_id = public.my_village_id());

drop policy if exists settings_update on public.village_settings;
create policy settings_update on public.village_settings
for update to authenticated
using (public.is_admin_kecamatan() or village_id = public.my_village_id())
with check (public.is_admin_kecamatan() or village_id = public.my_village_id());

-- Register: ADMIN KECAMATAN bisa semua desa; PETUGAS DESA hanya desanya.
drop policy if exists registers_select on public.registers;
create policy registers_select on public.registers
for select to authenticated
using (public.is_admin_kecamatan() or village_id = public.my_village_id());

drop policy if exists registers_insert on public.registers;
create policy registers_insert on public.registers
for insert to authenticated
with check ((public.is_admin_kecamatan() or village_id = public.my_village_id()) and created_by = auth.uid());

drop policy if exists registers_update on public.registers;
create policy registers_update on public.registers
for update to authenticated
using (public.is_admin_kecamatan() or village_id = public.my_village_id())
with check ((public.is_admin_kecamatan() or village_id = public.my_village_id()) and updated_by = auth.uid());

drop policy if exists registers_delete on public.registers;
create policy registers_delete on public.registers
for delete to authenticated
using (public.is_admin_kecamatan() or village_id = public.my_village_id());

-- Daftar desa Kecamatan Tanjungsari.
-- Nama disimpan tanpa prefix "Desa " agar tampilan Master Desa tetap ringkas.
insert into public.villages (name, kecamatan, kabupaten, provinsi, kode)
select v.name, 'Tanjungsari', 'Sumedang', 'Jawa Barat', null
from (values
  ('Gudang'),
  ('Tanjungsari'),
  ('Jatisari'),
  ('Margaluyu'),
  ('Kutamandiri'),
  ('Margajaya'),
  ('Raharja'),
  ('Cijambu'),
  ('Pasigaran'),
  ('Gunungmanik'),
  ('Kadakajaya'),
  ('Cinanjung')
) as v(name)
where not exists (
  select 1 from public.villages x
  where lower(x.name)=lower(v.name)
    and lower(coalesce(x.kecamatan,''))='tanjungsari'
);

-- ================================================================
-- SETELAH MEMBUAT USER DI Supabase Authentication > Users:
-- 1. Salin UUID user admin kecamatan.
-- 2. Jalankan contoh berikut dengan UUID sebenarnya:
--
-- insert into public.profiles(id, full_name, role, village_id)
-- values ('UUID-USER-ADMIN', 'Admin Kecamatan', 'admin_kecamatan', null)
-- on conflict (id) do update set full_name=excluded.full_name, role=excluded.role, village_id=excluded.village_id, active=true;
--
-- 3. Untuk petugas desa:
-- insert into public.profiles(id, full_name, role, village_id)
-- select 'UUID-USER-PETUGAS', 'Petugas Desa Gudang', 'petugas_desa', id
-- from public.villages where lower(name)='gudang'
-- on conflict (id) do update set full_name=excluded.full_name, role=excluded.role, village_id=excluded.village_id, active=true;
-- ================================================================


-- DATA AWAL 12 DESA KECAMATAN TANJUNGSARI
-- Aman dijalankan berulang: desa yang sudah ada tidak akan digandakan.
INSERT INTO public.villages (name, kecamatan, kabupaten, provinsi)
SELECT v.name, 'Tanjungsari', 'Sumedang', 'Jawa Barat'
FROM (VALUES
  ('Gudang'), ('Tanjungsari'), ('Jatisari'), ('Margaluyu'), ('Kutamandiri'), ('Margajaya'), ('Raharja'), ('Cijambu'), ('Pasigaran'), ('Gunungmanik'), ('Kadakajaya'), ('Cinanjung')
) AS v(name)
WHERE NOT EXISTS (
  SELECT 1 FROM public.villages x
  WHERE lower(trim(x.name)) = lower(trim(v.name))
    AND lower(trim(coalesce(x.kecamatan,''))) = 'tanjungsari'
);

