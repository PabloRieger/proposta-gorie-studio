--[[
	Interface principal: painel de status, barra de progresso do rank,
	zona atual, botão de treino e botões de Loja/Evolução.

	Tudo que aparece aqui vem de ATRIBUTOS do Player, escritos pelo servidor.
	O cliente não guarda cópia do progresso — assim é impossível a tela
	discordar do que o servidor considera verdade.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Formato = Compartilhado.Formato

local Ui = require(script.Parent.Ui)

local player = Players.LocalPlayer

local HUD = {}

local acoes = {
	treinar = function() end,
	abrirLoja = function() end,
	evoluir = function() end,
}

local widgets: { [string]: any } = {}
local forcaAnterior = 0
local ultimoPopup = 0

local INTERVALO_POPUP = 0.18

local function atributo(nome: string, padrao: any)
	local valor = player:GetAttribute(nome)
	if valor == nil then
		return padrao
	end
	return valor
end

--[[
	Progresso dentro do rank atual. O índice vem do servidor; as faixas vêm
	da config compartilhada, então cliente e servidor concordam por construção.
]]
local function progressoDoRank(): (number, string)
	local forca = atributo("Forca", 0)
	local indice = atributo("RankIndice", 1)

	local atual = Config.Ranks[indice]
	local proximo = Config.Ranks[indice + 1]

	if not atual then
		return 0, ""
	end

	if not proximo then
		return 1, "RANK MÁXIMO"
	end

	local intervalo = proximo.forca - atual.forca
	local progresso = if intervalo > 0 then (forca - atual.forca) / intervalo else 1

	return math.clamp(progresso, 0, 1),
		string.format(
			"%s → %s de %s",
			proximo.nome,
			Formato.abreviar(forca),
			Formato.abreviar(proximo.forca)
		)
end

local function progressoDaEvolucao(): (number, string, boolean)
	local forca = atributo("Forca", 0)
	local nome = atributo("ProximaEvolucaoNome", "")
	local necessaria = atributo("ProximaEvolucaoForca", 0)

	if nome == "" or necessaria <= 0 then
		return 1, "EVOLUÇÃO MÁXIMA", false
	end

	local pronto = forca >= necessaria

	return math.clamp(forca / necessaria, 0, 1),
		string.format(
			"%s\n%s / %s",
			nome,
			Formato.abreviar(forca),
			Formato.abreviar(necessaria)
		),
		pronto
end

--- Número flutuante de "+X" quando a Força sobe.
local function mostrarGanho(quantidade: number)
	local agora = os.clock()
	if agora - ultimoPopup < INTERVALO_POPUP or quantidade <= 0 then
		return
	end
	ultimoPopup = agora

	local rotulo = Ui.texto({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, math.random(-70, 70), 0.62, 0),
		Size = UDim2.fromOffset(200, 34),
		Text = "+" .. Formato.abreviar(quantidade),
		TextColor3 = Ui.cores.forca,
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Ui.fonteTitulo,
		TextSize = 26,
		TextStrokeTransparency = 0.5,
		Parent = widgets.raiz,
	})

	local subida = TweenService:Create(rotulo, TweenInfo.new(0.85, Enum.EasingStyle.Quad), {
		Position = rotulo.Position - UDim2.fromOffset(0, 70),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})

	subida:Play()
	subida.Completed:Once(function()
		rotulo:Destroy()
	end)
end

local function atualizar()
	local forca = atributo("Forca", 0)

	widgets.rank.Text = string.upper(atributo("RankNome", "Iniciante"))
	widgets.rank.TextColor3 = atributo("RankCor", Ui.cores.texto)
	widgets.forca.Text = Formato.abreviar(forca)
	widgets.moedas.Text = Formato.abreviar(atributo("Moedas", 0))
	widgets.multiplicador.Text = string.format(
		"x%.2f Força  ·  x%.2f Moedas",
		atributo("MultForca", 1),
		atributo("MultMoedas", 1)
	)

	local progresso, legenda = progressoDoRank()
	widgets.barraPreenchimento.Size = UDim2.new(progresso, 0, 1, 0)
	widgets.barraTexto.Text = legenda

	local progressoEvolucao, legendaEvolucao, pronto = progressoDaEvolucao()
	widgets.evoluirTexto.Text = legendaEvolucao
	widgets.evoluirPreenchimento.Size = UDim2.new(progressoEvolucao, 0, 1, 0)
	widgets.evoluir.BackgroundColor3 = if pronto then Ui.cores.evolucao else Ui.cores.cartaoClaro

	local zona = atributo("ZonaAtual", "")
	local bloqueada = atributo("ZonaBloqueada", false)

	if zona == "" then
		widgets.zona.Text = "Siga em frente para achar uma zona de treino"
		widgets.zona.TextColor3 = Ui.cores.textoFraco
	elseif bloqueada then
		widgets.zona.Text = "🔒 " .. zona .. " — Força insuficiente"
		widgets.zona.TextColor3 = Ui.cores.erro
	else
		widgets.zona.Text = "⚡ Treinando em " .. zona
		widgets.zona.TextColor3 = Ui.cores.sucesso
	end

	if forca > forcaAnterior then
		mostrarGanho(forca - forcaAnterior)
	end
	forcaAnterior = forca
end

local function construirPainel(raiz: Frame)
	local painel = Ui.novo("Frame", {
		Name = "Status",
		Position = UDim2.fromOffset(16, 16),
		Size = UDim2.fromOffset(330, 172),
		BackgroundColor3 = Ui.cores.cartao,
		BackgroundTransparency = 0.06,
		Parent = raiz,
	}, {
		Ui.canto(14),
		Ui.contorno(),
		Ui.margem(14),
	})

	widgets.rank = Ui.texto({
		Size = UDim2.new(1, 0, 0, 18),
		Text = "INICIANTE",
		Font = Ui.fonteTitulo,
		TextSize = 14,
		Parent = painel,
	})

	widgets.forca = Ui.texto({
		Position = UDim2.fromOffset(0, 20),
		Size = UDim2.new(1, 0, 0, 40),
		Text = "0",
		TextColor3 = Ui.cores.forca,
		Font = Ui.fonteTitulo,
		TextSize = 36,
		Parent = painel,
	})

	Ui.texto({
		Position = UDim2.fromOffset(0, 60),
		Size = UDim2.new(1, 0, 0, 16),
		Text = "FORÇA",
		TextColor3 = Ui.cores.textoFraco,
		TextSize = 12,
		Font = Ui.fonteTitulo,
		Parent = painel,
	})

	widgets.moedas = Ui.texto({
		Position = UDim2.fromOffset(0, 80),
		Size = UDim2.new(1, 0, 0, 22),
		Text = "0",
		TextColor3 = Ui.cores.moeda,
		Font = Ui.fonteTitulo,
		TextSize = 19,
		Parent = painel,
	})

	widgets.multiplicador = Ui.texto({
		Position = UDim2.fromOffset(0, 102),
		Size = UDim2.new(1, 0, 0, 14),
		Text = "",
		TextColor3 = Ui.cores.textoFraco,
		TextSize = 11,
		Parent = painel,
	})

	local barra = Ui.novo("Frame", {
		Name = "Barra",
		Position = UDim2.new(0, 0, 1, -18),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundColor3 = Ui.cores.fundo,
		Parent = painel,
	}, {
		Ui.canto(9),
	})

	widgets.barraPreenchimento = Ui.novo("Frame", {
		Name = "Preenchimento",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Ui.cores.forca,
		BorderSizePixel = 0,
		Parent = barra,
	}, {
		Ui.canto(9),
	})

	widgets.barraTexto = Ui.texto({
		Size = UDim2.fromScale(1, 1),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 11,
		Font = Ui.fonteTitulo,
		Parent = barra,
	})
end

local function botao(nome: string, rotulo: string, cor: Color3, ordem: number, pai: Instance): TextButton
	return Ui.novo("TextButton", {
		Name = nome,
		Size = UDim2.fromOffset(200, 52),
		LayoutOrder = ordem,
		BackgroundColor3 = cor,
		BackgroundTransparency = 0.04,
		AutoButtonColor = true,
		Text = rotulo,
		Font = Ui.fonteTitulo,
		TextSize = 15,
		TextColor3 = Ui.cores.texto,
		Parent = pai,
	}, {
		Ui.canto(12),
		Ui.contorno(),
	})
end

local function construirBotoes(raiz: Frame)
	local coluna = Ui.novo("Frame", {
		Name = "Acoes",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(200, 130),
		BackgroundTransparency = 1,
		Parent = raiz,
	}, {
		Ui.lista(10),
	})

	local loja = botao("Loja", "🛒  LOJA", Ui.cores.cartaoClaro, 1, coluna)
	loja.Activated:Connect(function()
		acoes.abrirLoja()
	end)

	local evoluir = botao("Evoluir", "", Ui.cores.cartaoClaro, 2, coluna)
	evoluir.Size = UDim2.fromOffset(200, 68)
	evoluir.Activated:Connect(function()
		acoes.evoluir()
	end)

	local trilho = Ui.novo("Frame", {
		Name = "Trilho",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -20, 0, 6),
		BackgroundColor3 = Ui.cores.fundo,
		Parent = evoluir,
	}, {
		Ui.canto(3),
	})

	widgets.evoluirPreenchimento = Ui.novo("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Ui.cores.evolucao,
		BorderSizePixel = 0,
		Parent = trilho,
	}, {
		Ui.canto(3),
	})

	widgets.evoluirTexto = Ui.texto({
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, 0, 0, 40),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Ui.fonteTitulo,
		TextSize = 13,
		Parent = evoluir,
	})

	widgets.evoluir = evoluir
