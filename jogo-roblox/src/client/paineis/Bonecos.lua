--[[
	A cara do combate: rótulo, barra de vida, número de dano e a quebra.

	Tudo aqui é LOCAL. A vida do boneco é por jogador, então a barra que você vê
	é a sua — o jogador ao lado tem a dele, no mesmo boneco, e um não atrapalha
	o outro. Por isso a quebra também é local: o modelo some só para quem
	quebrou e volta sozinho.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Formato = Compartilhado.Formato

local Ui = require(script.Parent.Parent.Ui)

local player = Players.LocalPlayer

local BonecosCliente = { ordem = 40 }

local DISTANCIA_ROTULO = 90
local paineis: { [string]: any } = {}

local function corDaBarra(indiceTier: number): Color3
	return Config.Bonecos.tiers[indiceTier].cor
end

local function montarPainel(modelo: Model)
	local corpo = modelo.PrimaryPart
	if not corpo then
		return
	end

	local indiceTier = modelo:GetAttribute("Tier") or 1

	local billboard = Ui.novo("BillboardGui", {
		Name = "PainelBoneco",
		Adornee = corpo,
		Size = UDim2.fromOffset(190, 56),
		StudsOffset = Vector3.new(0, corpo.Size.Y * 0.5 + 2.6, 0),
		MaxDistance = DISTANCIA_ROTULO,
		AlwaysOnTop = false,
		Parent = player:WaitForChild("PlayerGui"),
	})

	local titulo = Ui.texto({
		Size = UDim2.new(1, 0, 0, 20),
		Text = modelo:GetAttribute("TierNome") or "Boneco",
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Ui.fonteTitulo,
		TextSize = 15,
		TextStrokeTransparency = 0.4,
		Parent = billboard,
	})

	local exigencia = Ui.texto({
		Position = UDim2.fromOffset(0, 19),
		Size = UDim2.new(1, 0, 0, 15),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Ui.cores.erro,
		TextSize = 12,
		TextStrokeTransparency = 0.6,
		Parent = billboard,
	})

	local trilho = Ui.novo("Frame", {
		Position = UDim2.new(0, 0, 1, -12),
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = Color3.fromRGB(16, 18, 26),
		BackgroundTransparency = 0.25,
		Parent = billboard,
	}, { Ui.canto(5) })

	local preenchimento = Ui.novo("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = corDaBarra(indiceTier),
		BorderSizePixel = 0,
		Parent = trilho,
	}, { Ui.canto(5) })

	paineis[modelo.Name] = {
		modelo = modelo,
		corpo = corpo,
		billboard = billboard,
		titulo = titulo,
		exigencia = exigencia,
		preenchimento = preenchimento,
		indiceTier = indiceTier,
		danoExigido = modelo:GetAttribute("DanoExigido") or 0,
	}
end

--- Marca em vermelho os bonecos que o dano atual mal arranha.
local function revisarExigencias()
	local dano = player:GetAttribute("Dano") or 0

	for _, painel in paineis do
		if dano < painel.danoExigido then
			painel.exigencia.Text = "precisa de " .. Formato.abreviar(painel.danoExigido) .. " de dano"
			painel.titulo.TextColor3 = Ui.cores.textoFraco
		else
			painel.exigencia.Text = ""
			painel.titulo.TextColor3 = Ui.cores.texto
		end
	end
end

local function numeroDeDano(painel, valor: number, arranhou: boolean)
	local etiqueta = Ui.novo("BillboardGui", {
		Adornee = painel.corpo,
		Size = UDim2.fromOffset(150, 40),
		StudsOffset = Vector3.new(math.random(-18, 18) / 10, 1.5, 0),
		MaxDistance = DISTANCIA_ROTULO,
		AlwaysOnTop = true,
		Parent = player.PlayerGui,
	})

	local texto = Ui.texto({
		Size = UDim2.fromScale(1, 1),
		Text = (if arranhou then "" else "-") .. Formato.abreviar(valor),
		TextColor3 = if arranhou then Ui.cores.textoFraco else Ui.cores.forca,
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Ui.fonteTitulo,
		TextSize = if arranhou then 16 else 24,
		TextStrokeTransparency = 0.35,
		Parent = etiqueta,
	})

	local subida = TweenService:Create(etiqueta, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {
		StudsOffset = etiqueta.StudsOffset + Vector3.new(0, 3.5, 0),
	})
	local sumico = TweenService:Create(texto, TweenInfo.new(0.7), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})

	subida:Play()
	sumico:Play()
	sumico.Completed:Once(function()
		etiqueta:Destroy()
	end)
end

local function esconder(painel, escondido: boolean)
	for _, parte in painel.modelo:GetDescendants() do
		if parte:IsA("BasePart") then
			parte.LocalTransparencyModifier = if escondido then 1 else 0
			parte.CanCollide = not escondido and parte.Name ~= "Cabeca" and parte.Name ~= "Braco"
		end
	end
	painel.billboard.Enabled = not escondido
end

local function aoQuebrar(painel)
	-- Só some para quem quebrou; para os outros o boneco continua de pé.
	esconder(painel, true)

	task.delay(Config.Geral.RENASCE_BONECO, function()
		if painel.modelo.Parent then
			esconder(painel, false)
			painel.preenchimento.Size = UDim2.fromScale(1, 1)
		end
	end)
end

local function aoGolpe(resultado)
	local painel = paineis[resultado.id]
	if not painel then
		return
	end

	numeroDeDano(painel, resultado.dano, resultado.arranhou)

	local proporcao = if resultado.vida > 0 then resultado.restante / resultado.vida else 0
	painel.preenchimento.Size = UDim2.fromScale(math.clamp(proporcao, 0, 1), 1)

	if resultado.quebrou then
		aoQuebrar(painel)
	end
end

function BonecosCliente.montar()
	local pasta = workspace:WaitForChild("Bonecos", 30)
	if not pasta then
		warn("[Bonecos] pasta não encontrada em Workspace")
		return
	end

	for _, modelo in pasta:GetChildren() do
		if modelo:IsA("Model") then
			montarPainel(modelo)
		end
	end

	pasta.ChildAdded:Connect(function(modelo)
		if modelo:IsA("Model") then
			task.defer(montarPainel, modelo)
			task.defer(revisarExigencias)
		end
	end)

	player:GetAttributeChangedSignal("Dano"):Connect(revisarExigencias)
	revisarExigencias()
end

function BonecosCliente.ligar()
	Compartilhado.Remotes.obter("GolpeResolvido").OnClientEvent:Connect(aoGolpe)
end

return BonecosCliente
