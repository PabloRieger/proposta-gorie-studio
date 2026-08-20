--[[
	ÍNDICE da configuração. Este arquivo não guarda valor nenhum: ele só diz
	onde cada coisa mora, para que mudar balanceamento seja abrir UM arquivo
	pequeno em vez de caçar número no meio de lógica.

	    Geral      constantes globais (dano base, cooldowns, autosave)
	    Ranks      títulos e multiplicadores por Força, dentro de uma vida
	    Zonas      as fases: porteira de Força, base dos monstros, geometria
	    Monstros   os 4 tiers de dificuldade e as receitas de corpo
	    Bestiario  as 40 espécies: nome, silhueta e paleta por fase
	    Melhorias  o que a loja vende hoje (vira itens no passo 2)
	    Evolucoes  a escada de rebirth
]]

return {
	Geral = require(script.Geral),
	Ranks = require(script.Ranks),
	Zonas = require(script.Zonas),
	Monstros = require(script.Monstros),
	Bestiario = require(script.Bestiario),
	Melhorias = require(script.Melhorias),
	Evolucoes = require(script.Evolucoes),
}
