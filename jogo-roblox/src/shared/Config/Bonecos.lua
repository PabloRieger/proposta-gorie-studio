--[[
	Os quatro bonecos de cada fase.

	A escada não é só "mais vida, mais recompensa" — cada degrau cobra uma coisa
	que o anterior não cobrava, para que a loja tenha o que responder:

	  1. Palha   sempre cede. Existe para ninguém ficar travado sem opção.
	  2. Madeira pede a espada da fase.
	  3. Ferro   revida: pede armadura.
	  4. Pedra   ainda não cede. Rende muito mais, mas exige equipamento de
	             chefe ou mascote. Dá para insistir — só que teimar é pior do
	             que ir buscar o que falta.

	`vida`, `recompensa` e `exigeDano` são MULTIPLICADORES sobre a base da zona
	(Zonas[i].boneco). Assim o formato da escada é igual em todas as fases e o
	balanceamento mexe num número só por fase.

	`exigeDano` é lido contra a vida-base da zona: exigeDano = 6 significa
	"cada golpe seu precisa tirar 6x a vida de um boneco de palha daqui".
	Abaixo disso o golpe ainda entra, mas arranhando.
]]

local Bonecos = {}

--- Quanto do golpe passa quando você não alcança o dano exigido.
Bonecos.PENALIDADE_DANO_BAIXO = 0.12

Bonecos.tiers = {
	{
		id = "palha",
		nome = "Efígie de Palha",
		vida = 1,
		recompensa = 1,
		exigeDano = 0,
		revida = 0,
		cor = Color3.fromRGB(214, 190, 130),
		escala = 0.9,
	},
	{
		id = "madeira",
		nome = "Efígie de Madeira",
		vida = 7,
		recompensa = 6,
		exigeDano = 0.15,
		revida = 0,
		cor = Color3.fromRGB(150, 110, 72),
		escala = 1.0,
	},
	{
		id = "ferro",
		nome = "Efígie de Ferro",
		vida = 45,
		recompensa = 34,
		exigeDano = 0.9,
		revida = 6,
		cor = Color3.fromRGB(148, 158, 176),
		escala = 1.15,
	},
	{
		id = "pedra",
		nome = "Efígie de Pedra",
		vida = 300,
		recompensa = 190,
		exigeDano = 6,
		revida = 22,
		cor = Color3.fromRGB(104, 104, 112),
		escala = 1.35,
	},
}

--- Posição de cada boneco dentro da plataforma, relativa ao centro dela.
Bonecos.posicoes = {
	Vector3.new(-19, 0, -13),
	Vector3.new(-7, 0, -19),
	Vector3.new(7, 0, -19),
	Vector3.new(19, 0, -13),
}

function Bonecos.vidaDe(zona, indiceTier: number): number
	return math.floor(zona.boneco.vida * Bonecos.tiers[indiceTier].vida)
end

function Bonecos.danoExigido(zona, indiceTier: number): number
	return zona.boneco.vida * Bonecos.tiers[indiceTier].exigeDano
end

function Bonecos.recompensaDe(zona, indiceTier: number): (number, number)
	local fator = Bonecos.tiers[indiceTier].recompensa
	return zona.boneco.forca * fator, zona.boneco.moedas * fator
end

return Bonecos
