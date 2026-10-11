# Situação das licenças dos conteúdos

O desenvolvedor informa que as Bíblias vieram de uma fonte de conteúdo livre; em 11/10/2026 atribuiu a origem à IPB e declarou que os demais materiais lhe pertencem, dispensando autorização adicional. Solicitou manter todos os conteúdos. Essas declarações estão registradas, mas a investigação abaixo encontrou atribuições editoriais diferentes para algumas traduções. Nenhum conteúdo foi removido ou substituído.

Este registro distingue informações fornecidas pelo desenvolvedor de licenças verificadas. Ele não amplia a licença MIT do código para os conteúdos.

| Material | Informação disponível | Pendência para F-Droid |
| --- | --- | --- |
| Lista de músicas (`flutter/assets/musicas.json`) | O desenvolvedor declara autoria da lista e autoriza sua cópia, em 10/10/2026. | Identificar quais letras são originais e quais são de terceiros; definir os termos da licença para cada conteúdo. A autoria de uma seleção não comprova autoria das letras. |
| Hinário e documentos da biblioteca | O desenvolvedor atribui os demais documentos à Igreja Presbiteriana do Brasil (IPB). | Confirmar o titular de cada texto/tradução e registrar a autorização ou licença de redistribuição. |
| NVI | A página oficial da tradução em português identifica a Biblica como titular dos direitos. | Documentar uma autorização/licença aplicável ao texto completo incluído no app. |
| JFAA, ARA, NTLH e BKJ | Ainda sem documentação de licença no repositório. | Identificar a edição e origem exatas e incluir os termos de redistribuição. |
| Logomarca IPM | Ainda sem documentação de licença no repositório. | Registrar autorização/licença para redistribuição da imagem. |

A declaração de titularidade não substitui uma licença. Não aplicar licenças aos materiais de terceiros sem autorização do respectivo titular.

Fontes:
- NVI em português: https://partners.biblica.com/?bible-translation=nova-versao-internacional-portuguese
- Permissões da Biblica: https://www.biblica.com/permissions/
- Política do F-Droid: https://f-droid.org/en/docs/Inclusion_Policy/

## Modelo para solicitar autorização

> Sou responsável pelo aplicativo Bíblia IPM, cujo código está disponível em https://github.com/alunoadsnoite/bibliaappipm. Gostaria de obter autorização para incluir [obra, edição, tradução e origem] integralmente nos assets do aplicativo, disponíveis offline, e redistribuí-los junto ao código-fonte e aos APKs pelo GitHub e pelo catálogo oficial do F-Droid. Poderiam indicar o titular dos direitos, a licença aplicável, as condições de redistribuição e os créditos exigidos? A publicação no F-Droid envolve compilação e redistribuição por terceiros.

## Investigação de procedência — 11/10/2026

### Evidências locais

Os JSONs não contêm links de origem ou termos de licença. O histórico introduz os textos nos commits `c420f65` (Android), `d31fb43` (Flutter) e `bff23da` (BKJ); esses registros não identificam a fonte do download. O último identifica BKJ como **King James Fiel 1611**, distinta da King James Atualizada da Abba Press.

Todos os cinco arquivos têm 66 livros e 1.189 capítulos. As contagens abaixo medem entradas JSON, não certificam integridade editorial:

| Arquivo | Entradas de versículos | SHA-256 |
| --- | ---: | --- |
| `biblia.json` (rotulado JFAA) | 31.102 | `899d445f1da283beb441baab9f44ca1c06d035f70adc0e4d1d156229fc86ae3c` |
| `biblia_ara.json` | 31.104 | `7d3fd7246ba80c4b3b4be48c787b788fa3ba3f5a8d7c806722f6f493147defcc` |
| `biblia_nvi.json` | 31.105 | `cdb6561abaf060002334b4b2ab00bbd8a1f448cfc25ee167490bc0cc3e879628` |
| `biblia_ntlh.json` | 31.088 | `5d84e30fd67dfa208eaefac9be1e0254758d7a6856fccb7c9cf400e180bbdb80` |
| `biblia_bkj.json` | 31.102 | `8308f2c803009e6f04dce7ee51929cd457706a603258c13e1ba6907eb9990d4e` |

### Fontes e conclusões limitadas

- **ARA/NTLH:** a própria SBB as inclui em seu catálogo de traduções. A página de leitura da NTLH informa copyright de 2000 da SBB. Não foi localizada licença livre de redistribuição integral nessas páginas.
  - https://www.sbb.com.br/produto/biblia-sagrada-traducoes-sbb-%E2%80%94-tb-arc-ra-naa-ntlh-letra-regular-com-mapa-capa-dura-azul-150775
  - https://www.sbb.org.br/biblia/
