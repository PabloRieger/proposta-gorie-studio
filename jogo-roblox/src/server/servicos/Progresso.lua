--[[
	Estado do jogador em jogo: Força, Moedas, Evolução, rank e multiplicadores.

	Os valores autoritativos ficam em ATRIBUTOS do Player. Atributos replicam
	sozinhos para todos os clientes, aceitam número de ponto flutuante (leaderstats
	com IntValue estoura em 2^31, e este jogo passa disso em poucas horas) e o
	cliente não consegue escrever neles. O leaderstats vira só vitrine, com
	StringValue formatado.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Formato = Compartilhado.Formato
local Remotes = Compartilhado.Remotes

local Melhorias = Config.Melhorias

local Progresso = { ordem = 20 }

local Dados

local perfis: { [Player]: any } = {}
local alterado = Instance.new("BindableEvent")

--- Dispara (player, perfil) sempre que algo relevante para o personagem muda.
Progresso.Alterado = alterado.Event

local remoteEstado = Remotes.obter("EstadoAtualizado")
local remoteNotificar = Remotes.obter("Notificar")

--- Evita replicação desnecessária: só escreve se o valor realmente mudou.
local function definir(player: Player, nome: string, valor: any)
	if player:GetAttribute(nome) ~= valor then
		player:SetAttribute(nome, valor)
	end
end

--- Índice do rank correspondente à Força (sempre >= 1).
function Progresso.indiceRank(forca: number): number
	local indice = 1
	for i, rank in Config.Ranks do
		if forca >= rank.forca then
			indice = i
		else
			break
		end
	end
	return indice
end

function Progresso.rankDe(forca: number)
	return Config.Ranks[Progresso.indiceRank(forca)]
end

function Progresso.evolucaoDe(nivel: number)
	return Config.Evolucoes[math.clamp(nivel + 1, 1, #Config.Evolucoes)]
end

function Progresso.proximaEvolucao(nivel: number)
	return Config.Evolucoes[nivel + 2]
end

function Progresso.obter(player: Player)
	return perfis[player]
end

--[[
	Multiplicadores da RECOMPENSA por boneco quebrado.

	Rank e evolução ficam de fora daqui de propósito: eles já multiplicam o
	dano, e um boneco vale o que vale. Ficar mais forte deve significar quebrar
	mais bonecos por minuto — não ganhar mais por boneco. Contar duas vezes
	transforma a curva em exponencial e o jogo se resolve sozinho.
]]
function Progresso.multiplicadorForca(player: Player): number
	local perfil = perfis[player]
	if not perfil then
		return 1
	end

	return 1 + Melhorias.bonus("treino", perfil.melhorias.treino or 0)
end

function Progresso.multiplicadorMoedas(player: Player): number
	local perfil = perfis[player]
	if not perfil then
		return 1
	end

	return 1 + Melhorias.bonus("fortuna", perfil.melhorias.fortuna or 0)
end

--[[
	Dano de um golpe.

	Repare no que NÃO entra aqui: a Força. Ela é placar e porteira — nunca
	alimenta o próprio ganho. Foi essa realimentação que fez a primeira versão
	do jogo se resolver sozinha em 14 minutos; o poder vem de equipamento e de
	evolução, que são finitos e conquistados.

	Espada e mascote ainda não existem (passos 2 e 5). Os ganchos ficam aqui
	valendo 1 para que entrar com eles depois seja preencher dado, não mexer
	em fórmula.
]]
function Progresso.dano(player: Player): number
	local perfil = perfis[player]
	if not perfil then
		return 0
	end

	local rank = Progresso.rankDe(perfil.forca)
	local evolucao = Progresso.evolucaoDe(perfil.evolucao)
	local punho = 1 + Melhorias.bonus("punho", perfil.melhorias.punho or 0)

	return Config.Geral.DANO_BASE
		* punho
		* rank.multiplicador
		* evolucao.multiplicador
		* Progresso.bonusEspada(player)
		* Progresso.bonusMascotes(player)
end

--- Passo 2. Sem espada equipada, o multiplicador é o punho nu.
function Progresso.bonusEspada(_player: Player): number
	return 1
end

--- Passo 5.
function Progresso.bonusMascotes(_player: Player): number
	return 1
end

function Progresso.notificar(player: Player, mensagem: string, tipo: string?)
	remoteNotificar:FireClient(player, mensagem, tipo or "info")
end

--[[
	Tabela não cabe em atributo, e a loja precisa dos níveis das melhorias.
	Este canal é caro, então só é usado quando algo de fato muda de nível —
	nunca no tick de treino.
]]
function Progresso.enviarEstado(player: Player)
	local perfil = perfis[player]
	if not perfil then
		return
	end

	remoteEstado:FireClient(player, {
		melhorias = perfil.melhorias,
		tempoJogado = perfil.tempoJogado,
	})
end

function Progresso.sincronizar(player: Player)
	local perfil = perfis[player]
	if not perfil then
		return
	end

	local indiceRank = Progresso.indiceRank(perfil.forca)
	local rank = Config.Ranks[indiceRank]
	local evolucao = Progresso.evolucaoDe(perfil.evolucao)
	local proxima = Progresso.proximaEvolucao(perfil.evolucao)

	local rankAnterior = player:GetAttribute("RankIndice") or indiceRank

	definir(player, "Forca", perfil.forca)
	definir(player, "Moedas", perfil.moedas)
	definir(player, "Reliquias", perfil.reliquias)
	definir(player, "Dano", Progresso.dano(player))
	definir(player, "Evolucao", perfil.evolucao)
	definir(player, "AutoLigado", perfil.autoLigado == true)
	definir(player, "RankIndice", indiceRank)
	definir(player, "RankNome", rank.nome)
	definir(player, "RankCor", rank.cor)
	definir(player, "EvolucaoNome", evolucao.nome)
	definir(player, "EvolucaoCor", evolucao.cor)
	definir(player, "MultForca", Progresso.multiplicadorForca(player))
	definir(player, "MultMoedas", Progresso.multiplicadorMoedas(player))
	definir(player, "ProximaEvolucaoNome", proxima and proxima.nome or "")
	definir(player, "ProximaEvolucaoForca", proxima and proxima.forcaNecessaria or 0)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats["Força"].Value = Formato.abreviar(perfil.forca)
		leaderstats["Moedas"].Value = Formato.abreviar(perfil.moedas)
		leaderstats["Relíquias"].Value = Formato.abreviar(perfil.reliquias)
		leaderstats["Evolução"].Value = evolucao.nome
	end

	if indiceRank > rankAnterior then
		Progresso.notificar(player, "Novo rank: " .. rank.nome .. "!", "sucesso")
	end

	alterado:Fire(player, perfil)
end

function Progresso.adicionarForca(player: Player, valor: number)
	local perfil = perfis[player]
	if not perfil or valor <= 0 then
		return
	end

	perfil.forca += valor
	Progresso.sincronizar(player)
end

function Progresso.adicionarReliquias(player: Player, valor: number)
	local perfil = perfis[player]
	if not perfil or valor <= 0 then
		return
	end

	perfil.reliquias += valor
	Progresso.sincronizar(player)
end

function Progresso.adicionarMoedas(player: Player, valor: number)
	local perfil = perfis[player]
	if not perfil or valor <= 0 then
		return
	end

	perfil.moedas += valor
	Progresso.sincronizar(player)
end

--[[
	Ganho do tick de treino. Existe separado dos dois anteriores porque o laço
	de treino credita Força e Moedas juntas: somar em duas chamadas dispararia
	`sincronizar` duas vezes por tick, por jogador, sem nada mudar entre elas.
]]
function Progresso.adicionarGanho(player: Player, forca: number, moedas: number)
	local perfil = perfis[player]
	if not perfil then
		return
	end

	if forca > 0 then
		perfil.forca += forca
	end
	if moedas > 0 then
		perfil.moedas += moedas
	end

	if forca > 0 or moedas > 0 then
		Progresso.sincronizar(player)
	end
end

--- Cobra as moedas se houver saldo. Retorna se a cobrança aconteceu.
function Progresso.gastarMoedas(player: Player, valor: number): boolean
	local perfil = perfis[player]
	if not perfil or perfil.moedas < valor then
		return false
	end

	perfil.moedas -= valor
	return true
end

function Progresso.iniciar(servicos)
	Dados = servicos.Dados
end

function Progresso.aoEntrar(player: Player)
	Progresso.registrar(player, Dados.obter(player))
end

function Progresso.aoSair(player: Player)
	Progresso.remover(player)
end

function Progresso.registrar(player: Player, perfil)
	perfis[player] = perfil

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	for _, nome in { "Força", "Moedas", "Relíquias", "Evolução" } do
		local vitrine = Instance.new("StringValue")
		vitrine.Name = nome
		vitrine.Value = "0"
		vitrine.Parent = leaderstats
	end

	leaderstats.Parent = player

	Progresso.sincronizar(player)
	Progresso.enviarEstado(player)
end

function Progresso.remover(player: Player)
	perfis[player] = nil
end

return Progresso
