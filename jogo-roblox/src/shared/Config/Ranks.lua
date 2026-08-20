--[[
	Ranks são o progresso DENTRO de uma vida: dependem só da Força atual e
	zeram junto com ela a cada evolução. Dão título, multiplicador e tamanho
	do personagem.

	Espaçados em progressão geométrica (x8.4 de Força por degrau, x1.12 de
	multiplicador) para que subir de rank aconteça em ritmo constante durante
	toda a vida, e não tudo de uma vez no começo.
]]

return {
	{ nome = "Iniciante", forca = 0, multiplicador = 1.00, cor = Color3.fromRGB(176, 184, 198) },
	{ nome = "Aprendiz", forca = 1e3, multiplicador = 1.12, cor = Color3.fromRGB(126, 217, 160) },
	{ nome = "Lutador", forca = 8.4e3, multiplicador = 1.25, cor = Color3.fromRGB(96, 200, 214) },
	{ nome = "Guerreiro", forca = 71e3, multiplicador = 1.40, cor = Color3.fromRGB(88, 166, 240) },
	{ nome = "Veterano", forca = 590e3, multiplicador = 1.57, cor = Color3.fromRGB(126, 138, 246) },
	{ nome = "Elite", forca = 5e6, multiplicador = 1.75, cor = Color3.fromRGB(168, 124, 246) },
	{ nome = "Mestre", forca = 42e6, multiplicador = 1.96, cor = Color3.fromRGB(212, 116, 232) },
	{ nome = "Grão-Mestre", forca = 350e6, multiplicador = 2.19, cor = Color3.fromRGB(240, 112, 184) },
	{ nome = "Campeão", forca = 3e9, multiplicador = 2.45, cor = Color3.fromRGB(248, 122, 122) },
	{ nome = "Herói", forca = 25e9, multiplicador = 2.75, cor = Color3.fromRGB(250, 158, 96) },
	{ nome = "Titã", forca = 210e9, multiplicador = 3.07, cor = Color3.fromRGB(252, 200, 84) },
	{ nome = "Semideus", forca = 1.7e12, multiplicador = 3.44, cor = Color3.fromRGB(238, 236, 128) },
	{ nome = "Lenda", forca = 15e12, multiplicador = 3.84, cor = Color3.fromRGB(190, 250, 190) },
	{ nome = "Mito", forca = 120e12, multiplicador = 4.30, cor = Color3.fromRGB(255, 255, 255) },
}
