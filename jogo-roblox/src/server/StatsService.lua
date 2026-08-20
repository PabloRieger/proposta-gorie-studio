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

local StatsService = {}

local perfis: { [Player]: any } = {}
local alterado = Instance.new("BindableEvent")

--- Dispara (player, perfil) sempre que algo relevante para o personagem muda.
StatsService.Alterado = alterado.Event

local remoteEstado = Remotes.obter("EstadoAtualizado")
local remoteNotificar = Remotes.obter("Notificar")

--- Evita replicação desnecessária: só escreve se o valor realmente mudou.
local function definir(player: Player, nome: string, valor: any)
	if player:GetAttribute(nome) ~= valor then
		player:SetAttribute(nome, valor)
	end
end

--- Índice do rank correspondente à Força (sempre >= 1).
function StatsService.indiceRank(forca: number): number
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

function StatsService.rankDe(forca: number)
	return Config.Ranks[StatsService.indiceRank(forca)]
end

function StatsService.evolucaoDe(nivel: number)
	return Config.Evolucoes[math.clamp(nivel + 1, 1, #Config.Evolucoes)]
end

function StatsService.proximaEvolucao(nivel: number)
	return Config.Evolucoes[nivel + 2]
end

function StatsService.obter(player: Player)
	return perfis[player]
end

function StatsService.multiplicadorForca(player: Player): number
	local perfil = perfis[player]
	if not perfil then
		return 1
	end

	local rank = StatsService.rankDe(perfil.forca)
	local evolucao = StatsService.evolucaoDe(perfil.evolucao)
	local bonusTreino = 1 + Melhorias.bonus("treino", perfil.melhorias.treino or 0)

	return rank.multiplicador * evolucao.multiplicador * bonusTreino
end

function StatsService.multiplicadorMoedas(player: Player): number
	local perfil = perfis[player]
	if not perfil then
		return 1
	end

	local bonusFortuna = 1 + Melhorias.bonus("fortuna", perfil.melhorias.fortuna or 0)
	local bonusEvolucao = 1 + perfil.evolucao * 0.1

	return bonusFortuna * bonusEvolucao
end

function StatsService.multiplicadorClique(player: Player): number
	local perfil = perfis[player]
	if not perfil then
		return 1
	end

	return Config.Geral.MULTIPLICADOR_CLIQUE
		* (1 + Melhorias.bonus("punho", perfil.melhorias.punho or 0))
end

function StatsService.notificar(player: Player, mensagem: string, tipo: string?)
	remoteNotificar:FireClient(player, mensagem, tipo or "info")
end

--[[
	Tabela não cabe em atributo, e a loja precisa dos níveis das melhorias.
	Este canal é caro, então só é usado quando algo de fato muda de nível —
	nunca no tick de treino.
]]
function StatsService.enviarEstado(player: Player)
	local perfil = perfis[player]
	if not perfil then
		return
	end

	remoteEstado:FireClient(player, {
		melhorias = perfil.melhorias,
		tempoJogado = perfil.tempoJogado,
	})
end

function StatsService.sincronizar(player: Player)
	local perfil = perfis[player]
	if not perfil then
		return
	end

	local indiceRank = StatsService.indiceRank(perfil.forca)
	local rank = Config.Ranks[indiceRank]
	local evolucao = StatsService.evolucaoDe(perfil.evolucao)
	local proxima = StatsService.proximaEvolucao(perfil.evolucao)

	local rankAnterior = player:GetAttribute("RankIndice") or indiceRank

	definir(player, "Forca", perfil.forca)
	definir(player, "Moedas", perfil.moedas)
	definir(player, "Evolucao", perfil.evolucao)
	definir(player, "RankIndice", indiceRank)
	definir(player, "RankNome", rank.nome)
	definir(player, "RankCor", rank.cor)
	definir(player, "EvolucaoNome", evolucao.nome)
	definir(player, "EvolucaoCor", evolucao.cor)
	definir(player, "MultForca", StatsService.multiplicadorForca(player))
	definir(player, "MultMoedas", StatsService.multiplicadorMoedas(player))
	definir(player, "ProximaEvolucaoNome", proxima and proxima.nome or "")
	definir(player, "ProximaEvolucaoForca", proxima and proxima.forcaNecessaria or 0)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats["Força"].Value = Formato.abreviar(perfil.forca)
		leaderstats["Moedas"].Value = Formato.abreviar(perfil.moedas)
		leaderstats["Evolução"].Value = evolucao.nome
	end

	if indiceRank > rankAnterior then
		StatsService.notificar(player, "Novo rank: " .. rank.nome .. "!", "sucesso")
	end

	alterado:Fire(player, perfil)
end

function StatsService.adicionarForca(player: Player, valor: number)
	local perfil = perfis[player]
	if not perfil or valor <= 0 then
		return
	end

	perfil.forca += valor
	StatsService.sincronizar(player)
end

function StatsService.adicionarMoedas(player: Player, valor: number)
	local perfil = perfis[player]
	if not perfil or valor <= 0 then
		return
	end

	perfil.moedas += valor
	StatsService.sincronizar(player)
end

--[[
	Ganho do tick de treino. Existe separado dos dois anteriores porque o laço
	de treino credita Força e Moedas juntas: somar em duas chamadas dispararia
	`sincronizar` duas vezes por tick, por jogador, sem nada mudar entre elas.
]]
function StatsService.adicionarGanho(player: Player, forca: number, moedas: number)
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
		StatsService.sincronizar(player)
	end
end

--- Cobra as moedas se houver saldo. Retorna se a cobrança aconteceu.
function StatsService.gastarMoedas(player: Player, valor: number): boolean
	local perfil = perfis[player]
	if not perfil or perfil.moedas < valor then
		return false
	end

	perfil.moedas -= valor
	return true
end

function StatsService.registrar(player: Player, perfil)
	perfis[player] = perfil

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	for _, nome in { "Força", "Moedas", "Evolução" } do
		local vitrine = Instance.new("StringValue")
		vitrine.Name = nome
		vitrine.Value = "0"
		vitrine.Parent = leaderstats
	end

	leaderstats.Parent = player

	StatsService.sincronizar(player)
	StatsService.enviarEstado(player)
end

function StatsService.remover(player: Player)
	perfis[player] = nil
end

return StatsService
