-- Ny modell: ansatte stempler inn/ut, admin ser og redigerer alt.
drop table if exists public.timeforinger;
drop table if exists public.prosjekter;
drop table if exists public.kunder;

create table public.profiler (
  id uuid primary key references auth.users(id) on delete cascade,
  navn text not null default '',
  epost text not null default '',
  rolle text not null default 'ansatt' check (rolle in ('admin', 'ansatt')),
  aktiv boolean not null default false,
  opprettet timestamptz not null default now()
);

create table public.stemplinger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.profiler(id) on delete cascade,
  inn timestamptz not null default now(),
  ut timestamptz,
  kommentar text not null default '',
  endret timestamptz,
  endret_av uuid references public.profiler(id) on delete set null,
  opprettet timestamptz not null default now(),
  check (ut is null or ut >= inn)
);

create unique index stemplinger_en_apen on public.stemplinger(user_id) where ut is null;
create index stemplinger_user_inn on public.stemplinger(user_id, inn desc);
create index stemplinger_inn on public.stemplinger(inn desc);
create index stemplinger_endret_av on public.stemplinger(endret_av);

-- Hjelpefunksjoner (security definer for å unngå RLS-rekursjon)
create or replace function public.er_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiler where id = auth.uid() and rolle = 'admin' and aktiv)
$$;

create or replace function public.er_aktiv() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiler where id = auth.uid() and aktiv)
$$;

-- Ny bruker -> profil. Eieren blir admin automatisk; andre må aktiveres av admin.
create or replace function public.ny_bruker() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  admin boolean := lower(new.email) = 'anne.grethe.knutsen@antire.com';
begin
  insert into public.profiler (id, navn, epost, rolle, aktiv)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data->>'navn'), ''), split_part(new.email, '@', 1)),
    coalesce(new.email, ''),
    case when admin then 'admin' else 'ansatt' end,
    admin
  );
  return new;
end $$;

create trigger ny_bruker after insert on auth.users
  for each row execute function public.ny_bruker();

-- Logg hvem som sist endret en stempling
create or replace function public.merk_endring() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.endret := now();
  new.endret_av := auth.uid();
  return new;
end $$;

create trigger merk_endring before update on public.stemplinger
  for each row execute function public.merk_endring();

alter table public.profiler enable row level security;
alter table public.stemplinger enable row level security;

create policy "se egen profil eller admin" on public.profiler for select to authenticated
  using (id = (select auth.uid()) or (select public.er_admin()));
create policy "admin endrer profiler" on public.profiler for update to authenticated
  using ((select public.er_admin())) with check ((select public.er_admin()));

create policy "se egne eller admin" on public.stemplinger for select to authenticated
  using (user_id = (select auth.uid()) or (select public.er_admin()));
create policy "aktiv ansatt stempler selv, admin for alle" on public.stemplinger for insert to authenticated
  with check ((user_id = (select auth.uid()) and (select public.er_aktiv())) or (select public.er_admin()));
create policy "rette egne eller admin" on public.stemplinger for update to authenticated
  using ((user_id = (select auth.uid()) and (select public.er_aktiv())) or (select public.er_admin()))
  with check ((user_id = (select auth.uid()) and (select public.er_aktiv())) or (select public.er_admin()));
create policy "admin sletter" on public.stemplinger for delete to authenticated
  using ((select public.er_admin()));

revoke execute on function public.ny_bruker() from public, anon, authenticated;
