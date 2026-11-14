-- Flytt RLS-hjelpere ut av det eksponerte public-skjemaet
create schema if not exists privat;
grant usage on schema privat to authenticated;

alter function public.er_admin() set schema privat;
alter function public.er_aktiv() set schema privat;
revoke execute on function privat.er_admin() from public, anon;
revoke execute on function privat.er_aktiv() from public, anon;
grant execute on function privat.er_admin() to authenticated;
grant execute on function privat.er_aktiv() to authenticated;

-- Policyene peker på funksjonens OID, men vi gjenskaper dem for lesbarhet
drop policy "se egen profil eller admin" on public.profiler;
drop policy "admin endrer profiler" on public.profiler;
drop policy "se egne eller admin" on public.stemplinger;
drop policy "aktiv ansatt stempler selv, admin for alle" on public.stemplinger;
drop policy "rette egne eller admin" on public.stemplinger;
drop policy "admin sletter" on public.stemplinger;

create policy "se egen profil eller admin" on public.profiler for select to authenticated
  using (id = (select auth.uid()) or (select privat.er_admin()));
create policy "admin endrer profiler" on public.profiler for update to authenticated
  using ((select privat.er_admin())) with check ((select privat.er_admin()));

create policy "se egne eller admin" on public.stemplinger for select to authenticated
  using (user_id = (select auth.uid()) or (select privat.er_admin()));
create policy "aktiv ansatt stempler selv, admin for alle" on public.stemplinger for insert to authenticated
  with check ((user_id = (select auth.uid()) and (select privat.er_aktiv())) or (select privat.er_admin()));
create policy "rette egne eller admin" on public.stemplinger for update to authenticated
  using ((user_id = (select auth.uid()) and (select privat.er_aktiv())) or (select privat.er_admin()))
  with check ((user_id = (select auth.uid()) and (select privat.er_aktiv())) or (select privat.er_admin()));
create policy "admin sletter" on public.stemplinger for delete to authenticated
  using ((select privat.er_admin()));
