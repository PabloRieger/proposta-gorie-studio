--[[
	Combate — o laço que o jogador toca 90% do tempo.

	Duas decisões estruturais:

	1. A VIDA DO MONSTRO É POR JOGADOR. O monstro é um só no mundo, mas cada
	   jogador acumula o próprio dano nele. Sem isso, dois jogadores na mesma
	   fase disputam a mesma barra e quem chega depois é roubado. Matar é um
	   evento privado: o monstro cai só para quem o matou, e volta em pouco
	   mais de um segundo.

	2. O CLIENTE NÃO ESCOLHE O ALVO. Ele manda "bati" e o servidor decide em
	   qual monstro isso cai, a partir da posição real do personagem. Alvo vindo
	   do cliente é o vetor mais óbvio de exploit num jogo assim.

	O golpe automático roda aqui no servidor, no ritmo reduzido de FATOR_AUTO.
	Ele escolhe o melhor monstro que o jogador realmente machuca, em vez do mais
	perto — bater de graça no monstro mais duro a 12% não ajuda ninguém.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Remotes = Compartilhado.Remotes


local Monstros = Config.Monstros
local Geral = Config.Geral

local Combate = { ordem = 40 }

local Progresso

local monstros: { [string]: any } = {}
local progresso: { [Player]: { [string]: number } } = {}
local derrubadoAte: { [Player]: { [string]: number } } = {}
local ultimoGolpe: { [Player]: number } = {}

local remoteGolpe = Remotes.obter("GolpeResolvido")

local function limpar(player: Player)
	progresso[player] = nil
	derrubadoAte[player] = nil
	ultimoGolpe[player] = nil
end

function Combate.aoSair(player: Player)
	limpar(player)
end

local function estadoDe(player: Player)
	progresso[player] = progresso[player] or {}
	derrubadoAte[player] = derrubadoAte[player] or {}
	return progresso[player], derrubadoAte[player]
end

local function raizDe(player: Player): BasePart?
	local personagem = player.Character
	if not personagem then
		return nil
	end

	local humano = personagem:FindFirstChildOfClass("Humanoid")
	if not humano or humano.Health <= 0 then
		return nil
	end

	local raiz = personagem:FindFirstChild("HumanoidRootPart")
	return if raiz and raiz:IsA("BasePart") then raiz else nil
end

--[[
	Monstros ao alcance, já filtrados por tudo que o servidor precisa validar:
	fase liberada, monstro de pé para ESTE jogador, distância real.
]]
local function alcancaveis(player: Player, perfil)
	local raiz = raizDe(player)
	if not raiz then
		return {}
	end

	local _, derrubados = estadoDe(player)
	local agora = os.clock()
	local lista = {}

	for id, monstro in monstros do
		if perfil.forca < monstro.zona.forcaMinima then
			continue
		end
		if (derrubados[id] or 0) > agora then
			continue
		end
		if (monstro.posicao - raiz.Position).Magnitude > Geral.ALCANCE_GOLPE then
			continue
		end

		table.insert(lista, monstro)
	end

	return lista
end

local function maisProximo(lista, posicao: Vector3)
	local escolhido, menor = nil, math.huge
	for _, monstro in lista do
		local distancia = (monstro.posicao - posicao).Magnitude
		if distancia < menor then
			escolhido, menor = monstro, distancia
		end
	end
	return escolhido
end

--- O melhor monstro que o dano do jogador realmente machuca (usado pelo auto).
local function melhorAoAlcance(lista, dano: number)
	local escolhido, melhorTier = nil, 0
	for _, monstro in lista do
		local exigido = Monstros.danoExigido(monstro.zona, monstro.indiceTier)
		if dano >= exigido and monstro.indiceTier > melhorTier then
			escolhido, melhorTier = monstro, monstro.indiceTier
		end
	end
	-- Nenhum à altura: bate no mais fraco, que ao menos rende alguma coisa.
	if not escolhido then
		local menorTier = math.huge
		for _, monstro in lista do
			if monstro.indiceTier < menorTier then
				escolhido, menorTier = monstro, monstro.indiceTier
			end
		end
	end
	return escolhido
end

--[[
	O monstro revida. O ataque é porcentagem da vida máxima, não valor fixo:
	assim ele machuca o mesmo tanto em qualquer fase, e a armadura continua
	relevante na última.
]]
local function contraAtacar(player: Player, monstro)
	local percentual = Monstros.tiers[monstro.indiceTier].ataque
	if percentual <= 0 then
		return
	end

	local personagem = player.Character
	local humano = personagem and personagem:FindFirstChildOfClass("Humanoid")
	if not humano or humano.Health <= 0 then
		return
	end

	local bruto = humano.MaxHealth * (percentual / 100)
	humano:TakeDamage(bruto * (1 - Progresso.reducaoArmadura(player)))
end

local function derrubar(player: Player, monstro, danos, derrubados)
	local forca, moedas = Monstros.recompensaDe(monstro.zona, monstro.indiceTier)

	Progresso.adicionarGanho(
		player,
		forca * Progresso.multiplicadorForca(player),
		moedas * Progresso.multiplicadorMoedas(player)
	)

	danos[monstro.id] = 0
	derrubados[monstro.id] = os.clock() + Geral.RENASCE_MONSTRO
end

--- Resolve um golpe. Retorna se algo foi atingido.
local function golpear(player: Player, automatico: boolean): boolean
	local perfil = Progresso.obter(player)
	local raiz = raizDe(player)
	if not perfil or not raiz then
		return false
	end

	local lista = alcancaveis(player, perfil)
	if #lista == 0 then
		return false
	end

	local dano = Progresso.dano(player)
	local monstro = if automatico
		then melhorAoAlcance(lista, dano)
		else maisProximo(lista, raiz.Position)

	if not monstro then
		return false
	end

	local exigido = Monstros.danoExigido(monstro.zona, monstro.indiceTier)
	local arranhou = dano < exigido
	if arranhou then
		dano *= Monstros.PENALIDADE_DANO_BAIXO
	end

	local danos, derrubados = estadoDe(player)
	local vida = Monstros.vidaDe(monstro.zona, monstro.indiceTier)
	local acumulado = math.min((danos[monstro.id] or 0) + dano, vida)
	danos[monstro.id] = acumulado

	local caiu = acumulado >= vida
	if caiu then
		derrubar(player, monstro, danos, derrubados)
	else
		contraAtacar(player, monstro)
	end

	remoteGolpe:FireClient(player, {
		id = monstro.id,
		dano = dano,
		vida = vida,
		restante = math.max(vida - acumulado, 0),
		morreu = caiu,
		arranhou = arranhou,
		automatico = automatico,
	})

	return true
end

function Combate.iniciar(servicos)
	Progresso = servicos.Progresso

	for _, monstro in servicos.Mundo.monstros do
		monstros[monstro.id] = monstro
	end

	local remoteBater = Remotes.obter("Bater")
	local remoteAuto = Remotes.obter("AlternarAuto")

	remoteBater.OnServerEvent:Connect(function(player)
		local agora = os.clock()
		if agora - (ultimoGolpe[player] or 0) < Geral.COOLDOWN_GOLPE then
			return
		end
		ultimoGolpe[player] = agora

		golpear(player, false)
	end)

	remoteAuto.OnServerEvent:Connect(function(player, ligado)
		local perfil = Progresso.obter(player)
		if not perfil or typeof(ligado) ~= "boolean" then
			return
		end

		perfil.autoLigado = ligado
		Progresso.sincronizar(player)
	end)

	-- Laço do golpe automático.
	task.spawn(function()
		local intervalo = Geral.COOLDOWN_GOLPE / Geral.FATOR_AUTO
		while true do
			task.wait(intervalo)
			for _, player in Players:GetPlayers() do
				local perfil = Progresso.obter(player)
				if perfil and perfil.autoLigado then
					golpear(player, true)
				end
			end
		end
	end)

	-- Só para o HUD saber onde o jogador está.
	task.spawn(function()
		while true do
			task.wait(0.4)
			for _, player in Players:GetPlayers() do
				local perfil = Progresso.obter(player)
				local raiz = perfil and raizDe(player)
				local zona = nil

				if raiz then
					for _, candidata in Config.Zonas do
						local meio = candidata.tamanho * 0.5
						local p = raiz.Position
						if
							math.abs(p.X - candidata.posicao.X) <= meio.X
							and math.abs(p.Z - candidata.posicao.Z) <= meio.Z
							and p.Y > candidata.posicao.Y - 6
							and p.Y < candidata.posicao.Y + 60
						then
							zona = candidata
							break
						end
					end
				end

				if perfil then
					player:SetAttribute("ZonaAtual", zona and zona.nome or "")
					player:SetAttribute(
						"ZonaBloqueada",
						zona ~= nil and perfil.forca < zona.forcaMinima
					)
				end
			end
		end
	end)
end

return Combate
