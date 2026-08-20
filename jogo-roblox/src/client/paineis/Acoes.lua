--[[
	Coluna de botões à direita: Loja e Evolução.

	MEXER AQUI para: somar um botão de ação. O botão só emite um sinal ou
	dispara um remote — ele nunca conhece a interface que vai abrir.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Eventos = Compartilhado.Eventos
local Formato = Compartilhado.Formato
local Remotes = Compartilhado.Remotes

local Ui = require(script.Parent.Parent.Ui)
local Estado = require(script.Parent.Parent.Estado)

local Acoes = { ordem = 25 }

local w: { [string]: any } = {}
local remoteEvoluir = Remotes.obter("PedirEvolucao")

local function progressoDaEvolucao(): (number, string, boolean)
	local forca = Estado.ler("Forca", 0)
	local nome = Estado.ler("ProximaEvolucaoNome", "")
	local necessaria = Estado.ler("ProximaEvolucaoForca", 0)

	if nome == "" or necessaria <= 0 then
		return 1, "EVOLUÇÃO MÁXIMA", false
	end

	return math.clamp(forca / necessaria, 0, 1),
		string.format(
			"%s\n%s / %s",
			nome,
			Formato.abreviar(forca),
			Formato.abreviar(necessaria)
		),
		forca >= necessaria
end

local function atualizar()
	local progresso, legenda, pronto = progressoDaEvolucao()
	w.legenda.Text = legenda
	w.barra.Size = UDim2.new(progresso, 0, 1, 0)
	w.evoluir.BackgroundColor3 = if pronto then Ui.cores.evolucao else Ui.cores.cartaoClaro
end

local function botao(nome: string, rotulo: string, ordem: number, pai: Instance): TextButton
	return Ui.novo("TextButton", {
		Name = nome,
		Size = UDim2.fromOffset(200, 52),
		LayoutOrder = ordem,
		BackgroundColor3 = Ui.cores.cartaoClaro,
		BackgroundTransparency = 0.04,
		AutoButtonColor = true,
		Text = rotulo,
		Font = Ui.fonteTitulo,
		TextSize = 15,
		TextColor3 = Ui.cores.texto,
		Parent = pai,
	}, { Ui.canto(12), Ui.contorno() })
end

function Acoes.montar(ctx)
	local coluna = Ui.novo("Frame", {
		Name = "Acoes",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(200, 130),
		BackgroundTransparency = 1,
		Parent = ctx.raiz,
	}, { Ui.lista(10) })

	botao("Loja", "🛒  LOJA", 1, coluna).Activated:Connect(function()
		Eventos.emitir("PedirLoja")
	end)

	local evoluir = botao("Evoluir", "", 2, coluna)
	evoluir.Size = UDim2.fromOffset(200, 68)
	evoluir.Activated:Connect(function()
		remoteEvoluir:FireServer()
	end)

	local trilho = Ui.novo("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -20, 0, 6),
		BackgroundColor3 = Ui.cores.fundo,
		Parent = evoluir,
	}, { Ui.canto(3) })

	w.barra = Ui.novo("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Ui.cores.evolucao,
		BorderSizePixel = 0,
		Parent = trilho,
	}, { Ui.canto(3) })

	w.legenda = Ui.texto({
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, 0, 0, 40),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Ui.fonteTitulo,
		TextSize = 13,
		Parent = evoluir,
	})

	w.evoluir = evoluir

	Estado.observar({ "Forca", "ProximaEvolucaoNome", "ProximaEvolucaoForca" }, atualizar)
end

return Acoes
