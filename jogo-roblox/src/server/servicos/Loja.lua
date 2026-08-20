--[[
	Compras: melhorias por nível e equipamento.

	O cliente manda só o id. Nível, preço, saldo e posse são recalculados aqui
	a partir do perfil — o que aparece na tela dele é apenas informativo.

	Duas moedas distintas de propósito. Melhoria e equipamento saem de Moedas,
	que jorram de matar monstro. Épico e lendário não têm preço aqui: só caem
	de chefe. É o que impede o jogador de acampar num monstro a vida inteira e
	comprar o jogo todo sem nunca subir.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Formato = Compartilhado.Formato
local Remotes = Compartilhado.Remotes

local Armas = Config.Armas
local Melhorias = Config.Melhorias

local Loja = { ordem = 60 }

local Progresso

local ultimaAcao: { [Player]: number } = {}

--- Anti-spam. Devolve se o pedido deve ser atendido.
local function podeAgir(player: Player): boolean
	local agora = os.clock()
	if agora - (ultimaAcao[player] or 0) < Config.Geral.COOLDOWN_COMPRA then
		return false
	end
	ultimaAcao[player] = agora
	return true
end

local function cobrar(player: Player, preco: number, nome: string): boolean
	local perfil = Progresso.obter(player)
	if not perfil then
		return false
	end

	if not Progresso.gastarMoedas(player, preco) then
		Progresso.notificar(
			player,
			("Faltam %s moedas para %s."):format(Formato.abreviar(preco - perfil.moedas), nome),
			"erro"
		)
		return false
	end

	return true
end

local function comprarMelhoria(player: Player, id: string)
	local definicao = Melhorias.porId[id]
	local perfil = Progresso.obter(player)
	if not definicao or not perfil then
		return
	end

	local nivel = perfil.melhorias[id] or 0

	if nivel >= definicao.nivelMaximo then
		Progresso.notificar(player, definicao.nome .. " já está no nível máximo.", "erro")
		return
	end

	if not cobrar(player, Melhorias.preco(definicao, nivel), definicao.nome) then
		return
	end

	perfil.melhorias[id] = nivel + 1

	Progresso.sincronizar(player)
	Progresso.enviarEstado(player)
	Progresso.notificar(
		player,
		("%s agora está no nível %d."):format(definicao.nome, nivel + 1),
		"sucesso"
	)
end

local function comprarItem(player: Player, id: string)
	local item = Armas.porId[id]
	if not item then
		return
	end

	if not item.preco then
		-- Épico e lendário não se compram: caem de chefe.
		Progresso.notificar(player, item.nome .. " não está à venda.", "erro")
		return
	end

	if Progresso.possui(player, id) then
		Progresso.notificar(player, "Você já tem " .. item.nome .. ".", "info")
		return
	end

	if not cobrar(player, item.preco, item.nome) then
		return
	end

	Progresso.adicionarItem(player, id, "comprado")
	Progresso.equipar(player, id)
	Progresso.notificar(player, item.nome .. " comprada e equipada!", "sucesso")
end

local function equiparItem(player: Player, id: string)
	local item = Armas.porId[id]
	if not item then
		return
	end

	if Progresso.equipar(player, id) then
		Progresso.notificar(player, item.nome .. " equipada.", "sucesso")
	else
		Progresso.notificar(player, "Você ainda não tem " .. item.nome .. ".", "erro")
	end
end

function Loja.aoSair(player: Player)
	ultimaAcao[player] = nil
end

function Loja.iniciar(servicos)
	Progresso = servicos.Progresso

	local canais = {
		[Remotes.obter("ComprarMelhoria")] = comprarMelhoria,
		[Remotes.obter("ComprarItem")] = comprarItem,
		[Remotes.obter("EquiparItem")] = equiparItem,
	}

	for remote, tratador in canais do
		remote.OnServerEvent:Connect(function(player, id)
			if typeof(id) == "string" and Progresso.obter(player) and podeAgir(player) then
				tratador(player, id)
			end
		end)
	end
end

return Loja
