# Atualização preparada para o pedido F-Droid #4547

Estado: comentário publicado e confirmado em 11/10/2026 na solicitação existente. Link: https://gitlab.com/fdroid/rfp/-/work_items/4547#note_3992438672. O pedido permanece aberto, sem aprovação de inclusão.

Destino: https://gitlab.com/fdroid/rfp/-/work_items/4547

## Texto do comentário

Progress update from upstream:

- The missing Gradle Wrapper `distributionSha256Sum` reported by the bot was fixed in commit `94889ddb30ac3463f2300443251f2b5454cc3ed6`, using the official checksum for Gradle 9.3.1. The wrapper was checked locally with `./gradlew --version`.
- We investigated bundled text provenance and recorded the findings, developer statements and primary sources at https://github.com/alunoadsnoite/bibliaappipm/blob/main/docs/CONTENT_LICENSES.md.
- Official sources attribute NVI to Biblica, ARA/NTLH to the Brazilian Bible Society, and the Portuguese BKJ Fiel edition to BV Books. The exact download sources and full redistribution permissions for the app's assets remain unresolved. The developer asked to retain all current content; we have not replaced or removed assets or declared that these rights are resolved.
- Local source-code validation and the existing signed APK do not establish compliance with the content requirements or a validated fdroidserver build recipe.

Could a maintainer advise what documentation is needed for this preliminary request to progress with the current content? We understand that official inclusion is subject to review and that licensing remains an outstanding requirement.
