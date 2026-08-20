--[[
	A sua metade do golpe: braço que balança, hit stop, tremor de câmera e som.
	A metade do monstro (recuo, flash, morte) fica em Monstros.lua.

	MEXER AQUI para: como o golpe SE SENTE. Os números todos vêm de
	Config/Sensacao.lua — este arquivo é só o mecanismo.

	Duas decisões que valem explicar:

	1. O BRAÇO SOBE NO PEDIDO, NÃO NA RESPOSTA. Esperar o servidor confirmar
	   para animar significa o braço atrasar o tanto do ping do jogador, e
	   controle que atrasa é controle que parece quebrado. Então o movimento
	   sai na hora do clique e os efeitos de impacto (som, tremor, número)
	   entram quando a resposta chega. Errar o alvo não custa nada: o braço
	   balançou à toa, e ninguém percebe.

	2. NADA DE ANIMAÇÃO IMPORTADA. Rotacionar o Motor6D do ombro não precisa de
	   asset nenhum, funciona em R6 e R15, e compõe por cima da animação de
	   andar em vez de brigar com ela.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Eventos = Compartilhado.Eventos
local Remotes = Compartilhado.Remotes

local S = Config.Sensacao
local player = Players.LocalPlayer

local Impacto = { ordem = 40 }

local ombroOriginal: CFrame? = nil

--[[
	Geração do balanço em curso. Um golpe novo INTERROMPE o anterior em vez de
	ser ignorado: com hit stop de crítico o movimento passa dos 0.35s do
	cooldown, e a versão que ignorava deixava o braço parado no golpe seguinte
	toda vez que saía um crítico. Input que some é pior que animação cortada.
]]
local geracao = 0

local tremorAte = 0
local tremorForca = 0

-- ------------------------------------------------------------------- som

local function tocar(nome: string, em: BasePart?)
	local receita = S.SONS[nome]
	if not receita then
		return
	end

	local som = Instance.new("Sound")
	som.SoundId = receita.id
	som.Volume = receita.volume
	som.PlaybackSpeed = receita.tom
		+ (math.random() * 2 - 1) * S.VARIACAO_TOM
	som.RollOffMaxDistance = S.ALCANCE_SOM

	-- Preso a uma parte, o som ganha posição no mundo; solto, toca no ouvido.
	som.Parent = em or SoundService
	som:Play()

	-- Som que não carrega nunca dispara Ended; o Debris evita vazamento.
	game:GetService("Debris"):AddItem(som, 6)
	som.Ended:Once(function()
		som:Destroy()
	end)
end

-- ---------------------------------------------------------------- câmera

local function tremer(intensidade: number)
	-- Tremor novo não soma ao anterior: dois golpes seguidos embrulhariam a tela.
	tremorForca = math.max(tremorForca, intensidade)
	tremorAte = os.clock() + S.TREMOR_DURACAO
end

local function aplicarTremor()
	local camera = workspace.CurrentCamera
	local restante = tremorAte - os.clock()

	if not camera or restante <= 0 then
		tremorForca = 0
		return
	end

	local f = tremorForca * (restante / S.TREMOR_DURACAO)
	camera.CFrame = camera.CFrame
		* CFrame.new((math.random() * 2 - 1) * f, (math.random() * 2 - 1) * f, 0)
		* CFrame.Angles(0, 0, (math.random() * 2 - 1) * f * 0.02)
end

-- ----------------------------------------------------------------- braço

--- Motor do ombro direito. Existe nos dois rigs, em lugares diferentes.
local function ombro(): Motor6D?
	local personagem = player.Character
	if not personagem then
		return nil
	end

	local bracoR15 = personagem:FindFirstChild("RightUpperArm")
	local motor = bracoR15 and bracoR15:FindFirstChild("RightShoulder")

	if not motor then
		local torso = personagem:FindFirstChild("Torso")
		motor = torso and torso:FindFirstChild("Right Shoulder")
	end

	return if motor and motor:IsA("Motor6D") then motor else nil
end

local function girar(motor: Motor6D, graus: number, duracao: number)
	local destino = (ombroOriginal :: CFrame) * CFrame.Angles(math.rad(graus), 0, 0)
	local tween = TweenService:Create(
		motor,
		TweenInfo.new(duracao, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ C0 = destino }
	)
	tween:Play()
	return tween
end

--[[
	Prepara, ataca, segura e volta. O "segura" é o hit stop: sem ele o braço
	desliza pelo alvo e o golpe não tem peso nenhum.
]]
local function balancar(critico: boolean)
	local motor = ombro()
	if not motor then
		return
	end

	ombroOriginal = ombroOriginal or motor.C0

	geracao += 1
	local minha = geracao

	tocar("golpe")

	task.spawn(function()
		local function atual(): boolean
			return geracao == minha
		end

		girar(motor, S.ANGULO_PREPARO, S.PREPARO)
		task.wait(S.PREPARO)
		if not atual() then
			return
		end

		girar(motor, S.ANGULO_ATAQUE, S.ATAQUE)
		task.wait(S.ATAQUE)
		if not atual() then
			return
		end

		task.wait(if critico then S.HIT_STOP_CRITICO else S.HIT_STOP)
		if not atual() then
			return
		end

		girar(motor, 0, S.RETORNO)
	end)
end

-- --------------------------------------------------------------- impacto

local function aoResolver(resultado)
	local alvo: BasePart? = nil
	local pasta = workspace:FindFirstChild("Monstros")
	local modelo = pasta and pasta:FindFirstChild(resultado.id)
	if modelo and modelo:IsA("Model") then
		alvo = modelo.PrimaryPart
	end

	if resultado.morreu then
		tocar("morte", alvo)
		tremer(S.TREMOR_MORTE)
	elseif resultado.arranhou then
		tocar("arranhao", alvo)
	elseif resultado.critico then
		tocar("critico", alvo)
		tremer(S.TREMOR_CRITICO)
	else
		tocar("impacto", alvo)
		tremer(S.TREMOR_NORMAL)
	end
end

function Impacto.montar() end

function Impacto.ligar()
	Eventos.sinal("GolpeIniciado"):Connect(function()
		balancar(false)
	end)

	Remotes.obter("GolpeResolvido").OnClientEvent:Connect(aoResolver)

	-- Corpo novo, motor novo: o C0 guardado não vale mais.
	player.CharacterAdded:Connect(function()
		-- Corpo novo, motor novo: o C0 guardado não vale mais.
		ombroOriginal = nil
		geracao += 1
	end)

	RunService:BindToRenderStep(
		"TremorDeCombate",
		Enum.RenderPriority.Camera.Value + 1,
		aplicarTremor
	)

	-- O servidor já avisa o que deu certo; o som segue o aviso.
	Remotes.obter("Notificar").OnClientEvent:Connect(function(_mensagem, tipo)
		if tipo == "sucesso" then
			tocar("compra")
		end
	end)
end

return Impacto
