--[[
	O FORMATO do monstro: a escada de dificuldade e as receitas de corpo.
	A lista de espécies mora em Bestiario.lua — aqui não há nome de bicho.

	A escada não é só "mais vida, mais recompensa". Cada degrau cobra uma coisa
	que o anterior não cobrava, para que a loja tenha o que responder:

	  1. fraco   sempre cede. Existe para ninguém ficar travado sem opção.
	  2. comum   pede a espada da fase.
	  3. bruto   ataca de volta: pede armadura.
	  4. temido  ainda não cede. Rende muito mais, mas exige equipamento de
	             chefe ou mascote. Dá para insistir — só que teimar é pior do
	             que ir buscar o que falta.

	`vida`, `recompensa` e `exigeDano` são MULTIPLICADORES sobre a base da zona
	(Zonas[i].monstro). O formato da escada é igual em todas as fases, então
	rebalancear uma fase inteira é mexer em três números.

	`exigeDano` é lido contra a vida-base da zona: exigeDano = 6 significa
	"cada golpe seu precisa tirar 6x a vida do monstro mais fraco daqui".
	Abaixo disso o golpe ainda entra, mas arranhando.

	CORPOS: cada receita é uma LISTA DE PARTES, não código. O Mundo.lua sabe
	instanciar `bloco` e `esfera` em qualquer combinação, então inventar uma
	silhueta nova é acrescentar uma entrada aqui.

	  tamanho/offset  em unidades de corpo; a escala final multiplica tudo
	  cor             "principal" | "escura" | "olho" (a espécie define a paleta)
	  material        "corpo" | "neon"
]]

local Monstros = {}

--- Quanto do golpe passa quando você não alcança o dano exigido.
Monstros.PENALIDADE_DANO_BAIXO = 0.12

Monstros.tiers = {
	{ id = "fraco", vida = 1, recompensa = 1, exigeDano = 0, ataque = 0, escala = 0.85 },
	{ id = "comum", vida = 7, recompensa = 6, exigeDano = 0.15, ataque = 0, escala = 1.0 },
	{ id = "bruto", vida = 45, recompensa = 34, exigeDano = 0.9, ataque = 6, escala = 1.2 },
	{ id = "temido", vida = 300, recompensa = 190, exigeDano = 6, ataque = 22, escala = 1.5 },
}

--- Onde cada tier fica na plataforma, relativo ao centro dela.
Monstros.posicoes = {
	Vector3.new(-19, 0, -13),
	Vector3.new(-7, 0, -19),
	Vector3.new(7, 0, -19),
	Vector3.new(19, 0, -13),
}

local function parte(nome, forma, tamanho, offset, cor, material, transparencia)
	return {
		nome = nome,
		forma = forma,
		tamanho = tamanho,
		offset = offset,
		cor = cor,
		material = material or "corpo",
		transparencia = transparencia or 0,
	}
end

local BLOCO, ESFERA = "bloco", "esfera"
local V = Vector3.new

