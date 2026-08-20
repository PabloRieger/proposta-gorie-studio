--[[
	Persistência com DataStore.

	Três cuidados que evitam a perda de progresso mais comum do gênero:

	1. Retentativa com backoff — DataStore falha em pico de jogadores.
	2. Trava de sessão — dois servidores com o mesmo jogador sobrescrevem um
	   ao outro. Guardamos o JobId e só assumimos a sessão se ela estiver
	   livre ou expirada.
	3. Falha de leitura NUNCA vira perfil zerado. Se não conseguimos ler, o
	   jogador é recusado com aviso, em vez de começar do zero e salvar por
	   cima do progresso real.

	Sem acesso a DataStore (Studio com API Services desligado) cai para uma
	tabela em memória, só para o jogo continuar testável.
]]

local DataStoreService = game:GetService("DataStoreService")

local DataService = {}

local NOME_LOJA = "EvolucaoLendaria_v1"
local TENTATIVAS = 5
local SEGUNDOS_SESSAO_EXPIRA = 90
local RODADAS_REIVINDICACAO = 4

local PADRAO = {
	forca = 0,
	moedas = 0,
	evolucao = 0,
	melhorias = {},
	tempoJogado = 0,
	visitas = 0,
	sessao = "",
	carimbo = 0,
}

local perfis: { [Player]: any } = {}
local memoria: { [number]: any } = {}
local loja: DataStore? = nil

local okLoja, resultadoLoja = pcall(function()
	return DataStoreService:GetDataStore(NOME_LOJA)
end)

if okLoja then
	loja = resultadoLoja
else
	warn("[Dados] DataStore indisponível, usando memória temporária: " .. tostring(resultadoLoja))
end

local function copiar(tabela)
	local copia = {}
	for chave, valor in tabela do
		copia[chave] = if typeof(valor) == "table" then copiar(valor) else valor
	end
	return copia
end

--- Preenche campos que não existiam em saves antigos.
local function reconciliar(dados)
	local perfil = copiar(PADRAO)

	if typeof(dados) ~= "table" then
		return perfil
	end

	for chave, padrao in PADRAO do
		local valor = dados[chave]
		if typeof(valor) == typeof(padrao) then
			perfil[chave] = if typeof(valor) == "table" then copiar(valor) else valor
		end
	end

	-- Blindagem contra save corrompido ou adulterado.
	perfil.forca = math.max(tonumber(perfil.forca) or 0, 0)
	perfil.moedas = math.max(tonumber(perfil.moedas) or 0, 0)
	perfil.evolucao = math.max(math.floor(tonumber(perfil.evolucao) or 0), 0)

	local melhorias = {}
	for id, nivel in perfil.melhorias do
		if typeof(id) == "string" and typeof(nivel) == "number" then
			melhorias[id] = math.max(math.floor(nivel), 0)
		end
	end
	perfil.melhorias = melhorias

	return perfil
end

local function chaveDe(player: Player): string
	return "jogador_" .. player.UserId
end

--[[
	`GetDataStore` devolve um objeto mesmo sem acesso às APIs — o erro só
	aparece na primeira chamada de verdade. É o caso de um lugar aberto de
	arquivo e nunca publicado, ou do Studio sem "Enable Studio Access to API
	Services". Insistir nesses erros não adianta: reconhecemos e caímos para
	memória, em vez de recusar a entrada de todo mundo.
]]
local function semAcessoAsApis(erro): boolean
	local texto = string.lower(tostring(erro))
	for _, marca in { "api services", "not allowed", "403", "publish" } do
		if string.find(texto, marca, 1, true) then
			return true
		end
	end
	return false
end

local function desligarLoja(motivo: string)
	if loja then
		loja = nil
		warn(
			"[Dados] DataStore indisponível ("
				.. motivo
				.. "). O progresso vale só enquanto o servidor estiver de pé.\n"
				.. "  Para salvar de verdade: publique o lugar (File > Publish to Roblox As...)\n"
				.. "  e ligue Game Settings > Security > Enable Studio Access to API Services."
		)
	end
