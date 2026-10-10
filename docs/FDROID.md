# Inclusão no catálogo oficial do F-Droid

Estado: preparação em andamento; o aplicativo ainda não foi submetido nem publicado no catálogo oficial.

## Código e versão

- Repositório: https://github.com/alunoadsnoite/bibliaappipm
- Código principal: `flutter/` (a aplicação Java na raiz é legada).
- Application ID: `br.com.valdenor.bibliaapp`.
- Versão: `5.4.0`, versionCode `32`, tag prevista `v5.4.0`.
- Licença do código: MIT. A licença não cobre os conteúdos dos assets.
- Flutter usado na validação local: commit `abaf9c523780a608bd46686fd5e53740a07077f8`.
- Descrições, ícone e changelog: `fastlane/metadata/android/` em português e inglês.

## Pendência de conteúdo

É necessário documentar a origem, a licença e a autorização de redistribuição de cada tradução bíblica (JFAA, ARA, NVI, NTLH e BKJ), do Hinário Novo Cântico, das músicas, das traduções dos documentos e da logomarca. Não presumir que esses materiais estão cobertos pela licença MIT.

A política do F-Droid exige licenças legais válidas ou domínio público para todos os assets. A documentação de direitos deve ser incluída no repositório antes da solicitação de inclusão.

## Compilação

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

Após documentar as licenças e testar a receita de compilação, abrir uma merge request de metadados em https://gitlab.com/fdroid/fdroiddata, conforme o guia oficial. É necessária uma sessão autenticada no GitLab. A aceitação, assinatura e publicação no catálogo dependem dos mantenedores do F-Droid.

Referências:
- https://f-droid.org/en/docs/Inclusion_Policy/
- https://f-droid.org/docs/Submitting_to_F-Droid_Quick_Start_Guide/
