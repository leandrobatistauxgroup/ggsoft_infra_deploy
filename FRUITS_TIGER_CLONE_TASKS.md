# Fruits → Clone Tiger

**Épico:** Fruits → Tiger Layout Clone
**Prazo:** 30/06/2026 | **Dias úteis:** 16

---

## Sprint 1 — Análise e Especificação (09–12/06)

**T01 - Levantar dimensões do Tiger**
Tipo: Análise | Prazo: 09/06
Medir canvas, grid de reels, símbolos, botões, win meter, bet selector e painel info.

**T02 - Mapear diferenças Fruits vs Tiger**
Tipo: Análise | Prazo: 10/06
Documentar delta de dimensões, posicionamentos, fontes, cores e animações.

**T03 - Criar especificação visual para UX**
Tipo: UX Briefing | Prazo: 11/06
Documento listando todos os assets necessários: símbolos, background, UI skin, estados de tela.

**T04 - Abrir demandas formais para o time UX**
Tipo: UX | Prazo: 11/06
Criar tickets com referências do Tiger para cada asset a ser produzido.

---

## Sprint 2 — Implementação Dev (13–20/06)

**T05 - Reajustar dimensões do canvas e grid de reels**
Tipo: Dev | Prazo: 13/06
Ajustar Config.hx e layout base para as proporções do Tiger.

**T06 - Reposicionar elementos de UI**
Tipo: Dev | Prazo: 16/06
Botões, win frame, bet selector e painel de informações.

**T07 - Ajustar animações**
Tipo: Dev | Prazo: 17/06
Velocidade de spin, animações de win, transições e efeitos especiais conforme Tiger.

**T08 - Integrar primeiros assets do UX**
Tipo: Dev | Prazo: 18/06
Substituir placeholders pelos assets entregues na 1ª rodada.

**T09 - Integrar assets finais do UX**
Tipo: UX + Dev | Prazo: 19/06
Receber entrega final do UX e integrar ao projeto.

---

## Sprint 3 — Testes e Ajustes Finos (23–30/06)

**T10 - Testes visuais: Fruits clone vs Tiger**
Tipo: QA | Prazo: 23/06
Checklist de fidelidade visual comparando os dois jogos.

**T11 - Testes funcionais**
Tipo: QA | Prazo: 24/06
Spin, free games, animações de win e responsividade.

**T12 - Correções pós-QA**
Tipo: Dev | Prazo: 25/06
Ajustar bugs visuais e funcionais apontados pelo QA.

**T13 - Build final e deploy em staging**
Tipo: Dev | Prazo: 27/06
Compilar Game.js e copiar para nginx/games/1.

**T14 - Validação final do layout**
Tipo: Aprovação | Prazo: 30/06
PO aprova comparando o clone com o Tiger original.

---

## Checklist de Análise (T01/T02)

- [ ] Canvas: largura x altura (px)
- [ ] Grid de reels: cols x rows, espaçamento, margin
- [ ] Símbolos: tamanho por símbolo, sprite sheet dims
- [ ] Background: dimensões, camadas
- [ ] Botões UI: spin, bet +/-, info, sound, fullscreen (posição X/Y e tamanho)
- [ ] Win frame/meter: posição, tamanho, fonte, animação
- [ ] Painel inferior: altura, elementos internos
- [ ] Animações: FPS do spin, duração win, efeito idle
- [ ] Fontes: família, tamanho, cor por contexto

---

## Fluxo de Dependências

T01 → T02 → T03 → T04 (UX começa a produzir)
T02 → T05 → T06 → T07
T07 → T08 (aguarda 1ª entrega UX) ← T09
T08 → T10 → T11 → T12 → T13 → T14
