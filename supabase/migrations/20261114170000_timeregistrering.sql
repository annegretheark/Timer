-- Tidregistrering: kunder, prosjekter og timeføringer per bruker

create table public.kunder (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  navn text not null check (length(trim(navn)) > 0),
  opprettet timestamptz not null default now()
);

create table public.prosjekter (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  kunde_id uuid references public.kunder(id) on delete set null,
  navn text not null check (length(trim(navn)) > 0),
  timepris numeric(10,2),
  farge text not null default '#2563eb',
  aktiv boolean not null default true,
  opprettet timestamptz not null default now()
);

create table public.timeforinger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  prosjekt_id uuid references public.prosjekter(id) on delete set null,
  beskrivelse text not null default '',
  start_tid timestamptz not null default now(),
  slutt_tid timestamptz,
  fakturerbar boolean not null default true,
  opprettet timestamptz not null default now(),
  check (slutt_tid is null or slutt_tid >= start_tid)
);

-- Bare én løpende timer per bruker
create unique index timeforinger_en_lopende on public.timeforinger(user_id) where slutt_tid is null;
create index timeforinger_user_start on public.timeforinger(user_id, start_tid desc);
create index prosjekter_user on public.prosjekter(user_id);
create index prosjekter_kunde on public.prosjekter(kunde_id);
create index kunder_user on public.kunder(user_id);
create index timeforinger_prosjekt on public.timeforinger(prosjekt_id);

alter table public.kunder enable row level security;
alter table public.prosjekter enable row level security;
alter table public.timeforinger enable row level security;

create policy "egne kunder" on public.kunder for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "egne prosjekter" on public.prosjekter for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "egne timeforinger" on public.timeforinger for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
