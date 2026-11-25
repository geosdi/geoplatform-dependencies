# geoplatform-dependencies

Moduli che fissano le versioni delle dipendenze del progetto GeoPlatform (Spring, GeoTools, Jackson,
Hibernate Validator, CXF, ...). La build esiste sia con Maven (`pom.xml`) sia con Gradle
(`build.gradle`, `gradle.properties`): le versioni vanno tenute allineate nelle due.

## Remote

- `upstream`: `geosdi/geoplatform-dependencies`, il progetto del gruppo.
- `origin`: il fork personale.

## All'inizio di ogni sessione

- **Aggiornamenti delle versioni**: le versioni nuove le propone Renovate (`renovate.json`, workflow
  `renovate`) il 1° e il 15 del mese, solo se uscite da almeno 14 giorni. Una pull request per modulo
  (Spring, GeoTools, Jackson, ...) con `pom.xml` e `build.gradle` aggiornati insieme, più «build» (plugin
  Maven e Gradle, wrapper) e «pipeline» (action e versione di Renovate). Sulle pull request gira il
  workflow `build` (Maven e Gradle). Le major si aprono solo dopo la spunta nel Dependency Dashboard
  (issue «Aggiornamenti delle versioni (Renovate)»), dopo aver letto le note. Escluse le sostituzioni di
  artifact (es. `slf4j-log4j12` → `slf4j-reload4j`): Renovate le farebbe solo nel `pom.xml`, si fanno a
  mano in tutte e due le build. A inizio sessione si riferiscono le pull request aperte e il dashboard con
  la skill `progetto:aggiornamenti-versioni` (modo controllo); il merge lo decide Peppino.
  - Ultimo controllo: 2026-11-25 (impostazione di Renovate).
  - In uso: Spring 7.1.0, Spring Boot 4.2.0, Spring Security 7.2.0, Spring Batch 6.1.0, springdoc 3.2.1,
    GeoTools 35.2, Jackson 3.3.0, CXF 4.2.4, Hibernate Validator 9.2.0.Final, JUnit 6.1.3,
    Elasticsearch 7.17.29, Gradle 9.9.1.
  - Rimandati: Elasticsearch 9 si fa a mano sul ramo `elasticsearch-9`; la sua major è esclusa da
    Renovate. Per ora master non si tocca: Renovate si lancia a mano con
    `sh scripts/renovate-locale.sh` (prova, niente su GitHub) o `sh scripts/renovate-locale.sh vai` (PR
    verso `spring-upgrade`), token dal login di `gh`, Docker acceso prima e spento dopo. Il calendario del
    workflow `renovate` si accende da solo quando i suoi file arrivano su master.
  - Da sistemare a mano: `org.geotools:gt-gml` 2.5.5 (solo nel `pom.xml` di GeoTools, non nel
    `build.gradle`) non esiste in nessun repository e Renovate non lo trova.
  - Dependabot: sul progetto del gruppo sono attivi gli aggiornamenti di sicurezza di Dependabot (PR
    vecchie #19 e #20). Quando Renovate arriva su master conviene tenerne uno solo.

## Commit

- Nei messaggi di commit e nelle descrizioni delle PR non citare mai Claude: niente riga
  `Co-Authored-By: Claude ...` né "Generated with Claude Code".

## Parametri per i plugin geosdi

- `notifiche-remote`: `upstream`
- `notifiche-destinatari`: glascaleia@gmail.com, francesco.izzi@gmail.com, vito.salvia@gmail.com
- `notifiche-rami`: `tutti`
- `notifiche-smtp`: smtp.gmail.com:465 (TLS)
- `notifiche-mittente`: geoplatform-dependencies <geosdigeoplatform@gmail.com>
- `aggiornamenti-remote`: `upstream`
- `aggiornamenti-calendario`: `0 6 1,15 * *` (Europe/Rome; nel workflow `0 5 1,15 * *` UTC)
- `aggiornamenti-attesa`: `14 days`
- `aggiornamenti-fuori`: nessuno
- `aggiornamenti-versioni-in-uso`: punto «Aggiornamenti delle versioni» di «All'inizio di ogni sessione»
