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
local S = Compartilhado.Config.Sensacao
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

	--[[
		Cada peça guarda o próprio lugar RELATIVO ao pivô do visual, não a
		posição no mundo: o `animar` mexe no pivô todo quadro, então posição
		absoluta guardada aqui estaria errada meio segundo depois.
	]]
	local pivo = visual:GetPivot()
	local pecas, transparencias = {}, {}

	for _, parte in visual:GetDescendants() do
		if parte:IsA("BasePart") then
			pecas[parte] = pivo:Inverse() * parte.CFrame
			transparencias[parte] = parte.Transparency
		end
	end

	local brilho = Ui.novo("Highlight", {
		Name = "Impacto",
		Adornee = modelo,
		FillTransparency = 0.55,
		OutlineTransparency = 1,
		DepthMode = Enum.HighlightDepthMode.Occluded,
		Enabled = false,
		Parent = modelo,
	})

	monstros[modelo.Name] = {
		modelo = modelo,
		pecas = pecas,
		transparencias = transparencias,
		brilho = brilho,
		piscaAte = 0,
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

local function numeroDeDano(m, valor: number, arranhou: boolean, critico: boolean)
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
		Text = (if arranhou then "" else "-")
			.. Formato.abreviar(valor)
			.. (if critico then "!" else ""),
		TextColor3 = if arranhou
			then Ui.cores.textoFraco
			elseif critico then Ui.cores.moeda
			else Ui.cores.forca,
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Ui.fonteTitulo,
		TextSize = if arranhou then 16 elseif critico then 38 else 24,
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

--[[
	Flash branco no impacto. Highlight custa menos que trocar a cor de cada
	peça e devolver depois — e não corre o risco de deixar um monstro branco
	para sempre se algo interromper no meio.
]]
local function piscar(m, critico: boolean)
	if not m.brilho then
		return
	end

	m.brilho.FillColor = if critico then Color3.fromRGB(255, 226, 140) else Color3.new(1, 1, 1)
	m.brilho.FillTransparency = if critico then 0.35 else 0.55
	m.brilho.Enabled = true

	m.piscaAte = os.clock() + (if critico then 0.12 else 0.07)
	task.delay(if critico then 0.12 else 0.07, function()
		if m.brilho and os.clock() >= m.piscaAte then
			m.brilho.Enabled = false
		end
	end)
end

--[[
	Morte que se vê: as peças voam e somem, em vez de o monstro sumir de um
	quadro para o outro. Cada peça guarda o próprio lugar relativo ao pivô, e é
	de lá que ela volta no renascimento.
]]
local function espalhar(m)
	for parte, _ in m.pecas do
		local direcao = Vector3.new(
			math.random() * 2 - 1,
			math.random() * 1.2 + 0.4,
			math.random() * 2 - 1
		).Unit

		TweenService:Create(parte, TweenInfo.new(S.MORTE_ESPALHA, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			CFrame = (parte.CFrame + direcao * S.MORTE_FORCA)
				* CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6),
			Transparency = 1,
		}):Play()
	end
end

local function recompor(m)
	local pivo = m.visual:GetPivot()
	for parte, offset in m.pecas do
		parte.CFrame = pivo * offset
		parte.Transparency = m.transparencias[parte] or 0
	end
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
	m.ancora.CanCollide = false
	m.billboard.Enabled = false
	if m.brilho then
		m.brilho.Enabled = false
	end

	espalhar(m)

	task.delay(S.MORTE_ESPALHA, function()
		esconder(m, true)
	end)

	task.delay(Config.Geral.RENASCE_MONSTRO, function()
		if m.modelo.Parent then
			recompor(m)
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

	numeroDeDano(m, resultado.dano, resultado.arranhou, resultado.critico)
	if not resultado.arranhou then
		piscar(m, resultado.critico)
	end
	m.recuo = if resultado.arranhou
		then RECUO_MAXIMO * 0.3
		elseif resultado.critico then RECUO_MAXIMO * 2
		else RECUO_MAXIMO

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
