# Evolução Lendária

Jogo de Roblox do gênero *simulator de evolução*: bata nos bonecos de treino,
suba de rank, compre melhorias e **evolua** — zerando a Força em troca de um
multiplicador permanente.

> **Comece por [`MAPA.md`](MAPA.md).** Ele diz qual arquivo abrir para cada tipo
> de mudança, e é o que evita varrer o código atrás do lugar certo.

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

1. **Bata nos bonecos** — clique, toque, segure `E` ou use o botão BATER. Há um
   botão AUTO, que bate mais devagar de propósito. Parado não rende nada.
2. **Suba os quatro bonecos da fase** — cada degrau cobra algo que o anterior
   não cobrava: espada, armadura e, no quarto, equipamento que a loja não vende.
3. **Suba de rank** — o rank vem da Força atual, multiplica o dano e faz o
   personagem crescer.
4. **Avance de fase** — quem destrava a próxima é a Força. A barreira abre
   sozinha ao atingir o requisito.
5. **Compre melhorias** — com Moedas, na Loja. Elas **não** se perdem ao evoluir.
6. **Evolua** — no Altar do hub. Zera a Força, dá multiplicador permanente,
   título e uma aura nova.

---

## Mapa do código

```
src/
├── shared/                  ReplicatedStorage.Compartilhado
│   ├── Config/              TODO o balanceamento (nenhuma lógica)
│   │   ├── Geral.lua        dano base, cooldowns, autosave
│   │   ├── Ranks.lua        títulos e multiplicadores por Força
│   │   ├── Zonas.lua        as fases + geometria do mapa
│   │   ├── Bonecos.lua      os 4 tiers de boneco
│   │   ├── Melhorias.lua    loja, preços e bônus
│   │   └── Evolucoes.lua    escada de rebirth
│   ├── Formato.lua          "1.23M" a partir de 1234567
│   ├── Remotes.lua          canais cliente↔servidor
│   └── Eventos.lua          sinais entre sistemas
│
├── server/
│   ├── init.server.lua      carregador — não muda ao somar sistema
│   └── servicos/            um arquivo por sistema
│       ├── Dados.lua        DataStore, trava de sessão, autosave
│       ├── Progresso.lua    Força/Moedas/Evolução, dano, multiplicadores
│       ├── Mundo.lua        constrói mapa e bonecos a partir da config
│       ├── Combate.lua      resolve golpe, vida por jogador, recompensa
│       ├── Personagem.lua   tamanho, aura, velocidade e salto
│       ├── Loja.lua         validação de compra
│       └── Evolucao.lua     rebirth
│
└── client/
    ├── init.client.lua      carregador — não muda ao somar painel
    ├── Ui.lua               tema e construtor de interface
    ├── Estado.lua           lê e observa os atributos do jogador
    └── paineis/             um arquivo por pedaço de tela
        ├── Placar.lua       cartão de números e barra de rank
        ├── Acoes.lua        botões de Loja e Evoluir
        ├── Golpe.lua        BATER, AUTO, zona e números de ganho
        ├── Loja.lua         painel de compras
        ├── Bonecos.lua      rótulo, barra de vida e quebra
        ├── Notificacoes.lua avisos do topo
        ├── Barreiras.lua    liberação visual das fases
        ├── Entrada.lua      clique, toque e tecla
        └── Pedestais.lua    prompts do Altar e da Loja

ferramentas/
└── gerar-place.py           monta um .rbxlx a partir de src/, sem Rojo
```

### Três decisões que valem explicar

**Os arquivos de entrada não conhecem ninguém pelo nome.** Somar um sistema é
criar um arquivo em `servicos/` (ou `paineis/`); o carregador acha, ordena e
injeta as dependências. Nenhum arquivo existente é editado — que é justamente o
custo que mais pesa quando um projeto cresce.


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

> ⚠️ **Esses números são da versão anterior, sem combate.** A troca de renda por
> tempo para dano em boneco invalida a curva: agora há vida, dano exigido e
> recompensa por quebra no meio. O rebalanceamento por simulação está previsto
> para depois que chefe, equipamento e mascote existirem — estimar na mão, com
> tantas variáveis, já deu errado uma vez.

As duas relações que ainda valem:

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
