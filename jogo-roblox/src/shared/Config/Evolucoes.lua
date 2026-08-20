--[[
	Evoluções (o "rebirth" do gênero): zeram a Força em troca de um
	multiplicador permanente, um título novo e uma aura diferente.

	O índice 1 é o estado inicial de quem nunca evoluiu — ou seja,
	`Evolucoes[perfil.evolucao + 1]` é sempre a evolução atual e
	`Evolucoes[perfil.evolucao + 2]` é a próxima (nil quando no topo).

	`forcaNecessaria` é lida da PRÓXIMA evolução; por isso a primeira
	entrada não precisa dela.

	Curva: requisito x8 por degrau contra multiplicador x2.2. A sobra de x3.6
	é o que faz cada evolução demorar mais que a anterior, em vez de o jogo
	acelerar até o fim sozinho.
]]

return {
	{
		nome = "Mortal",
		forcaNecessaria = 0,
		multiplicador = 1,
		cor = Color3.fromRGB(190, 196, 210),
	},
	{
		nome = "Desperto",
		forcaNecessaria = 250e3,
		multiplicador = 2.2,
		cor = Color3.fromRGB(120, 226, 176),
	},
	{
		nome = "Ascendente",
		forcaNecessaria = 2e6,
		multiplicador = 4.84,
		cor = Color3.fromRGB(96, 204, 236),
	},
	{
		nome = "Radiante",
		forcaNecessaria = 16e6,
		multiplicador = 10.6,
		cor = Color3.fromRGB(110, 160, 250),
	},
	{
		nome = "Celestial",
		forcaNecessaria = 130e6,
		multiplicador = 23.4,
		cor = Color3.fromRGB(164, 128, 250),
	},
	{
		nome = "Divino",
		forcaNecessaria = 1e9,
		multiplicador = 51.5,
		cor = Color3.fromRGB(224, 118, 226),
	},
	{
		nome = "Primordial",
		forcaNecessaria = 8.2e9,
		multiplicador = 113,
		cor = Color3.fromRGB(250, 118, 150),
	},
	{
		nome = "Cósmico",
		forcaNecessaria = 66e9,
		multiplicador = 249,
		cor = Color3.fromRGB(252, 156, 92),
	},
	{
		nome = "Eterno",
		forcaNecessaria = 520e9,
		multiplicador = 549,
		cor = Color3.fromRGB(254, 208, 80),
	},
	{
		nome = "Absoluto",
		forcaNecessaria = 4.2e12,
		multiplicador = 1210,
		cor = Color3.fromRGB(214, 252, 138),
	},
	{
		nome = "Transcendente",
		forcaNecessaria = 34e12,
		multiplicador = 2660,
		cor = Color3.fromRGB(150, 255, 224),
	},
	{
		nome = "Lenda Suprema",
		forcaNecessaria = 270e12,
		multiplicador = 5840,
		cor = Color3.fromRGB(255, 255, 255),
	},
}
