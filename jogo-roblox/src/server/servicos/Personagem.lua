--[[
	Traduz os números em algo visível no personagem: tamanho pelo rank,
	aura e brilho pela evolução, velocidade e salto pelas melhorias.

	Sem esta camada o jogo vira uma planilha — é aqui que o jogador
	SENTE que evoluiu.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config


local Melhorias = Config.Melhorias
local Geral = Config.Geral

local Personagem = { ordem = 50 }

local Progresso

local ultimaAssinatura: { [Player]: string } = {}

local ESCALAS_CORPO = { "BodyDepthScale", "BodyHeightScale", "BodyWidthScale" }
local TEXTURA_AURA = "rbxasset://textures/particles/sparkles_main.dds"

local function aplicarEscala(humano: Humanoid, indiceRank: number)
	local degraus = math.max(#Config.Ranks - 1, 1)
	local proporcao = (indiceRank - 1) / degraus
	local escala = Geral.ESCALA_MINIMA + proporcao * (Geral.ESCALA_MAXIMA - Geral.ESCALA_MINIMA)

	-- Só existe em R15; em R6 estes valores simplesmente não estão lá.
	for _, nome in ESCALAS_CORPO do
		local valor = humano:FindFirstChild(nome)
		if valor and valor:IsA("NumberValue") then
			valor.Value = escala
		end
	end

	local cabeca = humano:FindFirstChild("HeadScale")
	if cabeca and cabeca:IsA("NumberValue") then
		cabeca.Value = math.min(escala, Geral.ESCALA_CABECA_MAXIMA)
	end
end

local function aplicarAura(raiz: BasePart, nivelEvolucao: number)
	local evolucao = Progresso.evolucaoDe(nivelEvolucao)
	local ativa = nivelEvolucao > 0

	local luz = raiz:FindFirstChild("AuraLuz") :: PointLight?
	if not luz then
		luz = Instance.new("PointLight")
		luz.Name = "AuraLuz"
		luz.Parent = raiz
	end
	luz.Color = evolucao.cor
	luz.Range = math.min(10 + nivelEvolucao * 1.5, 30)
	luz.Brightness = 1.6
	luz.Enabled = ativa

	local particulas = raiz:FindFirstChild("AuraParticulas") :: ParticleEmitter?
	if not particulas then
		particulas = Instance.new("ParticleEmitter")
		particulas.Name = "AuraParticulas"
		particulas.Texture = TEXTURA_AURA
		particulas.Lifetime = NumberRange.new(0.6, 1.2)
		particulas.Speed = NumberRange.new(1, 3)
		particulas.SpreadAngle = Vector2.new(180, 180)
		particulas.LightEmission = 0.8
		particulas.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(1, 0),
		})
		particulas.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		particulas.Parent = raiz
	end
	particulas.Color = ColorSequence.new(evolucao.cor)
	particulas.Rate = if ativa then math.min(6 + nivelEvolucao * 3, 45) else 0
	particulas.Enabled = ativa
end

--[[
	Progresso.Alterado dispara a cada tick de treino. Redimensionar o corpo e
	recriar a aura nessa frequência seria desperdício puro, então guardamos uma
	assinatura do que de fato importa visualmente e só reaplicamos quando ela muda.
]]
local function assinatura(perfil): string
	return table.concat({
		Progresso.indiceRank(perfil.forca),
		perfil.evolucao,
		perfil.melhorias.velocidade or 0,
		perfil.melhorias.salto or 0,
	}, "|")
end

local function aplicar(player: Player, forcar: boolean?)
	local personagem = player.Character
	if not personagem then
		return
	end

	local humano = personagem:FindFirstChildOfClass("Humanoid")
	local perfil = Progresso.obter(player)
	if not humano or not perfil or humano.Health <= 0 then
		return
	end

	local atual = assinatura(perfil)
	if not forcar and ultimaAssinatura[player] == atual then
		return
	end
	ultimaAssinatura[player] = atual

	humano.WalkSpeed = Geral.VELOCIDADE_BASE
		+ Melhorias.bonus("velocidade", perfil.melhorias.velocidade or 0)
	humano.UseJumpPower = true
	humano.JumpPower = Geral.SALTO_BASE + Melhorias.bonus("salto", perfil.melhorias.salto or 0)

	aplicarEscala(humano, Progresso.indiceRank(perfil.forca))

	local raiz = personagem:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		aplicarAura(raiz, perfil.evolucao)
	end
end

function Personagem.aoEntrar(player: Player)
	player.CharacterAppearanceLoaded:Connect(function()
		-- Corpo novo: a assinatura antiga não vale mais, reaplica tudo.
		-- O defer dá um quadro para a Roblox terminar de montar as escalas do R15.
		task.defer(aplicar, player, true)
	end)

	if player.Character then
		task.defer(aplicar, player, true)
	end
end

function Personagem.aoSair(player: Player)
	ultimaAssinatura[player] = nil
end

function Personagem.iniciar(servicos)
	Progresso = servicos.Progresso

	Progresso.Alterado:Connect(function(player)
		aplicar(player)
	end)
end

return Personagem
