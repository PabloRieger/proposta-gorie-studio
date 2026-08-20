--[[
	Tema e atalhos de construção de interface.

	Toda a UI do jogo é feita por código (nada de .rbxmx binário no repositório),
	então vale ter um construtor declarativo enxuto em vez de dezenas de
	`Instance.new` seguidos de dez atribuições.
]]

local Ui = {}

Ui.cores = {
	fundo = Color3.fromRGB(18, 20, 30),
	cartao = Color3.fromRGB(26, 29, 43),
	cartaoClaro = Color3.fromRGB(38, 42, 60),
	borda = Color3.fromRGB(58, 64, 88),
	texto = Color3.fromRGB(236, 240, 250),
	textoFraco = Color3.fromRGB(146, 154, 178),
	forca = Color3.fromRGB(252, 168, 96),
	moeda = Color3.fromRGB(252, 214, 108),
	evolucao = Color3.fromRGB(186, 140, 252),
	sucesso = Color3.fromRGB(120, 220, 160),
	erro = Color3.fromRGB(248, 116, 116),
}

Ui.fonteTitulo = Enum.Font.GothamBold
Ui.fonteTexto = Enum.Font.Gotham

--[[
	`novo("Frame", { ... }, { filhos })`

	Parent é aplicado por último de propósito: setar Parent antes das outras
	propriedades faz a instância replicar duas vezes.
]]
function Ui.novo(classe: string, propriedades: { [string]: any }?, filhos: { Instance }?): any
	local instancia = Instance.new(classe)
	local pai = nil

	for chave, valor in propriedades or {} do
		if chave == "Parent" then
			pai = valor
		else
			(instancia :: any)[chave] = valor
		end
	end

	for _, filho in filhos or {} do
		filho.Parent = instancia
	end

	if pai then
		instancia.Parent = pai
	end

	return instancia
end

function Ui.canto(raio: number): UICorner
	return Ui.novo("UICorner", { CornerRadius = UDim.new(0, raio) })
end

function Ui.contorno(cor: Color3?, espessura: number?): UIStroke
	return Ui.novo("UIStroke", {
		Color = cor or Ui.cores.borda,
		Thickness = espessura or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Ui.margem(valor: number): UIPadding
	return Ui.novo("UIPadding", {
		PaddingTop = UDim.new(0, valor),
		PaddingBottom = UDim.new(0, valor),
		PaddingLeft = UDim.new(0, valor),
		PaddingRight = UDim.new(0, valor),
	})
end

function Ui.lista(espaco: number, direcao: Enum.FillDirection?): UIListLayout
	return Ui.novo("UIListLayout", {
		Padding = UDim.new(0, espaco),
		FillDirection = direcao or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

function Ui.texto(propriedades: { [string]: any }): TextLabel
	local padrao = {
		BackgroundTransparency = 1,
		Font = Ui.fonteTexto,
		TextColor3 = Ui.cores.texto,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 15,
	}

	for chave, valor in propriedades do
		padrao[chave] = valor
	end

	return Ui.novo("TextLabel", padrao)
end

return Ui
