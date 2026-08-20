--[[
	Zonas de treino. Esta tabela é a ÚNICA fonte de verdade da geometria:
	o MundoBuilder constrói o mapa a partir dela e o CombateService usa as
	mesmas caixas para validar em que zona o jogador está.

	`posicao` é o centro da SUPERFÍCIE da plataforma (topo em Y = 0).
	`tamanho.Y` é a espessura do bloco, não a altura útil.

	`forcaMinima` é o que destrava a fase seguinte — e é a ÚNICA porta
	obrigatória. Parkour e chefão são a trilha rápida, não o caminho.

	`monstro` é a base da fase: os quatro tiers em Monstros.lua são
	multiplicadores sobre estes três números, então rebalancear uma fase
	inteira é mexer aqui.

	Os valores atuais dão uma curva jogável para testar o combate. O
	balanceamento de verdade é refeito por simulação depois que chefe,
	equipamento e mascote existirem — com HP e drop no meio, estimar na mão
	dá errado.
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
		monstro = {
			vida = 15,
			forca = 10,
			moedas = 1.2,
		},
		cor = Color3.fromRGB(104, 178, 128),
		posicao = em(1),
		tamanho = TAMANHO,
	},
	{
		id = "dojo",
		nome = "Dojo da Montanha",
		forcaMinima = 600,
		monstro = {
			vida = 39,
			forca = 22,
			moedas = 2.6,
		},
		cor = Color3.fromRGB(94, 176, 196),
		posicao = em(2),
		tamanho = TAMANHO,
	},
	{
		id = "gelo",
		nome = "Caverna de Gelo",
		forcaMinima = 7.2e3,
		monstro = {
			vida = 100,
			forca = 48,
			moedas = 5.8,
		},
		cor = Color3.fromRGB(126, 202, 240),
		posicao = em(3),
		tamanho = TAMANHO,
	},
	{
		id = "vulcao",
		nome = "Vulcão Adormecido",
		forcaMinima = 86e3,
		monstro = {
			vida = 260,
			forca = 110,
			moedas = 13,
		},
		cor = Color3.fromRGB(226, 110, 78),
		posicao = em(4),
		tamanho = TAMANHO,
	},
	{
		id = "ruinas",
		nome = "Ruínas Flutuantes",
		forcaMinima = 1e6,
		monstro = {
			vida = 690,
			forca = 230,
			moedas = 28,
		},
		cor = Color3.fromRGB(196, 176, 120),
		posicao = em(5),
		tamanho = TAMANHO,
	},
	{
		id = "deserto",
		nome = "Deserto Amaldiçoado",
		forcaMinima = 12e6,
		monstro = {
			vida = 1.8e3,
			forca = 520,
			moedas = 62,
		},
		cor = Color3.fromRGB(230, 186, 106),
		posicao = em(6),
		tamanho = TAMANHO,
	},
	{
		id = "templo",
		nome = "Templo Sombrio",
		forcaMinima = 150e6,
		monstro = {
			vida = 4.6e3,
			forca = 1.1e3,
			moedas = 130,
		},
		cor = Color3.fromRGB(132, 104, 196),
		posicao = em(7),
		tamanho = TAMANHO,
	},
	{
		id = "fenda",
		nome = "Fenda Estelar",
		forcaMinima = 1.8e9,
		monstro = {
			vida = 12e3,
			forca = 2.5e3,
			moedas = 300,
		},
		cor = Color3.fromRGB(108, 132, 246),
		posicao = em(8),
		tamanho = TAMANHO,
	},
	{
		id = "vazio",
		nome = "Núcleo do Vazio",
		forcaMinima = 21e9,
		monstro = {
			vida = 31e3,
			forca = 5.5e3,
			moedas = 660,
		},
		cor = Color3.fromRGB(72, 72, 96),
		posicao = em(9),
		tamanho = TAMANHO,
	},
	{
		id = "eter",
		nome = "Éter Primordial",
		forcaMinima = 260e9,
		monstro = {
			vida = 81e3,
			forca = 12e3,
			moedas = 1.4e3,
		},
		cor = Color3.fromRGB(248, 244, 214),
		posicao = em(10),
		tamanho = TAMANHO,
	},
}
