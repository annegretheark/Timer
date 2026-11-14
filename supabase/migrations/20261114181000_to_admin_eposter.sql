-- To e-poster blir automatisk admin
create or replace function public.ny_bruker() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  admin boolean := lower(new.email) in ('annknutsen59@gmail.com', 'greknuts@online.no');
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

update public.profiler set rolle = 'admin', aktiv = true
where lower(epost) in ('annknutsen59@gmail.com', 'greknuts@online.no');
