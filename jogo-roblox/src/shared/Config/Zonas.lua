--[[
	Zonas de treino. Esta tabela é a ÚNICA fonte de verdade da geometria:
	o MundoBuilder constrói o mapa a partir dela e o TreinoService usa as
	mesmas caixas para validar em que zona o jogador está.

	`posicao` é o centro da SUPERFÍCIE da plataforma (topo em Y = 0).
	`tamanho.Y` é a espessura do bloco, não a altura útil.

	Curva (medida por simulação, não chutada): o requisito cresce x12 por zona
	enquanto o rendimento cresce x2.1. É essa diferença que faz cada degrau
	custar mais tempo que o anterior — com os dois crescendo junto, o jogo
	inteiro acaba em minutos.
]]

local LARGURA = 70
local ESPESSURA = 3
local PROFUNDIDADE = 70
local PRIMEIRA_Z = 95
local ESPACAMENTO = 90

local function em(indice: number): Vector3
	return Vector3.new(0, 0, PRIMEIRA_Z + (indice - 1) * ESPACAMENTO)
end

local TAMANHO = Vector3.new(LARGURA, ESPESSURA, PROFUNDIDADE)

return {
	{
		id = "vilarejo",
		nome = "Academia do Vilarejo",
		forcaMinima = 0,
		forcaPorTick = 2,
		moedasPorTick = 0.2,
		cor = Color3.fromRGB(104, 178, 128),
		posicao = em(1),
		tamanho = TAMANHO,
	},
	{
		id = "dojo",
		nome = "Dojo da Montanha",
		forcaMinima = 600,
		forcaPorTick = 4.2,
		moedasPorTick = 0.42,
		cor = Color3.fromRGB(94, 176, 196),
		posicao = em(2),
		tamanho = TAMANHO,
	},
	{
		id = "gelo",
		nome = "Caverna de Gelo",
		forcaMinima = 7.2e3,
		forcaPorTick = 8.8,
		moedasPorTick = 0.88,
		cor = Color3.fromRGB(126, 202, 240),
		posicao = em(3),
		tamanho = TAMANHO,
	},
	{
		id = "vulcao",
		nome = "Vulcão Adormecido",
		forcaMinima = 86e3,
		forcaPorTick = 19,
		moedasPorTick = 1.9,
		cor = Color3.fromRGB(226, 110, 78),
		posicao = em(4),
		tamanho = TAMANHO,
	},
	{
		id = "ruinas",
		nome = "Ruínas Flutuantes",
		forcaMinima = 1e6,
		forcaPorTick = 39,
		moedasPorTick = 3.9,
		cor = Color3.fromRGB(196, 176, 120),
		posicao = em(5),
		tamanho = TAMANHO,
	},
	{
		id = "deserto",
		nome = "Deserto Amaldiçoado",
		forcaMinima = 12e6,
		forcaPorTick = 82,
		moedasPorTick = 8.2,
		cor = Color3.fromRGB(230, 186, 106),
		posicao = em(6),
		tamanho = TAMANHO,
	},
	{
		id = "templo",
		nome = "Templo Sombrio",
		forcaMinima = 150e6,
		forcaPorTick = 170,
		moedasPorTick = 17,
		cor = Color3.fromRGB(132, 104, 196),
		posicao = em(7),
		tamanho = TAMANHO,
	},
	{
		id = "fenda",
		nome = "Fenda Estelar",
		forcaMinima = 1.8e9,
		forcaPorTick = 360,
		moedasPorTick = 36,
		cor = Color3.fromRGB(108, 132, 246),
		posicao = em(8),
		tamanho = TAMANHO,
	},
	{
		id = "vazio",
		nome = "Núcleo do Vazio",
		forcaMinima = 21e9,
		forcaPorTick = 760,
		moedasPorTick = 76,
		cor = Color3.fromRGB(72, 72, 96),
		posicao = em(9),
		tamanho = TAMANHO,
	},
	{
		id = "eter",
		nome = "Éter Primordial",
		forcaMinima = 260e9,
		forcaPorTick = 1.6e3,
		moedasPorTick = 160,
		cor = Color3.fromRGB(248, 244, 214),
		posicao = em(10),
		tamanho = TAMANHO,
	},
}