end

--- Retorna (deuCerto, resultado, bloqueadoPorAcesso).
local function tentar(funcao)
	local ultimoErro
	for tentativa = 1, TENTATIVAS do
		local ok, resultado = pcall(funcao)
		if ok then
			return true, resultado, false
		end
		ultimoErro = resultado
		if semAcessoAsApis(ultimoErro) then
			return false, nil, true
		end
		task.wait(0.25 * 2 ^ tentativa)
	end
	warn("[Dados] desisti após " .. TENTATIVAS .. " tentativas: " .. tostring(ultimoErro))
	return false, nil, false
end

--- Toma posse da sessão do jogador. Retorna nil se outro servidor ainda a segura.
local function reivindicar(chave: string)
	for _ = 1, RODADAS_REIVINDICACAO do
		local ok, dados, bloqueado = tentar(function()
			return (loja :: DataStore):UpdateAsync(chave, function(antigo)
				local perfil = antigo or copiar(PADRAO)
				local sessao = perfil.sessao
				local carimbo = tonumber(perfil.carimbo) or 0
				local expirada = os.time() - carimbo > SEGUNDOS_SESSAO_EXPIRA

				if sessao and sessao ~= "" and sessao ~= game.JobId and not expirada then
					-- Retornar nil cancela a escrita: o outro servidor manda.
					return nil
				end

				perfil.sessao = game.JobId
				perfil.carimbo = os.time()
				return perfil
			end)
		end)

		if bloqueado then
			return nil, true
		end

		if ok and dados then
			return dados, false
		end

		task.wait(3)
	end

	return nil, false
end

--- Carrega (ou cria) o perfil. Retorna nil quando não foi seguro carregar.
function DataService.carregar(player: Player)
	local dados

	if loja then
		local carregado, bloqueado = reivindicar(chaveDe(player))

		if bloqueado then
			desligarLoja("o lugar não tem acesso às APIs")
		elseif not carregado then
			-- Falha transitória: recusar a entrada é melhor do que começar do
			-- zero e salvar por cima do progresso que não conseguimos ler.
			return nil
		else
			dados = carregado
		end
	end

	if not loja then
		dados = memoria[player.UserId] or copiar(PADRAO)
	end

	local perfil = reconciliar(dados)
	perfil.visitas += 1
	perfil.entradaEm = os.clock()

	perfis[player] = perfil
	return perfil
end

function DataService.obter(player: Player)
	return perfis[player]
end

function DataService.salvar(player: Player, liberarSessao: boolean?)
	local perfil = perfis[player]
	if not perfil then
		return
	end

	if perfil.entradaEm then
		perfil.tempoJogado += os.clock() - perfil.entradaEm
		perfil.entradaEm = os.clock()
	end

	local copia = copiar(perfil)
	copia.entradaEm = nil
	copia.sessao = if liberarSessao then "" else game.JobId
	copia.carimbo = os.time()

	if not loja then
		memoria[player.UserId] = copia
		return
	end

	tentar(function()
		return (loja :: DataStore):UpdateAsync(chaveDe(player), function()
			return copia
		end)
	end)
end

function DataService.descarregar(player: Player)
	DataService.salvar(player, true)
	perfis[player] = nil
end

function DataService.iniciar(intervaloAutosave: number)
	-- Uma chamada barata só para descobrir o acesso agora, e não no meio do
	-- primeiro PlayerAdded.
	if loja then
		local _, _, bloqueado = tentar(function()
			return (loja :: DataStore):GetAsync("__sonda_de_acesso")
		end)
		if bloqueado then
			desligarLoja("sonda de acesso recusada")
		end
	end

	task.spawn(function()
		while true do
			task.wait(intervaloAutosave)
			for player in perfis do
				task.spawn(DataService.salvar, player, false)
			end
		end
	end)

	game:BindToClose(function()
		for player in perfis do
			task.spawn(DataService.salvar, player, true)
		end
		-- Dá tempo das escritas terminarem antes do servidor morrer.
		task.wait(3)
	end)
end

return DataService
