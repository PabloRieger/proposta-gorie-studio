--[[
	Painel de compras: espadas, armaduras e melhorias.

	Mostra TUDO desde o começo, inclusive o que ainda não dá para pagar. Isso é
	de propósito: desejo precisa de alvo, e o item caro visível é o que faz o
	jogador voltar a matar monstro. O que ele nunca deve poder é comprar as três
	coisas que quer ao mesmo tempo — é a escolha que gera esforço, não a espera.

	Os preços aqui são espelho da config; quem cobra é o servidor, que recalcula
	tudo antes de tirar moeda.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Eventos = Compartilhado.Eventos
local Formato = Compartilhado.Formato
local Remotes = Compartilhado.Remotes

local Ui = require(script.Parent.Parent.Ui)
local Estado = require(script.Parent.Parent.Estado)

local player = Players.LocalPlayer
local Armas = Config.Armas
local Melhorias = Config.Melhorias

local Loja = { ordem = 30 }

local CORES_RARIDADE = {
	inicial = Color3.fromRGB(140, 146, 164),
	comum = Color3.fromRGB(176, 182, 198),
	incomum = Color3.fromRGB(120, 214, 152),
	raro = Color3.fromRGB(112, 170, 250),
	epico = Color3.fromRGB(186, 130, 250),
	lendario = Color3.fromRGB(252, 176, 84),
}

local painel: Frame? = nil
local linhas: { [string]: any } = {}
local estado = { melhorias = {}, inventario = {}, equipado = {} }

local remoteComprarItem = Remotes.obter("ComprarItem")
local remoteEquipar = Remotes.obter("EquiparItem")
local remoteMelhoria = Remotes.obter("ComprarMelhoria")

--- Estado de um equipamento para o jogador atual.
local function situacao(item): string
	if estado.equipado[Armas.tipoPorId[item.id]] == item.id then
		return "equipado"
	end
	if item.inicial or estado.inventario[item.id] then
		return "possui"
	end
	if not item.preco then
		return "sodebau"
	end
	return "aVenda"
end

local function atualizarEquipamento(id: string)
	local linha = linhas[id]
	local item = Armas.porId[id]
	if not linha or not item then
		return
	end

	local botao = linha.botao
	local caso = situacao(item)

	if caso == "equipado" then
		botao.Text = "EQUIPADO"
		botao.BackgroundColor3 = Ui.cores.sucesso
		botao.TextColor3 = Ui.cores.fundo
	elseif caso == "possui" then
		botao.Text = "EQUIPAR"
		botao.BackgroundColor3 = Ui.cores.cartaoClaro
		botao.TextColor3 = Ui.cores.texto
	elseif caso == "sodebau" then
		botao.Text = "SÓ DE BAÚ"
		botao.BackgroundColor3 = Ui.cores.cartaoClaro
		botao.TextColor3 = Ui.cores.textoFraco
	else
		local podePagar = Estado.ler("Moedas", 0) >= item.preco
		botao.Text = "💰 " .. Formato.abreviar(item.preco)
		botao.BackgroundColor3 = if podePagar then Ui.cores.moeda else Ui.cores.cartaoClaro
		botao.TextColor3 = if podePagar then Ui.cores.fundo else Ui.cores.textoFraco
	end
end

local function atualizarMelhoria(id: string)
	local linha = linhas[id]
	local definicao = Melhorias.porId[id]
	if not linha or not definicao then
		return
	end

	local nivel = estado.melhorias[id] or 0
	linha.detalhe.Text = ("%s  ·  nível %d / %d"):format(definicao.descricao, nivel, definicao.nivelMaximo)

	if nivel >= definicao.nivelMaximo then
		linha.botao.Text = "MÁXIMO"
		linha.botao.BackgroundColor3 = Ui.cores.cartaoClaro
		linha.botao.TextColor3 = Ui.cores.textoFraco
		return
	end

	local preco = Melhorias.preco(definicao, nivel)
	local podePagar = Estado.ler("Moedas", 0) >= preco
	linha.botao.Text = "💰 " .. Formato.abreviar(preco)
	linha.botao.BackgroundColor3 = if podePagar then Ui.cores.moeda else Ui.cores.cartaoClaro
	linha.botao.TextColor3 = if podePagar then Ui.cores.fundo else Ui.cores.textoFraco
end

local function atualizarTudo()
	for id, linha in linhas do
		if linha.tipo == "melhoria" then
			atualizarMelhoria(id)
		else
			atualizarEquipamento(id)
		end
	end
end

local function cabecalho(texto: string, ordem: number, pai: Instance)
	Ui.texto({
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = ordem,
		Text = texto,
		Font = Ui.fonteTitulo,
		TextSize = 13,
		TextColor3 = Ui.cores.textoFraco,
		Parent = pai,
	})
end

local function linhaBase(id: string, ordem: number, cor: Color3, titulo: string, pai: Instance)
	local cartao = Ui.novo("Frame", {
		Name = id,
		Size = UDim2.new(1, 0, 0, 62),
		LayoutOrder = ordem,
		BackgroundColor3 = Ui.cores.cartaoClaro,
		Parent = pai,
	}, { Ui.canto(10), Ui.contorno(cor, 1), Ui.margem(10) })

	Ui.texto({
		Size = UDim2.new(1, -150, 0, 20),
		Text = titulo,
		TextColor3 = cor,
		Font = Ui.fonteTitulo,
		TextSize = 15,
		Parent = cartao,
	})

	local detalhe = Ui.texto({
		Position = UDim2.fromOffset(0, 21),
		Size = UDim2.new(1, -150, 0, 20),
		Text = "",
		TextColor3 = Ui.cores.textoFraco,
		TextSize = 12,
		Parent = cartao,
	})

	local botao = Ui.novo("TextButton", {
		Name = "Acao",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(132, 38),
		AutoButtonColor = true,
		Text = "",
		Font = Ui.fonteTitulo,
		TextSize = 14,
		Parent = cartao,
	}, { Ui.canto(9) })

	return { detalhe = detalhe, botao = botao }
end

local function construirEquipamento(item, ordem: number, efeito: string, pai: Instance)
	local cor = CORES_RARIDADE[item.raridade] or Ui.cores.texto
	local linha = linhaBase(item.id, ordem, cor, item.nome, pai)

	linha.tipo = "equipamento"
	linha.detalhe.Text = efeito
	linha.botao.Activated:Connect(function()
		local caso = situacao(item)
		if caso == "possui" then
			remoteEquipar:FireServer(item.id)
		elseif caso == "aVenda" then
			remoteComprarItem:FireServer(item.id)
		end
	end)

	linhas[item.id] = linha
end

local function construirMelhoria(definicao, ordem: number, pai: Instance)
	local linha = linhaBase(
		definicao.id,
		ordem,
		Ui.cores.texto,
		definicao.icone .. "  " .. definicao.nome,
		pai
	)

	linha.tipo = "melhoria"
	linha.botao.Activated:Connect(function()
		remoteMelhoria:FireServer(definicao.id)
	end)

	linhas[definicao.id] = linha
end

function Loja.montar(ctx)
	painel = Ui.novo("Frame", {
		Name = "Loja",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(580, 500),
		BackgroundColor3 = Ui.cores.cartao,
		Visible = false,
		Parent = ctx.raiz,
	}, { Ui.canto(18), Ui.contorno(Ui.cores.moeda, 1.5), Ui.margem(18) })

	Ui.texto({
		Size = UDim2.new(1, -40, 0, 28),
		Text = "🛒  LOJA",
		Font = Ui.fonteTitulo,
		TextSize = 20,
		Parent = painel,
	})

	Ui.texto({
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, -40, 0, 18),
		Text = "Equipamento some ao evoluir. Melhorias ficam para sempre.",
		TextColor3 = Ui.cores.textoFraco,
		TextSize = 12,
		Parent = painel,
	})

	local fechar = Ui.novo("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = Ui.cores.cartaoClaro,
		Text = "✕",
		Font = Ui.fonteTitulo,
		TextSize = 16,
		TextColor3 = Ui.cores.texto,
		Parent = painel,
	}, { Ui.canto(10) })

	fechar.Activated:Connect(function()
		Loja.alternar(false)
	end)

	local rolagem = Ui.novo("ScrollingFrame", {
		Name = "Itens",
		Position = UDim2.fromOffset(0, 56),
		Size = UDim2.new(1, 0, 1, -56),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = Ui.cores.borda,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = painel,
	}, { Ui.lista(8) })

	local ordem = 0
	local function proxima(): number
		ordem += 1
		return ordem
	end

	cabecalho("⚔️  ESPADAS — quanto você tira por golpe", proxima(), rolagem)
	for _, espada in Armas.espadas do
		if not espada.inicial then
			construirEquipamento(espada, proxima(), ("dano x%s"):format(Formato.abreviar(espada.dano)), rolagem)
		end
	end

	cabecalho("🛡️  ARMADURAS — quanto tempo você fica de pé", proxima(), rolagem)
	for _, armadura in Armas.armaduras do
		if not armadura.inicial then
			construirEquipamento(
				armadura,
				proxima(),
				("-%d%% do contra-ataque"):format(math.floor(armadura.reducao * 100)),
				rolagem
			)
		end
	end

	cabecalho("⬆️  MELHORIAS — não somem ao evoluir", proxima(), rolagem)
	for _, definicao in Melhorias.lista do
		construirMelhoria(definicao, proxima(), rolagem)
	end

	Estado.observar({ "Moedas" }, atualizarTudo)
end

function Loja.ligar()
	Eventos.sinal("PedirLoja"):Connect(function()
		Loja.alternar()
	end)

	Remotes.obter("EstadoAtualizado").OnClientEvent:Connect(function(novo)
		if typeof(novo) ~= "table" then
			return
		end

		estado.melhorias = novo.melhorias or {}
		estado.inventario = novo.inventario or {}
		estado.equipado = novo.equipado or {}
		atualizarTudo()
	end)
end

function Loja.alternar(visivel: boolean?)
	if not painel then
		return
	end

	painel.Visible = if visivel == nil then not painel.Visible else visivel
end

return Loja
