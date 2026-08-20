--[[
	Tudo que dá para balancear sem tocar em lógica mora aqui.
]]

return {
	Geral = {
		-- Ritmo do ganho passivo enquanto o jogador está parado na zona.
		INTERVALO_TICK = 0.35,

		-- Um clique de treino vale este tanto de ticks.
		MULTIPLICADOR_CLIQUE = 1.5,
		COOLDOWN_CLIQUE = 0.2,

		-- Persistência.
		INTERVALO_AUTOSAVE = 90,

		-- Personagem.
		VELOCIDADE_BASE = 16,
		SALTO_BASE = 50,
		ESCALA_MINIMA = 1.0,
		ESCALA_MAXIMA = 1.9,
		ESCALA_CABECA_MAXIMA = 1.35,

		-- Anti-spam de compras (segundos entre pedidos aceitos).
		COOLDOWN_COMPRA = 0.2,
	},

	Ranks = require(script.Ranks),
	Zonas = require(script.Zonas),
	Melhorias = require(script.Melhorias),
	Evolucoes = require(script.Evolucoes),
}
