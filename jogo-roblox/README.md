# Evolução Lendária

Jogo de Roblox do gênero *simulator de evolução*: treine, suba de rank, compre
melhorias e **evolua** — zerando a Força em troca de um multiplicador permanente.

Projeto completo e jogável: mapa, interface, persistência e balanceamento.

---

## Rodando pela primeira vez

Há dois caminhos. Comece pelo A se você só quer ver o jogo rodando.

### A. Arquivo de lugar pronto (sem instalar nada além do Studio)

```bash
cd jogo-roblox
python3 ferramentas/gerar-place.py     # gera EvolucaoLendaria.rbxlx
```

Abra o `.rbxlx` gerado com dois cliques (ou `File → Open from File` no Studio)
e aperte **Play**.

O arquivo é um retrato do código no momento em que foi gerado: ele **não**
acompanha edições em `src/`. Rode o script de novo depois de mexer no código,
ou use o caminho B para desenvolver. Por isso ele fica fora do versionamento —
um `.rbxlx` desatualizado no repositório engana mais do que ajuda.

### B. Rojo (fluxo de desenvolvimento)

O **Rojo** sincroniza os arquivos deste repositório com o Studio em tempo real:
você salva o `.lua` no editor e o Studio recebe na hora.

```bash
# 1. Instale a cadeia de ferramentas (rojo, selene, stylua)
#    Aftman: https://github.com/LPGhatguy/aftman
aftman install

# 2. Suba o servidor do Rojo na raiz de jogo-roblox/
rojo serve
```

No Studio:

1. Crie um lugar novo (`Baseplate` serve — o cenário padrão é removido em tempo
   de execução).
2. Instale o plugin do Rojo (`rojo plugin install`, ou pela aba Plugins).
3. Abra o painel do Rojo → **Connect**. O código aparece em
   `ReplicatedStorage`, `ServerScriptService` e `StarterPlayer`.
4. **Game Settings → Security → Enable Studio Access to API Services.** Sem
   isso o DataStore não funciona e o progresso não é salvo (o jogo cai para
   memória temporária e avisa no output).
5. **Play**.

> Sem Aftman: `cargo install rojo` ou baixe o binário em
> <https://github.com/rojo-rbx/rojo/releases>.

---

## O laço de jogo

1. **Treine** — clique, toque, segure `E` ou use o botão TREINAR. Parado dentro
   de uma zona você também ganha, só que mais devagar.
2. **Suba de rank** — o rank vem da Força atual, dá multiplicador e faz o
   personagem crescer.
3. **Avance de zona** — cada zona à frente rende mais e exige mais Força. A
   barreira abre sozinha quando você atinge o requisito.
4. **Compre melhorias** — com Moedas, na Loja. Elas **não** se perdem ao evoluir.
5. **Evolua** — no Altar do hub. Zera a Força, dá multiplicador permanente,
   título e uma aura nova.

---

## Mapa do código

```
src/
├── shared/                  ReplicatedStorage.Compartilhado
│   ├── Config/              todo o balanceamento
│   │   ├── Ranks.lua        títulos e multiplicadores por Força
│   │   ├── Zonas.lua        zonas + geometria do mapa
│   │   ├── Melhorias.lua    loja, preços e bônus
│   │   └── Evolucoes.lua    ladder de rebirth
│   ├── Formato.lua          "1.23M" a partir de 1234567
│   └── Remotes.lua          criação/consulta dos RemoteEvents
│
├── server/                  ServerScriptService.Servidor
│   ├── init.server.lua      ciclo de vida do jogador
│   ├── DataService.lua      DataStore, trava de sessão, autosave
│   ├── StatsService.lua     Força/Moedas/Evolução e multiplicadores
│   ├── TreinoService.lua    laço de ganho + validação de zona
│   ├── LojaService.lua      compras
│   ├── EvolucaoService.lua  rebirth
│   ├── PersonagemService.lua tamanho, velocidade e aura
│   └── MundoBuilder.lua     constrói o mapa a partir de Config.Zonas
│
└── client/                  StarterPlayer.StarterPlayerScripts.Cliente
    ├── init.client.lua      monta a interface e liga os pedidos
    ├── Ui.lua               tema e construtor de UI
    ├── HUD.lua              status, barra de rank, botões
    ├── Loja.lua             painel de melhorias
    ├── Barreiras.lua        libera as zonas conquistadas
    ├── Entrada.lua          clique/toque/tecla de treino
    └── Notificacoes.lua     avisos de topo

ferramentas/
└── gerar-place.py           monta um .rbxlx a partir de src/, sem Rojo
```

### Duas decisões que valem explicar

**O mapa é gerado por código.** `Config.Zonas` é a única fonte de verdade da
geometria: o `MundoBuilder` constrói as plataformas a partir dela e o
`TreinoService` valida a posição do jogador contra exatamente as mesmas caixas.
Mudar o mapa é mudar uma tabela — e não existe arquivo binário impossível de
revisar em *diff*.

**O cliente não decide nada.** Ele só avisa "cliquei" e "quero comprar isto".
Posição, requisito de zona, preço e saldo são recalculados no servidor a cada
ganho. As barreiras têm colisão desligada localmente (conveniência visual);
quem atravessar com exploit entra na zona e não recebe nada.

---

## Balanceamento

Os números não foram chutados: a curva foi ajustada por simulação até bater
alvos de ritmo. O comportamento atual, medido:

| Marco | Jogador ativo | Jogador AFK |
|---|---|---|
| 1ª evolução | ~14 min | ~50 min |
| 3ª evolução | ~48 min | ~3,4 h |
| Última zona | ~6,5 h | ~35 h |
| Evolução máxima | ~68 h | não alcança em 200 h |

As duas relações que sustentam isso:

- **Zonas** — requisito cresce ×12 por degrau, rendimento cresce ×2,1.
- **Evoluções** — requisito cresce ×8, multiplicador cresce ×2,2.

A sobra entre os dois é o que faz cada degrau custar mais tempo que o anterior.
Se você aproximar esses fatores, o jogo acelera sozinho e acaba em minutos —
foi exatamente o que aconteceu na primeira versão desta config.

Para rebalancear, mexa só em `src/shared/Config/`. Nenhum serviço tem número
mágico embutido.

---

## Próximos passos naturais

- **Monetização** — Game Passes (multiplicador x2, auto-treino) e Developer
  Products (pacote de Moedas). O gancho já existe: some um fator em
  `StatsService.multiplicadorForca`.
- **Pets/companheiros** — mais uma fonte de multiplicador, com inventário salvo
  no perfil.
- **Ranking global** — `OrderedDataStore` com a maior Força por evolução.
- **Sons e efeitos** — impacto no clique e no rank-up mudam muito a percepção.
- **Ícone e thumbnails** — na prática é o que mais move cliques na plataforma.
