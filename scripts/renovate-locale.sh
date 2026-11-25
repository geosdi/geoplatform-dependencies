#!/bin/sh
# Renovate lanciato a mano dal proprio computer, in Docker, sul progetto del gruppo, con un ramo base diverso
# da master (CLAUDE.md, «Aggiornamenti delle versioni»). Serve finché renovate.json e il workflow renovate non
# sono su master: GitHub fa partire il calendario solo dai workflow di master.
#
#   sh scripts/renovate-locale.sh [prova|vai] [<ramo base>]
#
#   prova (default)  dry run: dice quali rami e pull request creerebbe, senza scrivere niente su GitHub
#   vai              crea davvero rami, pull request (verso il ramo base) e Dependency Dashboard
#
# Con SALVA_LOG=<file> il log completo di Renovate resta in quel file.
#
# Il token è quello del login di gh (gh auth token, scope repo e workflow): pull request e dashboard
# risultano aperti dall'utente di gh. Il token passa a Docker per variabile d'ambiente, mai sulla riga di
# comando. Il ramo base deve essere già su GitHub con il renovate.json, che lo script passa a Renovate come
# configurazione: Renovate legge GitHub, non il clone.
# Docker va acceso prima e rispento dopo (skill strumenti-locali:docker-locale).
set -eu

modo="${1:-prova}"
ramo="${2:-spring-upgrade}"
repo="geosdi/geoplatform-dependencies"

case "$modo" in
  prova | vai) ;;
  *) echo "uso: sh scripts/renovate-locale.sh [prova|vai] [<ramo base>]" >&2; exit 2 ;;
esac

cartella=$(cd "$(dirname "$0")/.." && pwd)
command -v gh >/dev/null || { echo "manca gh" >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "Docker non risponde: accendilo prima" >&2; exit 1; }

# stessa versione di Renovate del workflow renovate; -full (Java, Maven, Gradle) solo per i rami veri, dove
# Renovate aggiorna anche il wrapper di Gradle; per la prova basta l'immagine base
versione=$(sed -n 's/.*renovate-version: *"\([0-9][0-9.]*\)-full".*/\1/p' "$cartella/.github/workflows/renovate.yml")
[ -n "$versione" ] || { echo "versione di Renovate non trovata in .github/workflows/renovate.yml" >&2; exit 1; }
immagine="renovate/renovate:$versione"
[ "$modo" = vai ] && immagine="$immagine-full"

lavoro=$(mktemp -d)
trap 'rm -rf "$lavoro"' EXIT

# La configurazione è il renovate.json del ramo base su GitHub, passato come file di configurazione: su master
# il file non c'è, e Renovate cerca quello dei rami base con il nome trovato su master (useBaseBranchConfig).
# Senza il file Renovate girerebbe con la configurazione di serie: meglio fermarsi.
gh api "repos/$repo/contents/renovate.json?ref=$ramo" -H "Accept: application/vnd.github.raw" \
  > "$lavoro/renovate.json" 2>/dev/null || {
  echo "su $repo il ramo $ramo non ha renovate.json: prima il push del ramo" >&2
  exit 1
}

RENOVATE_TOKEN=$(gh auth token)
GITHUB_COM_TOKEN="$RENOVATE_TOKEN"
export RENOVATE_TOKEN GITHUB_COM_TOKEN

# il dry run solo nella prova: nel modo vai la variabile non deve esserci
set --
[ "$modo" = prova ] && set -- -e RENOVATE_DRY_RUN=full

log="$lavoro/renovate.log"

echo "Renovate $immagine su $repo, ramo base $ramo ($modo)"
docker run --rm \
  -e RENOVATE_TOKEN -e GITHUB_COM_TOKEN \
  -e RENOVATE_PLATFORM=github \
  -e RENOVATE_REPOSITORIES="$repo" \
  -e RENOVATE_BASE_BRANCH_PATTERNS="[\"$ramo\"]" \
  -v "$lavoro/renovate.json":/tmp/renovate-config.json:ro \
  -e RENOVATE_CONFIG_FILE=/tmp/renovate-config.json \
  -e RENOVATE_REQUIRE_CONFIG=optional \
  -e RENOVATE_ONBOARDING=false \
  "$@" \
  -e RENOVATE_BINARY_SOURCE=global \
  -e LOG_LEVEL=info \
  "$immagine" > "$log" 2>&1 || { tail -n 30 "$log"; [ -z "${SALVA_LOG:-}" ] || cp "$log" "$SALVA_LOG"; exit 1; }

# log completo, se chiesto: SALVA_LOG=<file> sh scripts/renovate-locale.sh ...
[ -z "${SALVA_LOG:-}" ] || cp "$log" "$SALVA_LOG"

# riassunto: cosa farebbe (prova) o cosa ha fatto (vai), poi avvisi ed errori
grep -E 'DRY-RUN|Branch created|PR created|PR updated|Dependency Dashboard|WARN|ERROR' "$log" || true
echo "fatto"
