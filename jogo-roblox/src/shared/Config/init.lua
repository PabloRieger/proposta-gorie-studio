--[[
	ÍNDICE da configuração. Este arquivo não guarda valor nenhum: ele só diz
	onde cada coisa mora, para que mudar balanceamento seja abrir UM arquivo
	pequeno em vez de caçar número no meio de lógica.

	    Geral      constantes globais (dano base, cooldowns, autosave)
	    Ranks      títulos e multiplicadores por Força, dentro de uma vida
	    Zonas      as fases: porteira de Força, base dos bonecos, geometria
	    Bonecos    os quatro tiers de boneco e como escalam sobre a zona
	    Melhorias  o que a loja vende hoje (vira itens no passo 2)
	    Evolucoes  a escada de rebirth
]]

return {
	Geral = require(script.Geral),
	Ranks = require(script.Ranks),
	Zonas = require(script.Zonas),
	Bonecos = require(script.Bonecos),
	Melhorias = require(script.Melhorias),
	Evolucoes = require(script.Evolucoes),
}
