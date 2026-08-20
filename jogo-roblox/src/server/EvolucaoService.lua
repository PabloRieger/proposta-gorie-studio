--[[
	Evolução (rebirth): zera a Força em troca de um multiplicador permanente.

	Moedas e melhorias sobrevivem de propósito — é o que faz o ciclo seguinte
	ser muito mais rápido e dá a sensação de avanço mesmo "perdendo" tudo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Formato = Compartilhado.Formato
local Remotes = Compartilhado.Remotes

local StatsService = require(script.Parent.StatsService)

local EvolucaoService = {}

function EvolucaoService.iniciar()
	local remoteEvoluir = Remotes.obter("PedirEvolucao")
	local remoteNotificar = Remotes.obter("Notificar")

	remoteEvoluir.OnServerEvent:Connect(function(player)
		local perfil = StatsService.obter(player)
		if not perfil then
			return
		end

		local proxima = StatsService.proximaEvolucao(perfil.evolucao)

		if not proxima then
			StatsService.notificar(player, "Você já alcançou a evolução máxima.", "info")
			return
		end

		if perfil.forca < proxima.forcaNecessaria then
			StatsService.notificar(
				player,
				"Faltam " .. Formato.abreviar(proxima.forcaNecessaria - perfil.forca) .. " de Força.",
				"erro"
			)
			return
		end

		perfil.evolucao += 1
		perfil.forca = 0

		StatsService.sincronizar(player)
		StatsService.enviarEstado(player)

		local anuncio = string.format(
			"%s evoluiu para %s (x%.1f de Força)!",
			player.DisplayName,
			proxima.nome,
			proxima.multiplicador
		)

		for _, outro in Players:GetPlayers() do
			remoteNotificar:FireClient(outro, anuncio, if outro == player then "sucesso" else "info")
		end

		-- Renasce no hub com o corpo e a aura já atualizados.
		player:LoadCharacter()
	end)
end

return EvolucaoService
