# Bíblia IPM — dois aplicativos

O projeto foi dividido em duas edições com identidades Android distintas.

| Aplicativo | Finalidade | Código | Download |
| --- | --- | --- | --- |
| **Bíblia IPM** | Uso pela igreja, com o conteúdo original | [Branch igreja](https://github.com/alunoadsnoite/bibliaappipm/tree/igreja) | [5.4.1](https://github.com/alunoadsnoite/bibliaappipm/releases/tag/v5.4.1) |
| **Bíblia Livre IPM** | Edição independente destinada ao F-Droid, sem documentos da Biblioteca | [Repositório próprio](https://github.com/alunoadsnoite/biblia-livre-ipm) | [Releases](https://github.com/alunoadsnoite/biblia-livre-ipm/releases) |

## Instalar e desenvolver

**Igreja:** identificador `br.com.valdenor.bibliaapp`. Para desenvolver com o conteúdo original, use a branch `igreja`, baseada em `v5.4.0`:

```sh
git clone --branch igreja https://github.com/alunoadsnoite/bibliaappipm.git
cd bibliaappipm/flutter
flutter pub get --enforce-lockfile
flutter run
```

**Edição livre:** identificador `br.com.valdenor.biblialivreipm`, nome e ícone próprios. Pode ser instalada junto com a edição da igreja. [Leia o README da edição livre](https://github.com/alunoadsnoite/biblia-livre-ipm#readme).

Cada app mantém seu armazenamento. A migração entre os dois identificadores não é automática; backups pessoais podem ser exportados/importados, com referências indisponíveis quando o conteúdo não existir no destino.

## Estado das publicações

- **5.4.1:** edição da igreja atualizada para remover contatos e Pix; a release histórica 5.4.0 permanece como publicada originalmente.
- **5.5.0:** etapa intermediária com substituições de textos; mantém o identificador da igreja e ainda contém Biblioteca. Não é o app independente e não comprova aprovação no F-Droid.
- **5.6.0 no novo repositório:** primeira edição independente Bíblia Livre IPM, sem documentos da Biblioteca.
- **F-Droid:** [pedido #4547](https://gitlab.com/fdroid/rfp/-/work_items/4547) em avaliação. Inclusão no catálogo oficial ainda não confirmada.

A branch `main` deste repositório preserva o código da etapa 5.5.0 e este índice da separação; a manutenção da edição da igreja ocorre em `igreja`. A edição livre evolui exclusivamente no novo repositório.

## Recursos da edição da igreja

Leitura bíblica offline, hinário, músicas, Biblioteca, boletim, notas e destaques, favoritos, busca, plano de leitura, leitura por voz, lembretes locais, widget e backups JSON. O conteúdo original e sua documentação de versão estão na branch `igreja`.

## Espelhos e licenças

- Igreja: [GitHub](https://github.com/alunoadsnoite/bibliaappipm) · [GitLab](https://gitlab.com/alunoadsnoite/bibliaappipm).
- Livre: [GitHub](https://github.com/alunoadsnoite/biblia-livre-ipm) · [GitLab](https://gitlab.com/alunoadsnoite/biblia-livre-ipm).

O código é MIT. Textos, hinários, traduções e marcas têm direitos próprios; a licença do código não autoriza automaticamente sua redistribuição. A edição da igreja não está sendo submetida ao F-Droid. [Licenças e pendências da edição livre](https://github.com/alunoadsnoite/biblia-livre-ipm/blob/main/docs/CONTENT_LICENSES.md).

Suporte: Issues do GitHub.
