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

local Monstros = Config.Monstros
local Bestiario = Config.Bestiario

local Mundo = { ordem = 30 }

--- Preenchido por iniciar(); o Combate lê daqui.
Mundo.monstros = {}

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
	Constrói um monstro.

	Duas fontes de corpo, nesta ordem: se existir um modelo com o nome que a
	espécie declara em ReplicatedStorage/Modelos, ele é usado; senão a silhueta
	é montada pela receita em Monstros.corpos. É o que permite trocar arte por
	arte, uma espécie por vez, sem tocar em código.

	A vida NÃO mora aqui — mora no Combate, porque é por jogador. Ficam na
	instância só os atributos que o cliente precisa para desenhar e animar.

	Estrutura: uma Âncora invisível com colisão, que nunca se move e serve de
	referência ao servidor, e um Visual sem colisão que o cliente é livre para
	balançar e virar sem afetar a física de ninguém.
]]
local function escurecer(cor: Color3): Color3
	return Color3.new(cor.R * 0.55, cor.G * 0.55, cor.B * 0.55)
end

local function corDaParte(descritor, especie): Color3
	if descritor.cor == "principal" then
		return especie.cor
	elseif descritor.cor == "escura" then
		return escurecer(especie.cor)
	end
	return especie.olho
end

--- Modelo do Toolbox costuma vir com script dentro; o monstro é só a casca.
local function higienizar(modelo: Instance)
	for _, item in modelo:GetDescendants() do
		if item:IsA("BaseScript") or item:IsA("ModuleScript") then
			item:Destroy()
		end
	end
end

local function montarVisual(especie, escala: number, centro: Vector3): Model
	local receita = Monstros.corpos[especie.corpo]
	local visual = Instance.new("Model")
	visual.Name = "Visual"

	for _, descritor in receita.partes do
		local parte = Instance.new("Part")
		parte.Name = descritor.nome
		parte.Size = descritor.tamanho * escala
		parte.Position = centro + descritor.offset * escala
		parte.Color = corDaParte(descritor, especie)
		parte.Material = if descritor.material == "neon"
			then Enum.Material.Neon
			else Enum.Material.SmoothPlastic
		parte.Transparency = descritor.transparencia
		parte.Shape = if descritor.forma == "esfera"
			then Enum.PartType.Ball
			else Enum.PartType.Block
		parte.Anchored = true
		parte.CanCollide = false
		parte.CanQuery = false
		parte.CanTouch = false
		parte.TopSurface = Enum.SurfaceType.Smooth
		parte.BottomSurface = Enum.SurfaceType.Smooth
		parte.Parent = visual

		if not visual.PrimaryPart then
			visual.PrimaryPart = parte
		end
	end

	return visual
end

local function visualDeModelo(especie, escala: number, centro: Vector3): Model?
	local pasta = ReplicatedStorage:FindFirstChild("Modelos")
	local pronto = pasta and especie.modelo and pasta:FindFirstChild(especie.modelo)

	if not pronto or not pronto:IsA("Model") then
		return nil
	end

	local visual = pronto:Clone()
	visual.Name = "Visual"
	higienizar(visual)

	for _, parte in visual:GetDescendants() do
		if parte:IsA("BasePart") then
			parte.Anchored = true
			parte.CanCollide = false
		end
	end

	local ok = pcall(function()
		visual:ScaleTo(escala)
	end)
	if not ok then
		warn("[Mundo] não consegui escalar o modelo " .. tostring(especie.modelo))
	end

	visual:PivotTo(CFrame.new(centro))
	return visual
end

local function construirMonstro(zona, indiceTier: number, pai: Instance)
	local tier = Monstros.tiers[indiceTier]
	local especie = Bestiario[zona.id][indiceTier]
	local escala = tier.escala * especie.escala
	local centro = zona.posicao + Monstros.posicoes[indiceTier]

	local modelo = Instance.new("Model")
	modelo.Name = zona.id .. "_" .. tier.id

	local ancora = bloco(
		"Ancora",
		Vector3.new(3.4 * escala, 5 * escala, 3.4 * escala),
		centro + Vector3.new(0, 2.5 * escala, 0),
		especie.cor,
		Enum.Material.SmoothPlastic,
		modelo
	)
	ancora.Transparency = 1
	ancora.CanCollide = true
	ancora.CanQuery = false

	local visual = visualDeModelo(especie, escala, centro)
		or montarVisual(especie, escala, centro)
	visual.Parent = modelo

	modelo.PrimaryPart = ancora
	modelo:SetAttribute("MonstroId", modelo.Name)
	modelo:SetAttribute("Tier", indiceTier)
	modelo:SetAttribute("Nome", especie.nome)
	modelo:SetAttribute("Vida", Monstros.vidaDe(zona, indiceTier))
	modelo:SetAttribute("DanoExigido", Monstros.danoExigido(zona, indiceTier))
	modelo:SetAttribute("Ataca", tier.ataque > 0)
	modelo:SetAttribute("Altura", Monstros.corpos[especie.corpo].altura * escala)
	modelo:SetAttribute("CorOlho", especie.olho)
	modelo.Parent = pai

	return {
		id = modelo.Name,
		zona = zona,
		indiceTier = indiceTier,
		posicao = ancora.Position,
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
		"Mate os monstros para ganhar Força · siga em frente para os piores",
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

local function construirZona(zona, pai: Instance, pastaBarreiras: Instance, pastaMonstros: Instance)
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
	for indiceTier = 1, #Monstros.tiers do
		table.insert(criados, construirMonstro(zona, indiceTier, pastaMonstros))
	end

	placa(
		zona.nome,
		string.format(
			"Requer %s de Força · monstros de %s a %s de vida",
			Formato.abreviar(zona.forcaMinima),
			Formato.abreviar(Monstros.vidaDe(zona, 1)),
			Formato.abreviar(Monstros.vidaDe(zona, #Monstros.tiers))
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

	local pastaMonstros = Instance.new("Folder")
	pastaMonstros.Name = "Monstros"
	pastaMonstros.Parent = workspace

	construirHub(mundo)

	local bordaAnterior = 45 -- borda frontal do hub
	local todosOsMonstros = {}

	for _, zona in Config.Zonas do
		local frenteZ = zona.posicao.Z - zona.tamanho.Z * 0.5
		construirCaminho(bordaAnterior, frenteZ, mundo)

		for _, monstro in construirZona(zona, mundo, pastaBarreiras, pastaMonstros) do
			table.insert(todosOsMonstros, monstro)
		end

		bordaAnterior = zona.posicao.Z + zona.tamanho.Z * 0.5
	end

	Mundo.monstros = todosOsMonstros
end

return Mundo
