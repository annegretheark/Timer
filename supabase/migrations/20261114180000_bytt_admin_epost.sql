-- Bytt e-post som automatisk blir admin
create or replace function public.ny_bruker() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  admin boolean := lower(new.email) = 'annknutsen59@gmail.com';
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

revoke execute on function public.ny_bruker() from public, anon, authenticated;

-- Hvis kontoen allerede finnes, gjør den til admin
update public.profiler set rolle = 'admin', aktiv = true where lower(epost) = 'annknutsen59@gmail.com';
