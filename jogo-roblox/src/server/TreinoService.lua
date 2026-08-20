--[[
	O laço central do jogo.

	Ganho passivo: a cada tick, quem estiver dentro da caixa de uma zona
	liberada ganha Força e Moedas.
	Ganho ativo: cliques valem alguns ticks de uma vez.

	O cliente nunca informa onde está nem quanto ganhou — ele só avisa "cliquei".
	A posição vem do HumanoidRootPart no servidor e o requisito da zona é
	revalidado em todo ganho. Assim, atravessar a barreira com exploit não
	rende nada.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Remotes = Compartilhado.Remotes

local StatsService = require(script.Parent.StatsService)

local TreinoService = {}

local ALTURA_ABAIXO = 6
local ALTURA_ACIMA = 45

local ultimoClique: { [Player]: number } = {}

--- Zona que contém o jogador, ou nil se ele estiver no hub/caminho.
local function zonaDoJogador(player: Player)
	local personagem = player.Character
	if not personagem then
		return nil
	end

	local raiz = personagem:FindFirstChild("HumanoidRootPart")
	local humano = personagem:FindFirstChildOfClass("Humanoid")
	if not raiz or not humano or humano.Health <= 0 then
		return nil
	end

	local posicao = (raiz :: BasePart).Position

	for _, zona in Config.Zonas do
		local centro = zona.posicao
		local meio = zona.tamanho * 0.5

		if
			math.abs(posicao.X - centro.X) <= meio.X
			and math.abs(posicao.Z - centro.Z) <= meio.Z
			and posicao.Y > centro.Y - ALTURA_ABAIXO
			and posicao.Y < centro.Y + ALTURA_ACIMA
		then
			return zona
		end
	end

	return nil
end

--- Concede o ganho de `quantidadeDeTicks` ticks. Retorna se houve ganho.
local function conceder(player: Player, quantidadeDeTicks: number): boolean
	local perfil = StatsService.obter(player)
	if not perfil then
		return false
	end

	local zona = zonaDoJogador(player)

	player:SetAttribute("ZonaAtual", zona and zona.nome or "")
	player:SetAttribute("ZonaBloqueada", zona ~= nil and perfil.forca < zona.forcaMinima)

	if not zona or perfil.forca < zona.forcaMinima then
		return false
	end

	StatsService.adicionarGanho(
		player,
		zona.forcaPorTick * quantidadeDeTicks * StatsService.multiplicadorForca(player),
		zona.moedasPorTick * quantidadeDeTicks * StatsService.multiplicadorMoedas(player)
	)

	return true
end

function TreinoService.iniciar()
	local remoteTreinar = Remotes.obter("TreinarPedido")

	remoteTreinar.OnServerEvent:Connect(function(player)
		local agora = os.clock()
		if agora - (ultimoClique[player] or 0) < Config.Geral.COOLDOWN_CLIQUE then
			return
		end
		ultimoClique[player] = agora

		conceder(player, StatsService.multiplicadorClique(player))
	end)

	Players.PlayerRemoving:Connect(function(player)
		ultimoClique[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(Config.Geral.INTERVALO_TICK)
			for _, player in Players:GetPlayers() do
				conceder(player, 1)
			end
		end
	end)
end

return TreinoService
