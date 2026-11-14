# Tidregistrering (stempling)

Hele appen er én fil: `index.html`. Ingen byggesteg, ingen npm.
Databasen er Supabase-prosjektet «Timer» (`fvefrpvybfrjlocukzxz`).

## Publisere med GitHub Pages
1. Last opp `index.html` (og gjerne `supabase/`-mappen og denne README) til et GitHub-repo.
2. I repoet: **Settings → Pages → Build and deployment → Source: Deploy from a branch**, velg `main` og `/ (root)`.
3. Etter et minutt ligger appen på `https://<brukernavn>.github.io/<repo>/`.
4. I Supabase: **Authentication → URL Configuration**
   - Site URL: `https://<brukernavn>.github.io/<repo>/`
   - Redirect URLs: legg til samme adresse (og `http://localhost:5175` om du vil teste lokalt).

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
Appen ligger på https://timer.greknuts.workers.dev (Cloudflare Workers, statiske filer).
Publiser en ny versjon fra denne mappen med:
```
npx wrangler@4 deploy
```
`wrangler.jsonc` og `.assetsignore` sørger for at bare `index.html` legges ut.
Husk å legge adressen inn i Supabase under Site URL / Redirect URLs.
