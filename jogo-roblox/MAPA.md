# Mapa do projeto

**Leia este arquivo antes de abrir qualquer outro.** Ele existe para que uma
mudança comece já sabendo qual arquivo abrir, em vez de varrer o código atrás
do lugar certo.

---

## Quero mudar… → abra

### Balanceamento e conteúdo (só tabela, nenhuma lógica)

| Quero mudar | Arquivo |
|---|---|
| Dano base, cooldown do golpe, alcance, velocidade, autosave | `src/shared/Config/Geral.lua` |
| Fases: porteira de Força, força dos monstros, cor, posição no mapa | `src/shared/Config/Zonas.lua` |
| Os 4 tiers de dificuldade e as receitas de corpo | `src/shared/Config/Monstros.lua` |
| Nome, silhueta e paleta das 40 espécies · trocar por modelo pronto | `src/shared/Config/Bestiario.lua` |
| Títulos e multiplicadores por Força, dentro de uma vida | `src/shared/Config/Ranks.lua` |
| Escada de evolução: requisito, multiplicador, cor da aura | `src/shared/Config/Evolucoes.lua` |
| Espadas e armaduras: dano, redução, preço, visual | `src/shared/Config/Armas.lua` |
| Melhorias por nível, preços e curva de preço | `src/shared/Config/Melhorias.lua` |

### Regras do jogo (servidor — `src/server/servicos/`)

| Quero mudar | Arquivo |
|---|---|
| Como o golpe resolve alvo, dano, morte e contra-ataque | `Combate.lua` |
| Fórmula de dano, multiplicadores, o que replica para a tela | `Progresso.lua` |
| Salvar, carregar, trava de sessão, o que sobrevive à evolução | `Dados.lua` |
| Geometria do mundo, monstros, barreiras, placas, iluminação | `Mundo.lua` |
| Tamanho, aura, velocidade, salto e equipamento visível | `Personagem.lua` |
| Validação de compra e de equipar | `Loja.lua` |
| O que acontece ao evoluir e **o que reseta** | `Evolucao.lua` |

### Interface (cliente — `src/client/paineis/`)

| Quero mudar | Arquivo |
|---|---|
| Cartão de números e barra de rank | `Placar.lua` |
| Botões de Loja e Evoluir | `Acoes.lua` |
| Botão BATER, AUTO, rótulo da zona, números de ganho | `Golpe.lua` |
| Painel de compras (espadas, armaduras, melhorias) | `Loja.lua` |
| Rótulo, barra de vida, morte e animação dos monstros | `Monstros.lua` |
| Avisos do topo | `Notificacoes.lua` |
| Liberação visual das barreiras | `Barreiras.lua` |
| Clique, toque e tecla de golpe | `Entrada.lua` |
| Prompts do Altar e da Loja | `Pedestais.lua` |
| Cores, fontes e construtor de UI | `src/client/Ui.lua` |

---

## Como adicionar coisa nova

**Um sistema no servidor** (chefe, baú, mascote, parkour): crie
`src/server/servicos/Nome.lua`. Nada mais é editado — o carregador acha sozinho.

```lua
local Nome = { ordem = 45 }        -- 10 dados · 20 progresso · 30 mundo
                                   -- 40 combate · 50 personagem · 60 loja · 70 evolução
local Progresso

function Nome.iniciar(servicos)    -- uma vez, na subida
	Progresso = servicos.Progresso -- dependência chega pronta: sem require, sem ciclo
end

function Nome.aoEntrar(player) end -- jogador entrou; devolver false aborta a entrada
function Nome.aoSair(player) end   -- jogador saiu

return Nome
```

**Uma interface**: crie `src/client/paineis/Nome.lua`.

```lua
local Nome = { ordem = 35 }

function Nome.montar(ctx)  -- ctx.raiz é onde desenhar (já tem a escala responsiva)
function Nome.ligar(ctx)   -- aqui ctx.paineis já está completo

return Nome
```

**Um evento entre sistemas**: use `Compartilhado.Eventos`. Quem emite não fica
sabendo quem escuta — é assim que o baú vai reagir ao chefe sem que o serviço do
chefe mude uma linha.

```lua
Eventos.emitir("ChefeDerrotado", player, chefe)
Eventos.sinal("ChefeDerrotado"):Connect(function(player, chefe) end)
```

**Um canal cliente↔servidor**: acrescente o nome em `src/shared/Remotes.lua`.

---

## Regras que sustentam a arquitetura

1. **Config não tem lógica; lógica não tem número.** Se você precisou digitar um
   número dentro de um serviço, ele estava no arquivo errado.
2. **O servidor decide, o cliente pede.** Alvo, dano, preço e saldo são sempre
   recalculados no servidor. O cliente manda "bati" e "quero comprar isto".
3. **Arte é opcional e substituível.** Toda espécie aceita `modelo = "Nome"`,
   procurado em `ReplicatedStorage/Modelos`. Achou, usa; não achou, monta o
   corpo procedural. Trocar arte nunca exige mexer em código, e nunca bloqueia
   o desenvolvimento.
4. **Estado do jogador vive em atributos do Player.** O cliente nunca guarda
   cópia — por isso a tela não tem como discordar do servidor.
5. **Id de item é para sempre.** Ele vai para o save do jogador. Por isso
   espadas usam `esp_*` e armaduras `arm_*`, e o índice em `Armas.lua` recusa
   subir com id repetido — uma colisão entrega a peça errada em silêncio.
6. **Força nunca alimenta a própria fórmula de ganho.** Ela é placar e porteira.
   O poder vem de equipamento e evolução, que são finitos. Ignorar isso já
   resolveu o jogo inteiro em 14 minutos uma vez.
7. **Pergunta é chamada direta; aviso é sinal.** Não transforme "quanto o
   jogador tem" em evento.

---

## Verificar antes de dar por pronto

```bash
# sintaxe dos arquivos Luau (baixe o luau-compile das releases do luau-lang)
find src -name '*.lua' -exec luau-compile --binary {} \; > /dev/null

# gerar o arquivo de lugar para abrir no Studio
python3 ferramentas/gerar-place.py
```
