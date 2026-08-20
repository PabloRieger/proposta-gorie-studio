--[[
	A cara do combate: rótulo, barra de vida, número de dano, morte — e a
	animação que faz o monstro parecer vivo.

	Tudo aqui é LOCAL, e isso não é detalhe: a vida do monstro é por jogador,
	então a barra que você vê é a sua. O jogador ao lado tem a dele, no mesmo
	monstro, e um não atrapalha o outro. A morte também é local — o bicho cai
	só para quem o matou e volta sozinho.

	A ANIMAÇÃO TAMBÉM É LOCAL, e de propósito. Balanço, giro e recuo não
	custam um byte de rede: o servidor só conhece a posição fixa da âncora, que
	nunca se move. Por isso o corpo visível não tem colisão — o cliente é livre
	para mexer nele sem afetar a física de ninguém.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Formato = Compartilhado.Formato
local Remotes = Compartilhado.Remotes

local Ui = require(script.Parent.Parent.Ui)
local Estado = require(script.Parent.Parent.Estado)

local player = Players.LocalPlayer

local MonstrosCliente = { ordem = 40 }

local DISTANCIA_ROTULO = 90
local DISTANCIA_ANIMA = 160
local DISTANCIA_ENCARA = 45
local RECUO_MAXIMO = 1.4

local monstros: { [string]: any } = {}

local function montar(modelo: Model)
	local ancora = modelo.PrimaryPart
	local visual = modelo:FindFirstChild("Visual")
	if not ancora or not visual then
		return
	end

	local altura = modelo:GetAttribute("Altura") or 5
	local corOlho = modelo:GetAttribute("CorOlho") or Ui.cores.forca

	local billboard = Ui.novo("BillboardGui", {
		Name = "PainelMonstro",
		Adornee = ancora,
		Size = UDim2.fromOffset(200, 56),
		StudsOffset = Vector3.new(0, altura * 0.55 + 2.2, 0),
		MaxDistance = DISTANCIA_ROTULO,
		AlwaysOnTop = false,
		Parent = player:WaitForChild("PlayerGui"),
	})

	local titulo = Ui.texto({
		Size = UDim2.new(1, 0, 0, 20),
		Text = modelo:GetAttribute("Nome") or "Monstro",
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

	local vida = Ui.novo("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = corOlho,
		BorderSizePixel = 0,
		Parent = trilho,
	}, { Ui.canto(5) })

	monstros[modelo.Name] = {
		modelo = modelo,
		ancora = ancora,
		visual = visual,
		base = visual:GetPivot(),
		billboard = billboard,
		titulo = titulo,
		exigencia = exigencia,
		vida = vida,
		altura = altura,
		danoExigido = modelo:GetAttribute("DanoExigido") or 0,
		-- Fase própria para os monstros não balançarem em uníssono.
		fase = math.random() * math.pi * 2,
		recuo = 0,
		morto = false,
	}
end

--- Marca em vermelho os monstros que o dano atual mal arranha.
local function revisarExigencias()
	local dano = Estado.ler("Dano", 0)

	for _, m in monstros do
		if dano < m.danoExigido then
			m.exigencia.Text = "precisa de " .. Formato.abreviar(m.danoExigido) .. " de dano"
			m.titulo.TextColor3 = Ui.cores.textoFraco
		else
			m.exigencia.Text = ""
			m.titulo.TextColor3 = Ui.cores.texto
		end
	end
end

local function numeroDeDano(m, valor: number, arranhou: boolean)
	local etiqueta = Ui.novo("BillboardGui", {
		Adornee = m.ancora,
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

	TweenService:Create(etiqueta, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {
		StudsOffset = etiqueta.StudsOffset + Vector3.new(0, 3.5, 0),
	}):Play()

	local sumico = TweenService:Create(texto, TweenInfo.new(0.7), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	sumico:Play()
	sumico.Completed:Once(function()
		etiqueta:Destroy()
	end)
end

local function esconder(m, escondido: boolean)
	for _, parte in m.visual:GetDescendants() do
		if parte:IsA("BasePart") then
			parte.LocalTransparencyModifier = if escondido then 1 else 0
		end
	end
	m.ancora.CanCollide = not escondido
	m.billboard.Enabled = not escondido
end

local function aoMorrer(m)
	m.morto = true
	esconder(m, true)

	task.delay(Config.Geral.RENASCE_MONSTRO, function()
		if m.modelo.Parent then
			m.morto = false
			m.recuo = 0
			esconder(m, false)
			m.vida.Size = UDim2.fromScale(1, 1)
		end
	end)
end

local function aoGolpe(resultado)
	local m = monstros[resultado.id]
	if not m then
		return
	end

	numeroDeDano(m, resultado.dano, resultado.arranhou)
	m.recuo = if resultado.arranhou then RECUO_MAXIMO * 0.3 else RECUO_MAXIMO

	local proporcao = if resultado.vida > 0 then resultado.restante / resultado.vida else 0
	m.vida.Size = UDim2.fromScale(math.clamp(proporcao, 0, 1), 1)

	if resultado.morreu then
		aoMorrer(m)
	end
end

--[[
	Balanço, giro e recuo. Um laço só para todos os monstros, e só para os que
	estão perto o bastante de a câmera enxergar.
]]
local function animar(delta: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local olho = camera.CFrame.Position
	local agora = os.clock()

	for _, m in monstros do
		if m.morto then
			continue
		end

		local base = m.base
		local distancia = (base.Position - olho).Magnitude
		if distancia > DISTANCIA_ANIMA then
			continue
		end

		local orientacao = base
		if distancia < DISTANCIA_ENCARA then
			-- Encara a câmera, mas só no eixo vertical: monstro não deita.
			local alvo = Vector3.new(olho.X, base.Position.Y, olho.Z)
			if (alvo - base.Position).Magnitude > 0.1 then
				orientacao = CFrame.lookAt(base.Position, alvo)
			end
		end

		local balanco = math.sin(agora * 2.1 + m.fase) * m.altura * 0.035
		local giro = math.sin(agora * 0.9 + m.fase) * 0.09

		m.recuo = math.max(m.recuo - delta * 5, 0)

		m.visual:PivotTo(
			orientacao
				* CFrame.Angles(0, giro, 0)
				* CFrame.new(0, balanco, m.recuo)
		)
	end
end

function MonstrosCliente.montar()
	local pasta = workspace:WaitForChild("Monstros", 30)
	if not pasta then
		warn("[Monstros] pasta não encontrada em Workspace")
		return
	end

	for _, modelo in pasta:GetChildren() do
		if modelo:IsA("Model") then
			montar(modelo)
		end
	end

	pasta.ChildAdded:Connect(function(modelo)
		if modelo:IsA("Model") then
			task.defer(function()
				montar(modelo)
				revisarExigencias()
			end)
		end
	end)

	Estado.observar({ "Dano" }, revisarExigencias)
end

function MonstrosCliente.ligar()
	Remotes.obter("GolpeResolvido").OnClientEvent:Connect(aoGolpe)
	RunService.Heartbeat:Connect(animar)
end

return MonstrosCliente
