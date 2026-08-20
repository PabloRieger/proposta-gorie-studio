--[[
	Constrói o mapa inteiro por código, a partir de Config.Zonas.

	Por que não um arquivo .rbxl com o mapa montado à mão: arquivo de lugar é
	binário e não dá para revisar em diff, resolver conflito nem versionar de
	forma útil. Gerando aqui, mudar o mapa é mudar a tabela de zonas — e o
	Combate valida contra exatamente a mesma geometria.

	As barreiras são criadas colidíveis para todos; o cliente desliga a colisão
	localmente das que já liberou (ele é dono da física do próprio personagem).
	Quem burlar isso não ganha nada: o servidor revalida o requisito da zona.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Formato = Compartilhado.Formato

local Bonecos = Config.Bonecos

local Mundo = { ordem = 30 }

--- Preenchido por iniciar(); o Combate lê daqui.
Mundo.bonecos = {}

local ALTURA_BARREIRA = 18
local LARGURA_CAMINHO = 16
local COR_HUB = Color3.fromRGB(60, 64, 82)
local COR_CAMINHO = Color3.fromRGB(78, 82, 104)

local function bloco(nome: string, tamanho: Vector3, posicao: Vector3, cor: Color3, material: Enum.Material, pai: Instance): Part
	local parte = Instance.new("Part")
	parte.Name = nome
	parte.Size = tamanho
	parte.Position = posicao
	parte.Color = cor
	parte.Material = material
	parte.Anchored = true
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
	parte.Parent = pai
	return parte
end

local function placa(texto: string, subtexto: string, cor: Color3, posicao: Vector3, pai: Instance)
	local ancora = bloco(
		"Placa",
		Vector3.new(1, 1, 1),
		posicao,
		cor,
		Enum.Material.Neon,
		pai
	)
	ancora.Transparency = 1
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.CanTouch = false

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Letreiro"
	billboard.Size = UDim2.fromScale(22, 5)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
	billboard.MaxDistance = 260
	billboard.AlwaysOnTop = false
	billboard.Parent = ancora

	local titulo = Instance.new("TextLabel")
	titulo.Name = "Titulo"
	titulo.Size = UDim2.fromScale(1, 0.58)
	titulo.BackgroundTransparency = 1
	titulo.Font = Enum.Font.GothamBold
	titulo.TextScaled = true
	titulo.TextColor3 = cor
	titulo.TextStrokeTransparency = 0.4
	titulo.Text = texto
	titulo.Parent = billboard

	local detalhe = Instance.new("TextLabel")
	detalhe.Name = "Detalhe"
	detalhe.Position = UDim2.fromScale(0, 0.58)
	detalhe.Size = UDim2.fromScale(1, 0.42)
	detalhe.BackgroundTransparency = 1
	detalhe.Font = Enum.Font.Gotham
	detalhe.TextScaled = true
	detalhe.TextColor3 = Color3.fromRGB(226, 230, 240)
	detalhe.TextStrokeTransparency = 0.6
	detalhe.Text = subtexto
	detalhe.Parent = billboard
end

local function pedestal(nome: string, rotulo: string, icone: string, posicao: Vector3, cor: Color3, pai: Instance)
	local base = Instance.new("Part")
	base.Name = nome
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(2, 9, 9)
	-- Cylinder nasce deitado no eixo X; de pé vira um pedestal.
	base.CFrame = CFrame.new(posicao) * CFrame.Angles(0, 0, math.rad(90))
	base.Color = cor
	base.Material = Enum.Material.Neon
	base.Anchored = true
	base.Parent = pai

	local luz = Instance.new("PointLight")
	luz.Color = cor
	luz.Range = 18
	luz.Brightness = 2
	luz.Parent = base

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Prompt"
	prompt.ActionText = rotulo
	prompt.ObjectText = icone .. " " .. nome
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = base

	return base
end

--[[
	Um boneco de treino. É só geometria: a vida não mora aqui, mora no
	Combate, porque ela é por jogador. O que fica na parte são os
	atributos que o cliente precisa para desenhar a barra e o rótulo.
]]
local function construirBoneco(zona, indiceTier: number, pai: Instance)
	local tier = Bonecos.tiers[indiceTier]
	local escala = tier.escala
	local centro = zona.posicao + Bonecos.posicoes[indiceTier]

	local modelo = Instance.new("Model")
	modelo.Name = zona.id .. "_" .. tier.id

	local base = bloco(
		"Base",
		Vector3.new(5, 1, 5),
		centro + Vector3.new(0, 0.5, 0),
		Color3.fromRGB(70, 66, 60),
		Enum.Material.Slate,
		modelo
	)

	local alturaCorpo = 5 * escala
	local corpo = bloco(
		"Corpo",
		Vector3.new(3.2 * escala, alturaCorpo, 2 * escala),
		centro + Vector3.new(0, 1 + alturaCorpo * 0.5, 0),
		tier.cor,
		Enum.Material.WoodPlanks,
		modelo
	)

	local cabeca = bloco(
		"Cabeca",
		Vector3.new(2.2 * escala, 2.2 * escala, 2.2 * escala),
		centro + Vector3.new(0, 1 + alturaCorpo + 1.1 * escala, 0),
		tier.cor,
		Enum.Material.WoodPlanks,
		modelo
	)

	-- Braços: só leitura visual de "isto é um boneco", sem colisão.
	for _, lado in { -1, 1 } do
		local braco = bloco(
			"Braco",
			Vector3.new(1 * escala, 3.4 * escala, 1 * escala),
			centro + Vector3.new(lado * 2.3 * escala, 1 + alturaCorpo * 0.6, 0),
			tier.cor,
			Enum.Material.WoodPlanks,
			modelo
		)
		braco.CanCollide = false
	end

	base.CanCollide = true
	corpo.CanCollide = true
	cabeca.CanCollide = false

	modelo.PrimaryPart = corpo
	modelo:SetAttribute("BonecoId", modelo.Name)
	modelo:SetAttribute("Tier", indiceTier)
	modelo:SetAttribute("TierNome", tier.nome)
	modelo:SetAttribute("Vida", Bonecos.vidaDe(zona, indiceTier))
	modelo:SetAttribute("DanoExigido", Bonecos.danoExigido(zona, indiceTier))
	modelo:SetAttribute("Revida", tier.revida > 0)
	modelo:SetAttribute("Alvo", corpo.Position + Vector3.new(0, alturaCorpo * 0.5 + 2, 0))
	modelo.Parent = pai

	return {
		id = modelo.Name,
		zona = zona,
		indiceTier = indiceTier,
		posicao = corpo.Position,
		modelo = modelo,
	}
end

local function limparCenarioPadrao()
	for _, filho in workspace:GetChildren() do
		if filho.Name == "Baseplate" or filho:IsA("SpawnLocation") then
			filho:Destroy()
		end
	end
end

local function ajustarIluminacao()
	Lighting.Ambient = Color3.fromRGB(70, 72, 92)
	Lighting.OutdoorAmbient = Color3.fromRGB(96, 100, 128)
	Lighting.Brightness = 2.2
	Lighting.ClockTime = 17.5
	Lighting.GeographicLatitude = 20
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.4

	local atmosfera = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosfera then
		atmosfera = Instance.new("Atmosphere")
		atmosfera.Parent = Lighting
	end
	atmosfera.Density = 0.32
	atmosfera.Haze = 1.4
	atmosfera.Glare = 0.2
	atmosfera.Color = Color3.fromRGB(200, 206, 226)
	atmosfera.Decay = Color3.fromRGB(96, 104, 140)
end

local function construirHub(pai: Instance)
	bloco(
		"Hub",
		Vector3.new(90, 3, 90),
		Vector3.new(0, -1.5, 0),
		COR_HUB,
		Enum.Material.SmoothPlastic,
		pai
	)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Nascimento"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.5, -12)
	spawn.Anchored = true
	spawn.Color = Color3.fromRGB(120, 208, 168)
	spawn.Material = Enum.Material.Neon
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Duration = 0
	spawn.Parent = pai

	pedestal(
		"Altar de Evolução",
		"Evoluir",
		"⭐",
		Vector3.new(-26, 4.5, -26),
		Color3.fromRGB(196, 140, 252),
		pai
	)
	pedestal(
		"Loja",
		"Abrir",
		"🛒",
		Vector3.new(26, 4.5, -26),
		Color3.fromRGB(252, 204, 108),
		pai
	)

	placa(
		"EVOLUÇÃO LENDÁRIA",
		"Bata nos bonecos para ganhar Força · siga em frente para os melhores",
		Color3.fromRGB(236, 240, 252),
		Vector3.new(0, 22, 30),
		pai
	)
end

--- Liga duas plataformas com uma passarela (a única rota entre elas).
local function construirCaminho(deZ: number, ateZ: number, pai: Instance)
	local comprimento = ateZ - deZ
	if comprimento <= 0 then
		return
	end

	bloco(
		"Caminho",
		Vector3.new(LARGURA_CAMINHO, 2, comprimento),
		Vector3.new(0, -1, deZ + comprimento * 0.5),
		COR_CAMINHO,
		Enum.Material.SmoothPlastic,
		pai
	)
end

local function construirZona(zona, pai: Instance, pastaBarreiras: Instance, pastaBonecos: Instance)
	local pasta = Instance.new("Folder")
	pasta.Name = zona.nome
	pasta.Parent = pai

	local meioZ = zona.tamanho.Z * 0.5
	local meioX = zona.tamanho.X * 0.5

	bloco(
		"Plataforma",
		zona.tamanho,
		zona.posicao - Vector3.new(0, zona.tamanho.Y * 0.5, 0),
		zona.cor,
		Enum.Material.SmoothPlastic,
		pasta
	)

	-- Pilares nos cantos só para dar leitura de profundidade ao mapa.
	for _, sinal in { -1, 1 } do
		for _, sinalZ in { -1, 1 } do
			local pilar = bloco(
				"Pilar",
				Vector3.new(4, 16, 4),
				zona.posicao + Vector3.new(sinal * (meioX - 4), 8, sinalZ * (meioZ - 4)),
				zona.cor,
				Enum.Material.Neon,
				pasta
			)
			pilar.Transparency = 0.35
			pilar.CanCollide = false
		end
	end

	local frenteZ = zona.posicao.Z - meioZ

	if zona.forcaMinima > 0 then
		local barreira = bloco(
			zona.id,
			Vector3.new(zona.tamanho.X + 4, ALTURA_BARREIRA, 1),
			Vector3.new(0, ALTURA_BARREIRA * 0.5, frenteZ),
			zona.cor,
			Enum.Material.ForceField,
			pastaBarreiras
		)
		barreira.Transparency = 0.55
		barreira.CanCollide = true
		barreira.CanQuery = false
		barreira:SetAttribute("ForcaMinima", zona.forcaMinima)
		barreira:SetAttribute("ZonaNome", zona.nome)
	end

	local criados = {}
	for indiceTier = 1, #Bonecos.tiers do
		table.insert(criados, construirBoneco(zona, indiceTier, pastaBonecos))
	end

	placa(
		zona.nome,
		string.format(
			"Requer %s de Força · bonecos de %s a %s",
			Formato.abreviar(zona.forcaMinima),
			Formato.abreviar(Bonecos.vidaDe(zona, 1)),
			Formato.abreviar(Bonecos.vidaDe(zona, #Bonecos.tiers))
		),
		zona.cor,
		Vector3.new(0, ALTURA_BARREIRA + 5, frenteZ),
		pasta
	)

	return criados
end

function Mundo.iniciar()
	limparCenarioPadrao()
	ajustarIluminacao()

	local mundo = Instance.new("Folder")
	mundo.Name = "Mundo"
	mundo.Parent = workspace

	local pastaBarreiras = Instance.new("Folder")
	pastaBarreiras.Name = "Barreiras"
	pastaBarreiras.Parent = workspace

	local pastaBonecos = Instance.new("Folder")
	pastaBonecos.Name = "Bonecos"
	pastaBonecos.Parent = workspace

	construirHub(mundo)

	local bordaAnterior = 45 -- borda frontal do hub
	local todosOsBonecos = {}

	for _, zona in Config.Zonas do
		local frenteZ = zona.posicao.Z - zona.tamanho.Z * 0.5
		construirCaminho(bordaAnterior, frenteZ, mundo)

		for _, boneco in construirZona(zona, mundo, pastaBarreiras, pastaBonecos) do
			table.insert(todosOsBonecos, boneco)
		end

		bordaAnterior = zona.posicao.Z + zona.tamanho.Z * 0.5
	end

	Mundo.bonecos = todosOsBonecos
end

return Mundo