Monstros.corpos = {
	bipede = {
		altura = 5.6,
		partes = {
			parte("PernaE", BLOCO, V(0.7, 1.8, 0.7), V(-0.5, 0.9, 0), "escura"),
			parte("PernaD", BLOCO, V(0.7, 1.8, 0.7), V(0.5, 0.9, 0), "escura"),
			parte("Tronco", BLOCO, V(1.9, 2.1, 1.1), V(0, 2.85, 0), "principal"),
			parte("BracoE", BLOCO, V(0.55, 1.8, 0.55), V(-1.3, 2.9, 0), "escura"),
			parte("BracoD", BLOCO, V(0.55, 1.8, 0.55), V(1.3, 2.9, 0), "escura"),
			parte("Cabeca", BLOCO, V(1.4, 1.3, 1.2), V(0, 4.5, 0), "principal"),
			parte("OlhoE", ESFERA, V(0.26, 0.26, 0.26), V(-0.33, 4.6, -0.62), "olho", "neon"),
			parte("OlhoD", ESFERA, V(0.26, 0.26, 0.26), V(0.33, 4.6, -0.62), "olho", "neon"),
			parte("ChifreE", BLOCO, V(0.22, 0.75, 0.22), V(-0.45, 5.4, 0), "escura"),
			parte("ChifreD", BLOCO, V(0.22, 0.75, 0.22), V(0.45, 5.4, 0), "escura"),
		},
	},

	quadrupede = {
		altura = 3.2,
		partes = {
			parte("PataDE", BLOCO, V(0.5, 1.1, 0.5), V(-0.6, 0.55, -1.0), "escura"),
			parte("PataDD", BLOCO, V(0.5, 1.1, 0.5), V(0.6, 0.55, -1.0), "escura"),
			parte("PataTE", BLOCO, V(0.5, 1.1, 0.5), V(-0.6, 0.55, 1.0), "escura"),
			parte("PataTD", BLOCO, V(0.5, 1.1, 0.5), V(0.6, 0.55, 1.0), "escura"),
			parte("Corpo", BLOCO, V(1.7, 1.3, 3.1), V(0, 1.75, 0), "principal"),
			parte("Cabeca", BLOCO, V(1.2, 1.1, 1.3), V(0, 2.1, -2.0), "principal"),
			parte("Focinho", BLOCO, V(0.7, 0.5, 0.6), V(0, 1.9, -2.7), "escura"),
			parte("OrelhaE", BLOCO, V(0.26, 0.55, 0.16), V(-0.38, 2.8, -1.8), "escura"),
			parte("OrelhaD", BLOCO, V(0.26, 0.55, 0.16), V(0.38, 2.8, -1.8), "escura"),
			parte("OlhoE", ESFERA, V(0.24, 0.24, 0.24), V(-0.3, 2.3, -2.55), "olho", "neon"),
			parte("OlhoD", ESFERA, V(0.24, 0.24, 0.24), V(0.3, 2.3, -2.55), "olho", "neon"),
			parte("Cauda", BLOCO, V(0.36, 0.36, 1.5), V(0, 2.0, 2.0), "escura"),
		},
	},

	rastejante = {
		altura = 2.0,
		partes = {
			parte("Cabeca", ESFERA, V(1.7, 1.7, 1.7), V(0, 0.9, -1.7), "principal"),
			parte("Segmento1", ESFERA, V(1.5, 1.5, 1.5), V(0, 0.8, -0.3), "principal"),
			parte("Segmento2", ESFERA, V(1.25, 1.25, 1.25), V(0, 0.7, 0.9), "escura"),
			parte("Segmento3", ESFERA, V(0.95, 0.95, 0.95), V(0, 0.6, 1.9), "escura"),
			parte("Segmento4", ESFERA, V(0.6, 0.6, 0.6), V(0, 0.5, 2.6), "escura"),
			parte("OlhoE", ESFERA, V(0.3, 0.3, 0.3), V(-0.4, 1.2, -2.4), "olho", "neon"),
			parte("OlhoD", ESFERA, V(0.3, 0.3, 0.3), V(0.4, 1.2, -2.4), "olho", "neon"),
			parte("PresaE", BLOCO, V(0.18, 0.45, 0.18), V(-0.35, 0.35, -2.3), "olho", "neon"),
			parte("PresaD", BLOCO, V(0.18, 0.45, 0.18), V(0.35, 0.35, -2.3), "olho", "neon"),
		},
	},

	flutuante = {
		altura = 4.4,
		partes = {
			parte("Manto", ESFERA, V(2.4, 2.4, 2.4), V(0, 2.6, 0), "principal", "corpo", 0.45),
			parte("Nucleo", ESFERA, V(1.3, 1.3, 1.3), V(0, 2.6, 0), "olho", "neon"),
			parte("Orbe1", ESFERA, V(0.5, 0.5, 0.5), V(-1.5, 3.4, 0), "olho", "neon"),
			parte("Orbe2", ESFERA, V(0.5, 0.5, 0.5), V(1.5, 3.4, 0), "olho", "neon"),
			parte("Orbe3", ESFERA, V(0.42, 0.42, 0.42), V(0, 1.4, -1.4), "olho", "neon"),
			parte("Cauda", ESFERA, V(0.9, 0.9, 0.9), V(0, 1.2, 0.9), "principal", "corpo", 0.6),
		},
	},
}

function Monstros.vidaDe(zona, indiceTier: number): number
	return math.floor(zona.monstro.vida * Monstros.tiers[indiceTier].vida)
end

function Monstros.danoExigido(zona, indiceTier: number): number
	return zona.monstro.vida * Monstros.tiers[indiceTier].exigeDano
end

function Monstros.recompensaDe(zona, indiceTier: number): (number, number)
	local fator = Monstros.tiers[indiceTier].recompensa
	return zona.monstro.forca * fator, zona.monstro.moedas * fator
end

return Monstros
