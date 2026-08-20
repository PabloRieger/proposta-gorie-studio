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


local Evolucao = { ordem = 70 }

local Progresso

function Evolucao.iniciar(servicos)
	Progresso = servicos.Progresso

	local remoteEvoluir = Remotes.obter("PedirEvolucao")
	local remoteNotificar = Remotes.obter("Notificar")

	remoteEvoluir.OnServerEvent:Connect(function(player)
		local perfil = Progresso.obter(player)
		if not perfil then
			return
		end

		local proxima = Progresso.proximaEvolucao(perfil.evolucao)

		if not proxima then
			Progresso.notificar(player, "Você já alcançou a evolução máxima.", "info")
			return
		end

		if perfil.forca < proxima.forcaNecessaria then
			Progresso.notificar(
				player,
				"Faltam " .. Formato.abreviar(proxima.forcaNecessaria - perfil.forca) .. " de Força.",
				"erro"
			)
			return
		end

		perfil.evolucao += 1
		perfil.forca = 0

		Progresso.sincronizar(player)
		Progresso.enviarEstado(player)

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

return Evolucao
