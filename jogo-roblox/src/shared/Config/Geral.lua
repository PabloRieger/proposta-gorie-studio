--[[
	Constantes globais do jogo.

	MEXER AQUI para: ritmo de golpe, alcance, dano base, velocidade do
	personagem, autosave. Nada de lógica — só números que o jogo lê.
]]

return {
	-- Combate. Nada rende parado: Força só vem de golpe em boneco.
	DANO_BASE = 5,
	COOLDOWN_GOLPE = 0.35,
	ALCANCE_GOLPE = 15,

	-- O golpe automático bate mais devagar que a mão, de propósito: ele
	-- mantém quem joga de segunda tela avançando sem tornar a presença
	-- irrelevante. Não vale para chefe nem para parkour.
	FATOR_AUTO = 0.6,

	-- Quanto tempo um boneco quebrado fica de pé de novo (por jogador).
	RENASCE_BONECO = 1.2,

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
}
