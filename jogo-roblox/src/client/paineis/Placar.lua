--[[
	Painel de status, canto superior esquerdo.

	MEXER AQUI para: o que aparece no cartão de números e a barra de rank.
	Nada além disso — botões e combate moram em Acoes.lua e Golpe.lua.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Formato = Compartilhado.Formato

local Ui = require(script.Parent.Parent.Ui)
local Estado = require(script.Parent.Parent.Estado)

local Placar = { ordem = 20 }

local w: { [string]: any } = {}

--- Progresso dentro do rank atual, com a legenda pronta.
local function progressoDoRank(): (number, string)
	local forca = Estado.ler("Forca", 0)
	local atual = Config.Ranks[Estado.ler("RankIndice", 1)]
	local proximo = Config.Ranks[Estado.ler("RankIndice", 1) + 1]

	if not atual then
		return 0, ""
	end
	if not proximo then
		return 1, "RANK MÁXIMO"
	end

	local faixa = proximo.forca - atual.forca
	local progresso = if faixa > 0 then (forca - atual.forca) / faixa else 1

	return math.clamp(progresso, 0, 1),
		string.format(
			"%s → %s de %s",
			proximo.nome,
			Formato.abreviar(forca),
			Formato.abreviar(proximo.forca)
		)
end

local function atualizar()
	w.rank.Text = string.upper(Estado.ler("RankNome", "Iniciante"))
	w.rank.TextColor3 = Estado.ler("RankCor", Ui.cores.texto)
	w.forca.Text = Formato.abreviar(Estado.ler("Forca", 0))
	w.moedas.Text = Formato.abreviar(Estado.ler("Moedas", 0))
	w.reliquias.Text = Formato.abreviar(Estado.ler("Reliquias", 0)) .. " relíquias"
	w.rodape.Text = string.format(
		"%s de dano  ·  recompensa x%.2f",
		Formato.abreviar(Estado.ler("Dano", 0)),
		Estado.ler("MultForca", 1)
	)

	local progresso, legenda = progressoDoRank()
	w.barra.Size = UDim2.new(progresso, 0, 1, 0)
	w.legenda.Text = legenda
end

function Placar.montar(ctx)
	local painel = Ui.novo("Frame", {
		Name = "Placar",
		Position = UDim2.fromOffset(16, 16),
		Size = UDim2.fromOffset(330, 190),
		BackgroundColor3 = Ui.cores.cartao,
		BackgroundTransparency = 0.06,
		Parent = ctx.raiz,
	}, { Ui.canto(14), Ui.contorno(), Ui.margem(14) })

	w.rank = Ui.texto({
		Size = UDim2.new(1, 0, 0, 18),
		Text = "INICIANTE",
		Font = Ui.fonteTitulo,
		TextSize = 14,
		Parent = painel,
	})

	w.forca = Ui.texto({
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
		Font = Ui.fonteTitulo,
		TextSize = 12,
		Parent = painel,
	})

	w.moedas = Ui.texto({
		Position = UDim2.fromOffset(0, 80),
		Size = UDim2.new(1, 0, 0, 22),
		Text = "0",
		TextColor3 = Ui.cores.moeda,
		Font = Ui.fonteTitulo,
		TextSize = 19,
		Parent = painel,
	})

	w.reliquias = Ui.texto({
		Position = UDim2.fromOffset(0, 100),
		Size = UDim2.new(1, 0, 0, 16),
		Text = "",
		TextColor3 = Ui.cores.evolucao,
		Font = Ui.fonteTitulo,
		TextSize = 13,
		Parent = painel,
	})

	w.rodape = Ui.texto({
		Position = UDim2.fromOffset(0, 118),
		Size = UDim2.new(1, 0, 0, 14),
		Text = "",
		TextColor3 = Ui.cores.textoFraco,
		TextSize = 11,
		Parent = painel,
	})

	local trilho = Ui.novo("Frame", {
		Position = UDim2.new(0, 0, 1, -18),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundColor3 = Ui.cores.fundo,
		Parent = painel,
	}, { Ui.canto(9) })

	w.barra = Ui.novo("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Ui.cores.forca,
		BorderSizePixel = 0,
		Parent = trilho,
	}, { Ui.canto(9) })

	w.legenda = Ui.texto({
		Size = UDim2.fromScale(1, 1),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Ui.fonteTitulo,
		TextSize = 11,
		Parent = trilho,
	})

	Estado.observar({
		"Forca",
		"Moedas",
		"Reliquias",
		"Dano",
		"MultForca",
		"RankIndice",
		"RankNome",
		"RankCor",
	}, atualizar)
end

return Placar
