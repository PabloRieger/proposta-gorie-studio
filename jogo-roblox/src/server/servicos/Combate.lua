--[[
	Combate nos bonecos — o laço que o jogador toca 90% do tempo.

	Duas decisões estruturais:

	1. A VIDA DO BONECO É POR JOGADOR. O boneco é um só no mundo, mas cada
	   jogador acumula o próprio dano nele. Sem isso, dois jogadores na mesma
	   fase disputam a mesma barra e quem chega depois é roubado. Quebrar é um
	   evento privado: some só para quem quebrou, e volta em pouco mais de um
	   segundo.

	2. O CLIENTE NÃO ESCOLHE O ALVO. Ele manda "bati" e o servidor decide em
	   qual boneco isso cai, a partir da posição real do personagem. Alvo vindo
	   do cliente é o vetor mais óbvio de exploit num jogo assim.

	O golpe automático roda aqui no servidor, no ritmo reduzido de FATOR_AUTO.
	Ele escolhe o melhor boneco que o jogador realmente machuca, em vez do mais
	perto — bater de graça em pedra a 12% não ajuda ninguém.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Remotes = Compartilhado.Remotes


local Bonecos = Config.Bonecos
local Geral = Config.Geral

local Combate = { ordem = 40 }

local Progresso

local bonecos: { [string]: any } = {}
local progresso: { [Player]: { [string]: number } } = {}
local quebradoAte: { [Player]: { [string]: number } } = {}
local ultimoGolpe: { [Player]: number } = {}

local remoteGolpe = Remotes.obter("GolpeResolvido")

local function limpar(player: Player)
	progresso[player] = nil
	quebradoAte[player] = nil
	ultimoGolpe[player] = nil
end

function Combate.aoSair(player: Player)
	limpar(player)
end

local function estadoDe(player: Player)
	progresso[player] = progresso[player] or {}
	quebradoAte[player] = quebradoAte[player] or {}
	return progresso[player], quebradoAte[player]
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
	Bonecos ao alcance, já filtrados por tudo que o servidor precisa validar:
	fase liberada, boneco de pé para ESTE jogador, distância real.
]]
local function alcancaveis(player: Player, perfil)
	local raiz = raizDe(player)
	if not raiz then
		return {}
	end

	local _, quebrados = estadoDe(player)
	local agora = os.clock()
	local lista = {}

	for id, boneco in bonecos do
		if perfil.forca < boneco.zona.forcaMinima then
			continue
		end
		if (quebrados[id] or 0) > agora then
			continue
		end
		if (boneco.posicao - raiz.Position).Magnitude > Geral.ALCANCE_GOLPE then
			continue
		end

		table.insert(lista, boneco)
	end

	return lista
end

local function maisProximo(lista, posicao: Vector3)
	local escolhido, menor = nil, math.huge
	for _, boneco in lista do
		local distancia = (boneco.posicao - posicao).Magnitude
		if distancia < menor then
			escolhido, menor = boneco, distancia
		end
	end
	return escolhido
end

--- O melhor boneco que o dano do jogador realmente machuca (usado pelo auto).
local function melhorAoAlcance(lista, dano: number)
	local escolhido, melhorTier = nil, 0
	for _, boneco in lista do
		local exigido = Bonecos.danoExigido(boneco.zona, boneco.indiceTier)
		if dano >= exigido and boneco.indiceTier > melhorTier then
			escolhido, melhorTier = boneco, boneco.indiceTier
		end
	end
	-- Nenhum à altura: bate no mais fraco, que ao menos rende alguma coisa.
	if not escolhido then
		local menorTier = math.huge
		for _, boneco in lista do
			if boneco.indiceTier < menorTier then
				escolhido, menorTier = boneco, boneco.indiceTier
			end
		end
	end
	return escolhido
end

local function revidar(player: Player, boneco)
	local revide = Bonecos.tiers[boneco.indiceTier].revida
	if revide <= 0 then
		return
	end

	local personagem = player.Character
	local humano = personagem and personagem:FindFirstChildOfClass("Humanoid")
	if humano and humano.Health > 0 then
		-- A armadura entra no passo 2 e vai reduzir isto.
		humano:TakeDamage(revide)
	end
end

local function quebrar(player: Player, boneco, danos, quebrados)
	local forca, moedas = Bonecos.recompensaDe(boneco.zona, boneco.indiceTier)

	Progresso.adicionarGanho(
		player,
		forca * Progresso.multiplicadorForca(player),
		moedas * Progresso.multiplicadorMoedas(player)
	)

	danos[boneco.id] = 0
	quebrados[boneco.id] = os.clock() + Geral.RENASCE_BONECO
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
	local boneco = if automatico
		then melhorAoAlcance(lista, dano)
		else maisProximo(lista, raiz.Position)

	if not boneco then
		return false
	end

	local exigido = Bonecos.danoExigido(boneco.zona, boneco.indiceTier)
	local arranhou = dano < exigido
	if arranhou then
		dano *= Bonecos.PENALIDADE_DANO_BAIXO
	end

	local danos, quebrados = estadoDe(player)
	local vida = Bonecos.vidaDe(boneco.zona, boneco.indiceTier)
	local acumulado = math.min((danos[boneco.id] or 0) + dano, vida)
	danos[boneco.id] = acumulado

	local caiu = acumulado >= vida
	if caiu then
		quebrar(player, boneco, danos, quebrados)
	else
		revidar(player, boneco)
	end

	remoteGolpe:FireClient(player, {
		id = boneco.id,
		dano = dano,
		vida = vida,
		restante = math.max(vida - acumulado, 0),
		quebrou = caiu,
		arranhou = arranhou,
		automatico = automatico,
	})

	return true
end

function Combate.iniciar(servicos)
	Progresso = servicos.Progresso

	for _, boneco in servicos.Mundo.bonecos do
		bonecos[boneco.id] = boneco
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
