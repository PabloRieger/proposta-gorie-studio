--[[
	As 40 espécies do jogo: quatro por fase, na ordem dos tiers de Monstros.lua
	(fraco, comum, bruto, temido). A dificuldade vem do tier; daqui vem só a
	IDENTIDADE — nome, silhueta e paleta.

	COMO TROCAR UM MONSTRO PROCEDURAL POR UM MODELO DE VERDADE:

	  1. No Studio, ponha o modelo em ReplicatedStorage/Modelos.
	  2. Preencha `modelo = "NomeExatoDoModelo"` na espécie aqui.

	É só isso — nenhuma linha de código muda. Enquanto `modelo` for nil, o
	Mundo monta o corpo procedural pela receita em `corpo`. Ou seja: dá para
	trocar uma espécie por vez, sem nunca parar o desenvolvimento esperando arte.

	⚠️ Modelo grátis do Toolbox é o principal vetor de backdoor no Roblox.
	Apague todo Script e LocalScript de dentro antes de usar: quem comanda o
	monstro é o nosso código, o modelo é só a casca.
]]

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

return {
	vilarejo = {
		{ nome = "Rato do Celeiro", corpo = "quadrupede", cor = rgb(126, 110, 96), olho = rgb(248, 200, 120), escala = 0.75 },
		{ nome = "Espantalho Vivo", corpo = "bipede", cor = rgb(190, 162, 96), olho = rgb(252, 128, 72), escala = 0.95 },
		{ nome = "Lobo Cinzento", corpo = "quadrupede", cor = rgb(128, 132, 140), olho = rgb(250, 232, 120), escala = 1.05 },
		{ nome = "Ogro do Moinho", corpo = "bipede", cor = rgb(126, 156, 108), olho = rgb(252, 96, 88), escala = 1.25 },
	},

	dojo = {
		{ nome = "Macaco de Pedra", corpo = "bipede", cor = rgb(140, 134, 122), olho = rgb(180, 240, 200), escala = 0.8 },
		{ nome = "Serpente da Trilha", corpo = "rastejante", cor = rgb(96, 150, 108), olho = rgb(250, 214, 96), escala = 1.0 },
		{ nome = "Javali Selvagem", corpo = "quadrupede", cor = rgb(102, 84, 70), olho = rgb(252, 148, 96), escala = 1.1 },
		{ nome = "Guardião de Bambu", corpo = "bipede", cor = rgb(122, 168, 98), olho = rgb(226, 250, 160), escala = 1.3 },
	},

	gelo = {
		{ nome = "Morcego de Gelo", corpo = "flutuante", cor = rgb(170, 214, 244), olho = rgb(180, 244, 252), escala = 0.8 },
		{ nome = "Aranha de Cristal", corpo = "quadrupede", cor = rgb(150, 202, 236), olho = rgb(120, 236, 250), escala = 0.95 },
		{ nome = "Urso Nevado", corpo = "quadrupede", cor = rgb(226, 236, 248), olho = rgb(96, 178, 238), escala = 1.25 },
		{ nome = "Golem de Gelo", corpo = "bipede", cor = rgb(126, 190, 232), olho = rgb(200, 250, 255), escala = 1.35 },
	},

	vulcao = {
		{ nome = "Larva de Magma", corpo = "rastejante", cor = rgb(198, 84, 52), olho = rgb(255, 208, 96), escala = 0.85 },
		{ nome = "Salamandra de Lava", corpo = "quadrupede", cor = rgb(224, 106, 58), olho = rgb(255, 236, 140), escala = 1.0 },
		{ nome = "Imp Flamejante", corpo = "bipede", cor = rgb(206, 70, 54), olho = rgb(255, 178, 72), escala = 1.05 },
		{ nome = "Colosso de Obsidiana", corpo = "bipede", cor = rgb(62, 56, 62), olho = rgb(255, 118, 48), escala = 1.45 },
	},

	ruinas = {
		{ nome = "Fragmento Errante", corpo = "flutuante", cor = rgb(198, 186, 148), olho = rgb(248, 240, 176), escala = 0.85 },
		{ nome = "Serpente de Vento", corpo = "rastejante", cor = rgb(176, 190, 196), olho = rgb(226, 250, 252), escala = 1.05 },
		{ nome = "Gárgula Quebrada", corpo = "bipede", cor = rgb(146, 142, 130), olho = rgb(250, 210, 130), escala = 1.15 },
		{ nome = "Sentinela Caída", corpo = "bipede", cor = rgb(184, 168, 118), olho = rgb(255, 246, 196), escala = 1.4 },
	},

	deserto = {
		{ nome = "Escorpião de Areia", corpo = "quadrupede", cor = rgb(214, 178, 108), olho = rgb(252, 240, 150), escala = 0.85 },
		{ nome = "Verme das Dunas", corpo = "rastejante", cor = rgb(198, 160, 100), olho = rgb(250, 132, 96), escala = 1.15 },
		{ nome = "Múmia Ressecada", corpo = "bipede", cor = rgb(226, 206, 168), olho = rgb(160, 250, 190), escala = 1.1 },
		{ nome = "Faraó Esquecido", corpo = "bipede", cor = rgb(230, 190, 92), olho = rgb(120, 240, 236), escala = 1.4 },
	},

	templo = {
		{ nome = "Sombra Rastejante", corpo = "rastejante", cor = rgb(58, 50, 78), olho = rgb(196, 132, 250), escala = 0.9 },
		{ nome = "Monge Sem Rosto", corpo = "bipede", cor = rgb(96, 82, 126), olho = rgb(226, 200, 255), escala = 1.05 },
		{ nome = "Quimera do Templo", corpo = "quadrupede", cor = rgb(120, 92, 158), olho = rgb(252, 160, 240), escala = 1.2 },
		{ nome = "Guardião Selado", corpo = "bipede", cor = rgb(72, 60, 110), olho = rgb(178, 120, 252), escala = 1.45 },
	},

	fenda = {
		{ nome = "Fagulha Estelar", corpo = "flutuante", cor = rgb(132, 154, 244), olho = rgb(226, 236, 255), escala = 0.8 },
		{ nome = "Aracnídeo Sideral", corpo = "quadrupede", cor = rgb(90, 108, 200), olho = rgb(168, 224, 255), escala = 1.05 },
		{ nome = "Devorador de Luz", corpo = "flutuante", cor = rgb(52, 62, 128), olho = rgb(120, 180, 255), escala = 1.25 },
		{ nome = "Arauto da Fenda", corpo = "bipede", cor = rgb(108, 128, 236), olho = rgb(248, 252, 255), escala = 1.45 },
	},

	vazio = {
		{ nome = "Eco Silencioso", corpo = "flutuante", cor = rgb(48, 48, 64), olho = rgb(150, 150, 190), escala = 0.9 },
		{ nome = "Coisa Sem Nome", corpo = "rastejante", cor = rgb(38, 38, 50), olho = rgb(200, 60, 90), escala = 1.15 },
		{ nome = "Terror do Vazio", corpo = "bipede", cor = rgb(30, 30, 42), olho = rgb(230, 70, 100), escala = 1.35 },
		{ nome = "Boca do Núcleo", corpo = "flutuante", cor = rgb(20, 20, 30), olho = rgb(250, 90, 120), escala = 1.6 },
	},

	eter = {
		{ nome = "Faísca Primeva", corpo = "flutuante", cor = rgb(244, 240, 214), olho = rgb(255, 255, 255), escala = 0.9 },
		{ nome = "Forma Inacabada", corpo = "rastejante", cor = rgb(226, 220, 196), olho = rgb(255, 250, 220), escala = 1.2 },
		{ nome = "Primogênito", corpo = "bipede", cor = rgb(248, 244, 226), olho = rgb(255, 255, 255), escala = 1.4 },
		{ nome = "Aquilo Que Restou", corpo = "flutuante", cor = rgb(255, 255, 255), olho = rgb(255, 236, 180), escala = 1.7 },
	},
}
