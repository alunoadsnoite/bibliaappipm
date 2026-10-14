# Licenças dos conteúdos empacotados

Este inventário descreve a etapa intermediária 5.5.0. A conformidade integral
não foi comprovada: obras originais antigas não estabelecem a licença de suas
traduções modernas. Os documentos foram removidos da edição independente
[Bíblia Livre IPM](https://github.com/alunoadsnoite/biblia-livre-ipm).

A licença MIT do código não se aplica aos textos, que mantêm suas próprias
licenças (abaixo).

## Bíblia (`flutter/assets/biblia_*.json`)

Quatro traduções livres, no formato `[{abbr,name,chapters}]` com 66 livros e
1.189 capítulos:

| Asset | Tradução | Licença | Origem |
| --- | --- | --- | --- |
| `biblia_blivre.json` | Bíblia Livre (BLIVRE) | Creative Commons Atribuição 3.0 Brasil (CC BY 3.0 BR) | Diego Santos, Mario Sérgio e Marco Teles — http://sites.google.com/site/biblialivre/ |
| `biblia_bpm.json` | Bíblia Portuguesa Mundial (BPM) | Domínio público | eBible.org — https://ebible.org/ (porbrbsl) |
| `biblia_jfaal.json` | João Ferreira de Almeida Atualizada Livre (JFAAL) | MIT | Projeto BibliaJFAAL — https://github.com/BibliaJFAAL |
| `biblia_1911.json` | Almeida 1911 | Domínio público | Almeida e Silva (edições de 1911) |

Observações:

- **BLIVRE** exige a menção da fonte e dos autores. Crédito: "Bíblia Livre
  (BLIVRE), Copyright © Diego Santos, Mario Sérgio e Marco Teles, fevereiro de
  2018. Licença Creative Commons Atribuição 3.0 Brasil."
- **BPM** é declarada de domínio público pela eBible.org e está em revisão
  (rascunho). Versículos ausentes nos manuscritos mais antigos aparecem
  numerados com a marca `[Versículo não incluído nesta tradução.]`, preservando
  a numeração canônica.
- **JFAAL** é distribuída sob licença MIT (arquivo `LICENSE` do projeto).
- A **Almeida 1911** é de domínio público por expiração de prazo.

## Hinário (`flutter/assets/hinos.json`)

- Obra: **Salmos e Hinos**, edição de 1880.
- Licença: **domínio público** (obra publicada em 1880; prazo autoral expirado).
- Transcrição obtida por reconhecimento óptico de caracteres (OCR) a partir do
  exemplar digitalizado do Internet Archive (`psalmosehymnos00unse`).
- Contém 287 hinos; a numeração preserva a da edição. Pequenos ruídos de OCR
  podem permanecer no texto transcrito.

## Biblioteca (`flutter/assets/biblioteca.json`)

Documentos clássicos, cujas obras originais estão em domínio público:

- Confissão de Fé de Westminster (1646), Catecismo Maior (1647) e Catecismo
  Menor (1647).
- Credo Apostólico e Credo Niceno.
- Os Dez Mandamentos (Êxodo 20 — texto da Bíblia Portuguesa Mundial, domínio
  público).
- Os Cinco Pontos do Calvinismo (Cânones de Dort, 1619).
- As 95 Teses de Lutero (1517).
- Oração Dominical (Mateus 6.9-13 e Lucas 11.2-4 — texto da Bíblia Portuguesa
  Mundial, domínio público).
- As Cinco Solas da Reforma.

As citações bíblicas dos Dez Mandamentos e da Oração Dominical usam a
**Bíblia Portuguesa Mundial** (domínio público), substituindo citações
anteriores da ARA.

## Outros

| Asset | Descrição | Licença/observação |
| --- | --- | --- |
| `flutter/assets/redletter.json` | Índice das falas de Jesus e de Deus por livro/capítulo/versículo | Dado factual derivado das traduções livres empacotadas |
| `flutter/assets/boletim.json` | Estrutura vazia do boletim (`{"aniversariantes":[],"eventos":[]}`) | Sem conteúdo de terceiros |
| `flutter/assets/logo_ipm.png` | Logomarca IPM | Usada pelo desenvolvedor/titular; redistribuída para identificação do app |

## Músicas

O cancioneiro empacotado anteriormente foi **removido** (não havia
documentação de licença das letras). A aba Músicas continua permitindo que o
próprio usuário cadastre, edite e leia suas letras, armazenadas localmente.

## App Java legado (`app/src/main/assets/`)

O app nativo Android legado foi alinhado ao mesmo conjunto de conteúdos livres
(quatro traduções e hinário) e seu cancioneiro empacotado foi esvaziado.

## Referências

- Política de inclusão do F-Droid: https://f-droid.org/en/docs/Inclusion_Policy/
- BLIVRE: http://sites.google.com/site/biblialivre/ (CC BY 3.0 BR)
- eBible.org (BPM, domínio público): https://ebible.org/
