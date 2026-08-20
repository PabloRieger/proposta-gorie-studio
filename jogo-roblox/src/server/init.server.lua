--[[
	Ponto de entrada do servidor.

	O ciclo de vida do jogador vive todo aqui, em vez de espalhado em cada
	serviço: fica óbvio em que ordem as coisas acontecem e é impossível um
	serviço rodar antes do perfil existir.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config

local MundoBuilder = require(script.MundoBuilder)
local DataService = require(script.DataService)
local StatsService = require(script.StatsService)
local PersonagemService = require(script.PersonagemService)
local TreinoService = require(script.TreinoService)
local LojaService = require(script.LojaService)
local EvolucaoService = require(script.EvolucaoService)

local function aoEntrar(player: Player)
	local perfil = DataService.carregar(player)

	if not perfil then
		-- Preferimos recusar a entrada a deixar o jogador começar do zero e
		-- salvar por cima do progresso que não conseguimos ler.
		player:Kick(
			"Não conseguimos carregar seu progresso agora.\n"
				.. "Entre de novo em alguns instantes — nada foi perdido."
		)
		return
	end

	-- O jogador pode ter saído durante o carregamento.
	if not player.Parent then
		DataService.descarregar(player)
		return
	end

	StatsService.registrar(player, perfil)
	PersonagemService.registrar(player)
end

local function aoSair(player: Player)
	StatsService.remover(player)
	DataService.descarregar(player)
end

MundoBuilder.construir()

DataService.iniciar(Config.Geral.INTERVALO_AUTOSAVE)
PersonagemService.iniciar()
TreinoService.iniciar()
LojaService.iniciar()
EvolucaoService.iniciar()

Players.PlayerAdded:Connect(aoEntrar)
Players.PlayerRemoving:Connect(aoSair)

-- Cobre quem já estava no servidor quando o script subiu (comum no Studio).
for _, player in Players:GetPlayers() do
	task.spawn(aoEntrar, player)
end

print("[Evolução Lendária] servidor pronto.")
