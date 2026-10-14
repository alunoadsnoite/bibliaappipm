# Inclusão no catálogo oficial do F-Droid

Estado: solicitação de avaliação preliminar publicada em 10/10/2026 e aberta em https://gitlab.com/fdroid/rfp/-/work_items/4547. A pendência das licenças **foi resolvida** nesta versão: todo o conteúdo empacotado passou a ser de domínio público ou de licença livre. O aplicativo ainda não foi aprovado nem publicado no catálogo oficial.

## Código e versão

- Repositório: https://github.com/alunoadsnoite/bibliaappipm
- Código principal: `flutter/` (a aplicação Java na raiz é legada).
- Application ID: `br.com.valdenor.bibliaapp`.
- Versão: `5.5.0`, versionCode `33`.
- Licença do código: MIT. A licença não cobre os conteúdos dos assets, que têm licenças próprias livres.
- Flutter usado na validação local: commit `abaf9c523780a608bd46686fd5e53740a07077f8`.
- Descrições, ícone e changelog: `fastlane/metadata/android/` em português e inglês.

## Conteúdo (resolvido)

Os conteúdos protegidos foram substituídos por equivalentes livres/domínio público:

- Bíblia: **Bíblia Livre** (CC BY 4.0 BR), **Bíblia Portuguesa Mundial** (domínio público), **JFAAL** (MIT) e **Almeida 1911** (domínio público), no lugar de ARA, NVI, NTLH, BKJ e JFAA.
- Hinário: **Salmos e Hinos** (edição de 1880, domínio público), no lugar do Novo Cântico.
- Cancioneiro empacotado: removido (as letras ficam a cargo do usuário).
- Biblioteca: documentos clássicos em domínio público; as citações dos Dez Mandamentos e da Oração Dominical passaram a usar a BPM.
- App Java legado: alinhado ao mesmo conteúdo livre.

A origem e as licenças de cada conteúdo estão em [CONTENT_LICENSES.md](CONTENT_LICENSES.md). A política do F-Droid exige licenças válidas ou domínio público para todos os assets; esse requisito está atendido.

## Compilação

Em 11/10/2026, foi conferido o relatório automático do F-Droid Bot na
[solicitação #4547](https://gitlab.com/fdroid/rfp/-/work_items/4547#note_3991187767).
O alerta de ausência de `distributionSha256Sum` foi corrigido no Gradle Wrapper
Flutter com o checksum oficial da distribuição Gradle 9.3.1. A solicitação
continua aberta; ainda não há resposta de um mantenedor sobre as licenças.

```sh
cd flutter
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build apk --release
```

A publicação do desenvolvedor utiliza `flutter/android/key.properties` e a chave privada local, ambos ignorados pelo Git. O F-Droid compila do código-fonte e normalmente assina com sua própria chave. Na receita do F-Droid, remover a configuração de assinatura do desenvolvedor para produzir um APK sem assinatura; jamais enviar a chave privada.

O empacotador precisa fixar a revisão do Flutter, configurar a compilação em `flutter/`, verificar as dependências e testar a receita no ambiente do fdroidserver. A compilação local de um APK não comprova validação no ambiente oficial.

## Envio

O pedido de avaliação preliminar está registrado na issue #4547 do tracker Requests For Packaging. A descrição inclui os links do código e do APK, a versão e a licença MIT limitada ao código; a checklist não declara conformidade já comprovada.

Após documentar as licenças e testar a receita de compilação, abrir uma merge request de metadados em https://gitlab.com/fdroid/fdroiddata, conforme o guia oficial. É necessária uma sessão autenticada no GitLab. A aceitação, assinatura e publicação no catálogo dependem dos mantenedores do F-Droid.

Referências:
- https://f-droid.org/en/docs/Inclusion_Policy/
- https://f-droid.org/docs/Submitting_to_F-Droid_Quick_Start_Guide/
