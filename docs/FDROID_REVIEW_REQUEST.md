# Bíblia IPM — request for preliminary inclusion review (asset licensing unresolved)

Hello F-Droid maintainers,

I am requesting a preliminary review of Bíblia IPM and guidance on the remaining requirements for inclusion. This is not a claim that all inclusion requirements have been met.

## App details

- Name: Bíblia IPM
- Application ID: br.com.valdenor.bibliaapp
- Source: https://github.com/alunoadsnoite/bibliaappipm
- Release: https://github.com/alunoadsnoite/bibliaappipm/releases/tag/v5.4.0
- Version: 5.4.0 (versionCode 32)
- Source code license: MIT; bundled content is explicitly excluded from this license.
- Main app: Flutter project under flutter/; the Java project at the repository root is legacy code.
- Upstream descriptions and changelog: fastlane/metadata/android/ (pt-BR and en-US).

The app provides Portuguese offline Bible reading, hymn and song lyrics, a document library, notes, highlights, favorites, reading plans, optional local reminders, device text-to-speech, and JSON backups. It does not require an account. Automated validation passed 119 tests and static analysis; a signed release APK was built locally. This does not constitute a validated fdroidserver build recipe.

## Known unresolved asset licensing

The app bundles JFAA, ARA, NVI, NTLH and BKJ Bible texts, the Novo Cântico hymnal, songs, translated documents and a church logo. Their origin and redistribution licenses have not yet been fully documented. The developer reports that the Bible files were obtained by an earlier coding assistant from a supposedly free source, but the original source link is unavailable. We do not claim that free online availability establishes redistribution rights.

The developer states that the song list is their own compilation and authorizes copying it; this does not establish ownership or a license for every included lyric. They attribute other church materials to the Igreja Presbiteriana do Brasil, but written redistribution permissions have not been supplied. The official Portuguese NVI page identifies Biblica as its copyright holder.

Current documentation:
- https://github.com/alunoadsnoite/bibliaappipm/blob/main/docs/CONTENT_LICENSES.md
- https://github.com/alunoadsnoite/bibliaappipm/blob/main/docs/FDROID.md

Could you advise whether this request should remain open pending license documentation, or whether a separate build containing only verified licensed/public-domain content should be proposed? Please also identify any additional build or dependency requirements for this Flutter project.

We understand that inclusion cannot proceed without resolving the content licensing requirements, and that the final decision belongs to the F-Droid maintainers.
