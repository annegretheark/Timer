# Tidregistrering (stempling)

Hele appen er én fil: `index.html`. Ingen byggesteg, ingen npm.
Databasen er Supabase-prosjektet «Timer» (`fvefrpvybfrjlocukzxz`).

**Adresse:** https://timer.rettilomma.com (Cloudflare, se nederst). GitHub-repoet er bare kildekode.

Supabase → **Authentication → URL Configuration**: Site URL og Redirect URLs = `https://timer.rettilomma.com`.

## Roller
- **Ansatt**: oppretter konto selv, må aktiveres av admin. Stempler inn/ut, ser og retter egne føringer.
- **Admin**: e-postene i `ny_bruker()`-triggeren blir admin automatisk. Ser alle, retter/sletter, aktiverer ansatte, laster ned Excel.

## Sikkerhet
Nøkkelen i `index.html` er Supabase sin *publishable key*, som er laget for å ligge åpent i nettleseren.
Hvem som får se og endre hva, styres av Row Level Security i databasen (se `supabase/migrations`).

## Database
Endringer: legg en ny fil i `supabase/migrations` og kjør `supabase db push --linked`.
Tabeller: `profiler` (navn, rolle, aktiv) og `stemplinger` (inn, ut, kommentar, endret, endret_av).

## Excel / Fiken
Oversikt → «Last ned Excel» gir to ark: *Sammendrag* (timer per ansatt) og *Stemplinger* (alle rader).
Fiken-integrasjon kan senere bygges som en Supabase Edge Function som leser de samme tabellene.

## Publisere på Cloudflare
Appen ligger på https://timer.rettilomma.com (Cloudflare Workers, statiske filer, eget domene).
Publiser en ny versjon fra denne mappen med:
```
npx wrangler@4 deploy
```
`wrangler.jsonc` og `.assetsignore` sørger for at bare `index.html` legges ut.
Husk å legge adressen inn i Supabase under Site URL / Redirect URLs.

## Hjemskjermapp (mobil)
`manifest.webmanifest`, `sw.js` og `ikoner/` gjør at appen kan legges på hjemskjermen og åpnes i
fullskjerm. Innloggingen huskes på enheten til brukeren selv logger ut (Logg ut ligger i brukermenyen).
På iPhone må appen legges på hjemskjermen for at Safari ikke skal slette innloggingen etter 7 dager.
Service workeren henter alltid nyeste versjon fra nettet og bruker bare lagret kopi hvis nettet er nede.
