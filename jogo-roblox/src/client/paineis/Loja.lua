--[[
	Painel de melhorias.

	Os preços mostrados aqui são espelho da mesma função que o servidor usa
	para cobrar (Config.Melhorias.preco). Se divergirem, o servidor vence.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Formato = Compartilhado.Formato
local Remotes = Compartilhado.Remotes

local Ui = require(script.Parent.Parent.Ui)

local player = Players.LocalPlayer
local Melhorias = Config.Melhorias

local Loja = { ordem = 30 }

local Eventos = Compartilhado.Eventos

local remoteComprar = Remotes.obter("ComprarMelhoria")

local painel: Frame? = nil
local linhas: { [string]: any } = {}
local niveis: { [string]: number } = {}

local function atualizarLinha(id: string)
	local linha = linhas[id]
	if not linha then
		return
	end

	local definicao = Melhorias.porId[id]
	local nivel = niveis[id] or 0
	local moedas = player:GetAttribute("Moedas") or 0
	local maximo = nivel >= definicao.nivelMaximo

	linha.nivel.Text = string.format("Nível %d / %d", nivel, definicao.nivelMaximo)

	if maximo then
		linha.comprar.Text = "MÁXIMO"
		linha.comprar.BackgroundColor3 = Ui.cores.cartaoClaro
		linha.comprar.TextColor3 = Ui.cores.textoFraco
		return
	end

	local preco = Melhorias.preco(definicao, nivel)
	local podePagar = moedas >= preco

	linha.comprar.Text = "💰 " .. Formato.abreviar(preco)
	linha.comprar.BackgroundColor3 = if podePagar then Ui.cores.moeda else Ui.cores.cartaoClaro
	linha.comprar.TextColor3 = if podePagar then Ui.cores.fundo else Ui.cores.textoFraco
end

local function atualizarTudo()
	for id in linhas do
		atualizarLinha(id)
	end
end

local function construirLinha(definicao, pai: Instance, ordem: number)
	local cartao = Ui.novo("Frame", {
		Name = definicao.id,
		Size = UDim2.new(1, 0, 0, 76),
		LayoutOrder = ordem,
		BackgroundColor3 = Ui.cores.cartaoClaro,
		Parent = pai,
	}, {
		Ui.canto(12),
		Ui.contorno(),
		Ui.margem(12),
	})

	Ui.texto({
		Size = UDim2.fromOffset(40, 40),
		Text = definicao.icone,
		TextSize = 28,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = cartao,
	})

	Ui.texto({
		Position = UDim2.fromOffset(48, 0),
		Size = UDim2.new(1, -190, 0, 20),
		Text = definicao.nome,
		Font = Ui.fonteTitulo,
		TextSize = 16,
		Parent = cartao,
	})

	Ui.texto({
		Position = UDim2.fromOffset(48, 20),
		Size = UDim2.new(1, -190, 0, 18),
		Text = definicao.descricao,
		TextColor3 = Ui.cores.textoFraco,
		TextSize = 13,
		Parent = cartao,
	})

	local nivel = Ui.texto({
		Position = UDim2.fromOffset(48, 38),
		Size = UDim2.new(1, -190, 0, 16),
		Text = "",
		TextColor3 = Ui.cores.sucesso,
		TextSize = 12,
		Font = Ui.fonteTitulo,
		Parent = cartao,
	})

	local comprar = Ui.novo("TextButton", {
		Name = "Comprar",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(120, 40),
		BackgroundColor3 = Ui.cores.moeda,
		AutoButtonColor = true,
		Text = "",
		Font = Ui.fonteTitulo,
		TextSize = 16,
		TextColor3 = Ui.cores.fundo,
		Parent = cartao,
	}, {
		Ui.canto(10),
	})

	comprar.Activated:Connect(function()
		remoteComprar:FireServer(definicao.id)
	end)

	linhas[definicao.id] = { nivel = nivel, comprar = comprar }
end

function Loja.montar(ctx)
	local gui = ctx.raiz
	painel = Ui.novo("Frame", {
		Name = "Loja",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(560, 470),
		BackgroundColor3 = Ui.cores.cartao,
		Visible = false,
		Parent = gui,
	}, {
		Ui.canto(18),
		Ui.contorno(Ui.cores.moeda, 1.5),
		Ui.margem(18),
	})

	Ui.texto({
		Size = UDim2.new(1, -40, 0, 28),
		Text = "🛒  LOJA DE MELHORIAS",
		Font = Ui.fonteTitulo,
		TextSize = 20,
		Parent = painel,
	})

	Ui.texto({
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, -40, 0, 18),
		Text = "As melhorias NÃO são perdidas ao evoluir.",
		TextColor3 = Ui.cores.textoFraco,
		TextSize = 13,
		Parent = painel,
	})

	local fechar = Ui.novo("TextButton", {
		Name = "Fechar",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = Ui.cores.cartaoClaro,
		Text = "✕",
		Font = Ui.fonteTitulo,
		TextSize = 16,
		TextColor3 = Ui.cores.texto,
		Parent = painel,
	}, {
		Ui.canto(10),
	})

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
	}, {
		Ui.lista(10),
	})

	for ordem, definicao in Melhorias.lista do
		construirLinha(definicao, rolagem, ordem)
	end

	player:GetAttributeChangedSignal("Moedas"):Connect(atualizarTudo)
	atualizarTudo()
end

function Loja.ligar()
	Eventos.sinal("PedirLoja"):Connect(function()
		Loja.alternar()
	end)
	Remotes.obter("EstadoAtualizado").OnClientEvent:Connect(Loja.aplicarEstado)
end

--- Recebe do servidor os níveis atuais das melhorias.
function Loja.aplicarEstado(estado)
	if typeof(estado) ~= "table" or typeof(estado.melhorias) ~= "table" then
		return
	end

	niveis = estado.melhorias
	atualizarTudo()
end

function Loja.alternar(visivel: boolean?)
	if not painel then
		return
	end

	painel.Visible = if visivel == nil then not painel.Visible else visivel
end

return Loja