end

local function construirRodape(raiz: Frame)
	widgets.zona = Ui.texto({
		Name = "Zona",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -178),
		Size = UDim2.fromOffset(460, 26),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Ui.fonteTitulo,
		TextSize = 16,
		TextStrokeTransparency = 0.7,
		Parent = raiz,
	})

	local treinar = Ui.novo("TextButton", {
		Name = "Treinar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -28),
		Size = UDim2.fromOffset(140, 140),
		BackgroundColor3 = Ui.cores.forca,
		BackgroundTransparency = 0.08,
		AutoButtonColor = true,
		Text = "TREINAR",
		Font = Ui.fonteTitulo,
		TextSize = 20,
		TextColor3 = Ui.cores.fundo,
		Parent = raiz,
	}, {
		Ui.novo("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		Ui.contorno(Ui.cores.forca, 3),
	})

	widgets.treinar = treinar
end

--[[
	Uma escala única para telas pequenas. Mais simples e previsível do que
	reposicionar cada elemento em UDim2 relativo.
]]
local function acompanharEscala(raiz: Frame)
	local escala = Ui.novo("UIScale", { Parent = raiz })
	local camera = workspace.CurrentCamera

	local function ajustar()
		local largura = camera.ViewportSize.X
		escala.Scale = if largura < 640 then 0.72 elseif largura < 900 then 0.85 else 1
	end

	camera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustar)
	ajustar()
end

function HUD.criar(gui: ScreenGui)
	local raiz = Ui.novo("Frame", {
		Name = "HUD",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = gui,
	})

	widgets.raiz = raiz

	construirPainel(raiz)
	construirBotoes(raiz)
	construirRodape(raiz)
	acompanharEscala(raiz)

	forcaAnterior = atributo("Forca", 0)

	for _, nome in
		{
			"Forca",
			"Moedas",
			"RankIndice",
			"RankNome",
			"RankCor",
			"MultForca",
			"MultMoedas",
			"ZonaAtual",
			"ZonaBloqueada",
			"ProximaEvolucaoNome",
			"ProximaEvolucaoForca",
		}
	do
		player:GetAttributeChangedSignal(nome):Connect(atualizar)
	end

	atualizar()
end

function HUD.definirAcoes(novasAcoes: { [string]: () -> () })
	for chave, funcao in novasAcoes do
		acoes[chave] = funcao
	end
end

function HUD.botaoTreinar(): TextButton
	return widgets.treinar
end

return HUD
