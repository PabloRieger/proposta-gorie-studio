--[[
	Equipamento comprável: espadas e armaduras.

	ESPADA responde "quanto eu tiro por golpe" — `dano` é multiplicador sobre
	Geral.DANO_BASE. ARMADURA responde "quanto tempo eu fico de pé" — `reducao`
	corta o contra-ataque dos monstros. São perguntas diferentes de propósito:
	se as duas fizessem a mesma coisa, o jogador compraria só a mais eficiente e
	a loja deixaria de ser uma escolha.

	O que reseta ao evoluir: TUDO daqui. É isso que faz a loja continuar
	importando em todas as vidas, em vez de virar compra única. Melhorias por
	nível e o que vier de baú permanecem.

	`raridade` limita a origem: comum/incomum/raro se compram aqui; épico e
	lendário só caem de chefe. Por isso `preco = nil` neles.

	VISUAL: mesma regra dos monstros — se `modelo` apontar para algo em
	ReplicatedStorage/Modelos, ele é usado; senão a peça é montada pela receita.
	Trocar arte nunca exige mexer em código.
]]

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local Armas = {}

--[[
	`dano` cresce x2.6 por fase, acompanhando a vida dos monstros. `preco`
	cresce mais rápido que a renda de propósito: cada espada nova custa mais
	tempo que a anterior.
]]
Armas.espadas = {
	{
		id = "esp_punhos",
		nome = "Punhos",
		dano = 1,
		inicial = true,
		raridade = "inicial",
		lamina = { comprimento = 0, largura = 0, cor = rgb(0, 0, 0), brilho = false },
	},
	{
		id = "esp_madeira",
		nome = "Espada de Madeira",
		dano = 3,
		preco = 250,
		zona = "vilarejo",
		raridade = "comum",
		lamina = { comprimento = 3.2, largura = 0.34, cor = rgb(176, 138, 92), brilho = false },
	},
	{
		id = "esp_bronze",
		nome = "Lâmina de Bronze",
		dano = 8,
		preco = 900,
		zona = "dojo",
		raridade = "comum",
		lamina = { comprimento = 3.6, largura = 0.38, cor = rgb(198, 148, 86), brilho = false },
	},
	{
		id = "esp_cristal",
		nome = "Sabre de Cristal",
		dano = 21,
		preco = 3.2e3,
		zona = "gelo",
		raridade = "incomum",
		lamina = { comprimento = 3.9, largura = 0.4, cor = rgb(150, 214, 248), brilho = true },
	},
	{
		id = "esp_obsidiana",
		nome = "Gume de Obsidiana",
		dano = 55,
		preco = 12e3,
		zona = "vulcao",
		raridade = "incomum",
		lamina = { comprimento = 4.1, largura = 0.44, cor = rgb(72, 62, 76), brilho = false },
	},
	{
		id = "esp_runica",
		nome = "Espada Rúnica",
		dano = 145,
		preco = 45e3,
		zona = "ruinas",
		raridade = "incomum",
		lamina = { comprimento = 4.3, largura = 0.42, cor = rgb(206, 190, 132), brilho = true },
	},
	{
		id = "esp_areia",
		nome = "Cimitarra de Areia",
		dano = 380,
		preco = 170e3,
		zona = "deserto",
		raridade = "raro",
		lamina = { comprimento = 4.4, largura = 0.46, cor = rgb(232, 196, 118), brilho = true },
	},
	{
		id = "esp_sombria",
		nome = "Lâmina Sombria",
		dano = 1e3,
		preco = 620e3,
		zona = "templo",
		raridade = "raro",
		lamina = { comprimento = 4.6, largura = 0.44, cor = rgb(142, 108, 208), brilho = true },
	},
	{
		id = "esp_estelar",
		nome = "Espada Estelar",
		dano = 2.6e3,
		preco = 2.3e6,
		zona = "fenda",
		raridade = "raro",
		lamina = { comprimento = 4.8, largura = 0.48, cor = rgb(130, 158, 252), brilho = true },
	},
	{
		id = "esp_vazio",
		nome = "Fenda em Lâmina",
		dano = 6.8e3,
		preco = 8.5e6,
		zona = "vazio",
		raridade = "raro",
		lamina = { comprimento = 5.0, largura = 0.5, cor = rgb(40, 40, 56), brilho = true },
	},
	{
		id = "esp_primordial",
		nome = "Corte Primordial",
		dano = 18e3,
		preco = 32e6,
		zona = "eter",
		raridade = "raro",
		lamina = { comprimento = 5.2, largura = 0.52, cor = rgb(252, 248, 226), brilho = true },
	},
}

