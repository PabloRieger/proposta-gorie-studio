--[[
	Compra de melhorias.

	O cliente manda só o id. Nível, preço e saldo são recalculados aqui a
	partir do perfil — o preço que aparece na tela dele é apenas informativo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Formato = Compartilhado.Formato
local Remotes = Compartilhado.Remotes

local StatsService = require(script.Parent.StatsService)

local Melhorias = Config.Melhorias
local LojaService = {}

local ultimaCompra: { [Player]: number } = {}

function LojaService.iniciar()
	local remoteComprar = Remotes.obter("ComprarMelhoria")

	remoteComprar.OnServerEvent:Connect(function(player, id)
		if typeof(id) ~= "string" then
			return
		end

		local agora = os.clock()
		if agora - (ultimaCompra[player] or 0) < Config.Geral.COOLDOWN_COMPRA then
			return
		end
		ultimaCompra[player] = agora

		local definicao = Melhorias.porId[id]
		local perfil = StatsService.obter(player)
		if not definicao or not perfil then
			return
		end

		local nivel = perfil.melhorias[id] or 0

		if nivel >= definicao.nivelMaximo then
			StatsService.notificar(player, definicao.nome .. " já está no nível máximo.", "erro")
			return
		end

		local preco = Melhorias.preco(definicao, nivel)

		if not StatsService.gastarMoedas(player, preco) then
			StatsService.notificar(
				player,
				"Faltam " .. Formato.abreviar(preco - perfil.moedas) .. " moedas.",
				"erro"
			)
			return
		end

		perfil.melhorias[id] = nivel + 1

		StatsService.sincronizar(player)
		StatsService.enviarEstado(player)
		StatsService.notificar(
			player,
			definicao.nome .. " agora está no nível " .. (nivel + 1) .. ".",
			"sucesso"
		)
	end)

	Players.PlayerRemoving:Connect(function(player)
		ultimaCompra[player] = nil
	end)
end

return LojaService