- **Possível família de dados ARA:** comparado `biblia_ara.json` com https://mrk214.github.io/snapshots/pt___por___por/ARA_vid_1608.json, listado em https://github.com/mrk214/bible-data-pt-por. Comparação por posição livro/capítulo/versículo, juntando as linhas do JSON externo e normalizando somente espaços e Unicode NFC: **25.208 de 31.104 entradas iguais**. Isso é semelhança textual, não prova de procedência direta. O arquivo externo declara `ARA © 1993 Sociedade Bíblica do Brasil`, embora o repositório tenha LICENSE MIT; não foi encontrada nele evidência de autorização da SBB para sublicenciar o texto.
- **NVI:** a Biblica declara copyright de 1993/2000/2011/2023 e direitos reservados. Seus termos distinguem citações de usos que exigem licença. Não foi comprovada permissão para os assets integrais deste aplicativo.
  - https://partners.biblica.com/?bible-translation=nova-versao-internacional-portuguese
  - https://www.biblica.com/permissions/
- **BKJ Fiel 1611:** há redações coincidentes e outras diferentes entre Gênesis 1 do arquivo e o site da BKJ. O FAQ atribui direitos da edição em português à BV Books, permite citar/usar o texto, mas não explicita licença livre para redistribuição integral, modificação e distribuição por terceiros. É necessário esclarecer esses termos e identificar a edição exata do arquivo; não atribuir automaticamente a BKJ à Abba Press.
  - https://bkjfiel.com.br/genesis-1/
  - https://bkjfiel.com.br/faq-perguntas-frequentes/
- **Novo Cântico/IPB:** a resolução CE-SC/IPB 2023 DOC. LVI trata da possibilidade de incorporar o hinário ao aplicativo do CHHM. Ela não fornece uma licença geral para aplicativos de terceiros.
  - https://ipb.org.br/content/conteudos/2575f344-4858-400c-82b3-e68534e22fa1_BPCadernoResolucoesjunho.pdf (página 25 do PDF)
- **Biblioteca:** inclui confissões/catecismos de Westminster, credos, mandamentos, cinco pontos do calvinismo, teses de Lutero, oração dominical e cinco solas. Antiguidade da obra original não identifica a tradução portuguesa nem a licença desta redação. A origem exata continua indeterminada.
- **JFAA:** o rótulo não identifica edição, ano ou responsável editorial. A procedência e a licença continuam indeterminadas.

### Situação para a avaliação

Mantidos todos os assets a pedido do desenvolvedor. A investigação não comprovou licença livre abrangente da IPB para os textos incluídos e não comprova titularidade pessoal sobre as traduções atribuídas publicamente a outras editoras. A declaração de autoria e autorização do desenvolvedor aplica-se aos materiais sobre os quais ele efetivamente detenha os direitos; não foi escolhido um texto de licença em seu nome. O pedido preliminar do F-Droid continua dependente da avaliação dos mantenedores e da documentação dessas permissões. Este registro reúne evidências técnicas e editoriais, sem emitir parecer jurídico.

## Complemento da investigação — 11/10/2026

- **Hinário:** a ata oficial CE-SC/IPB 2018, DOC. LIII, orienta o CHHM a resolver a questão submetida junto aos detentores dos direitos autorais. Isso não constitui licença geral para redistribuir o hinário; reforça que a relação institucional com a IPB, isoladamente, não documenta todas as permissões.
  - https://www.executivaipb.com.br/Atas_CE_SC/CE/Ata_CE_2018.pdf (páginas 34–35 do PDF)
- **BKJ:** a amostra editorial da Bíblia Jeffrey BKJ 1611, disponibilizada em seu site, identifica copyright da BV Films/BV Books. Na página impressa de créditos, a permissão geral de citação é limitada a um capítulo, 500 versículos e proporção do texto da obra; outros usos exigem permissão escrita. Esses termos pertencem à edição consultada, não comprovam qual edição originou o JSON do aplicativo, mas impedem interpretar a permissão genérica de citação do FAQ como licença irrestrita do texto completo.
  - https://bibliajeffrey.com.br/wp-content/uploads/2020/11/Livreto_Jeffrey.pdf (página 5 do PDF)

Não foram enviadas mensagens às editoras ou à IPB. A avaliação solicitada ao F-Droid permanece preliminar; não foi declarado cumprimento integral das condições de inclusão.