--[[
	`reducao` é a fatia do contra-ataque que a armadura come. O teto fica em
	0.8: monstro que nunca machuca tira o sentido de existir tier que revida.
]]
Armas.armaduras = {
	{
		id = "arm_roupa",
		nome = "Roupa de Pano",
		reducao = 0,
		inicial = true,
		raridade = "inicial",
		placa = { cor = rgb(150, 140, 130), brilho = false },
	},
	{
		id = "arm_couro",
		nome = "Colete de Couro",
		reducao = 0.15,
		preco = 400,
		zona = "vilarejo",
		raridade = "comum",
		placa = { cor = rgb(140, 96, 62), brilho = false },
	},
	{
		id = "arm_ferro",
		nome = "Peitoral de Ferro",
		reducao = 0.28,
		preco = 1.4e3,
		zona = "dojo",
		raridade = "comum",
		placa = { cor = rgb(158, 164, 176), brilho = false },
	},
	{
		id = "arm_gelo",
		nome = "Casco de Gelo",
		reducao = 0.4,
		preco = 5e3,
		zona = "gelo",
		raridade = "incomum",
		placa = { cor = rgb(158, 212, 244), brilho = true },
	},
	{
		id = "arm_magma",
		nome = "Couraça de Magma",
		reducao = 0.5,
		preco = 19e3,
		zona = "vulcao",
		raridade = "incomum",
		placa = { cor = rgb(206, 96, 62), brilho = true },
	},
	{
		id = "arm_runica",
		nome = "Égide Rúnica",
		reducao = 0.58,
		preco = 70e3,
		zona = "ruinas",
		raridade = "incomum",
		placa = { cor = rgb(202, 186, 130), brilho = true },
	},
	{
		id = "arm_faraonica",
		nome = "Placa Faraônica",
		reducao = 0.65,
		preco = 260e3,
		zona = "deserto",
		raridade = "raro",
		placa = { cor = rgb(228, 192, 96), brilho = true },
	},
	{
		id = "arm_selada",
		nome = "Armadura Selada",
		reducao = 0.71,
		preco = 950e3,
		zona = "templo",
		raridade = "raro",
		placa = { cor = rgb(120, 96, 176), brilho = true },
	},
	{
		id = "arm_sideral",
		nome = "Manto Sideral",
		reducao = 0.76,
		preco = 3.5e6,
		zona = "fenda",
		raridade = "raro",
		placa = { cor = rgb(120, 146, 246), brilho = true },
	},
	{
		id = "arm_vazio",
		nome = "Casca do Vazio",
		reducao = 0.8,
		preco = 13e6,
		zona = "vazio",
		raridade = "raro",
		placa = { cor = rgb(34, 34, 48), brilho = true },
	},
}

--[[
	Índices montados uma vez. `tipoPorId` existe para ninguém precisar adivinhar
	pela presença de um campo se o item é espada ou armadura — adivinhação que
	quebra em silêncio no dia em que uma armadura ganhar dano.
]]
Armas.porId = {}
Armas.tipoPorId = {}

for tipo, lista in { espada = Armas.espadas, armadura = Armas.armaduras } do
	for _, item in lista do
		-- Id vai parar no save do jogador: colisão aqui é bug permanente, e
		-- silencioso — um item sobrescreve o outro no índice e a compra entrega
		-- a peça errada. Melhor não subir o servidor.
		assert(
			Armas.porId[item.id] == nil,
			("Armas: id repetido '%s' (%s)"):format(item.id, item.nome)
		)

		Armas.porId[item.id] = item
		Armas.tipoPorId[item.id] = tipo
	end
end

--- O que o jogador usa quando não tem nada equipado.
function Armas.inicial(lista): any
	for _, item in lista do
		if item.inicial then
			return item
		end
	end
	return lista[1]
end

return Armas
