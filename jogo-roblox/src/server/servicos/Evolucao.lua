--[[
	Evolução (rebirth): zera a Força em troca de um multiplicador permanente.

	O QUE SOBREVIVE, e por quê:

	  Moedas, melhorias, relíquias   ficam. São o que faz o ciclo seguinte ser
	                                 mais rápido e dá avanço mesmo "perdendo".
	  Itens de baú e lendários       ficam. Foram conquistados, não comprados.
	  Espadas e armaduras compradas  SOMEM.

	A última é a regra que sustenta a economia inteira. Se equipamento comprado
	ficasse para sempre, a loja importaria durante uma vida e nunca mais — o
	jogador compra tudo uma vez e o esforço acaba. Zerando as compras, a loja
	volta a valer em todas as vidas, só que cada vez você re-equipa mais rápido,
	porque o que veio de chefe continuou com você.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Formato = Compartilhado.Formato
local Remotes = Compartilhado.Remotes


local Evolucao = { ordem = 70 }

local Progresso

--[[
	Devolve ao inventário só o que foi conquistado. Percorrer e remover é mais
	seguro do que zerar e recolocar: um item novo de origem desconhecida
	permanece, em vez de sumir por descuido.
]]
function Evolucao.limparEquipamentoComprado(perfil)
	for id, origem in perfil.inventario do
		if origem == "comprado" then
			perfil.inventario[id] = nil
		end
	end

	-- Equipado que não sobreviveu volta para a peça inicial.
	for tipo, id in perfil.equipado do
		if id and not perfil.inventario[id] then
			perfil.equipado[tipo] = nil
		end
	end
end

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
		Evolucao.limparEquipamentoComprado(perfil)

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
