--[[
	A SENSAÇÃO do golpe. Tudo que faz bater ser gostoso mora aqui.

	MEXER AQUI para: ritmo do braço, hit stop, tremor de câmera, crítico e sons.
	Nenhum destes números afeta balanceamento — são só o que se vê e se ouve.
	Mexa à vontade e teste; é o arquivo mais seguro do projeto.

	SOBRE OS SONS: são caminhos `rbxasset://`, que vêm junto com o Studio — não
	dependem de upload nem de internet. Se algum não tocar na sua versão, troque
	a linha por um id da biblioteca (`rbxassetid://NUMERO`). Som que falha não
	quebra nada: simplesmente não sai.
]]

return {
	-- ---------------------------------------------------------------- braço
	-- O golpe inteiro precisa caber no COOLDOWN_GOLPE (0.35s), senão um
	-- movimento atropela o outro e o braço fica tremendo no lugar.
	PREPARO = 0.09, -- levanta
	ATAQUE = 0.06, -- desce
	RETORNO = 0.14, -- volta

	-- Ângulos do ombro, em graus. Se o braço girar para o lado errado no seu
	-- rig, inverta o sinal dos dois.
	ANGULO_PREPARO = -55,
	ANGULO_ATAQUE = 75,

	--[[
		HIT STOP: a pausa no instante do impacto. É o truque mais subestimado
		de jogo de ação — 60 milésimos parados são o que separa "o número mudou"
		de "eu acertei". Acima de ~120ms começa a parecer travamento.
	]]
	HIT_STOP = 0.06,
	HIT_STOP_CRITICO = 0.11,

	-- --------------------------------------------------------------- câmera
	TREMOR_DURACAO = 0.13,
	TREMOR_NORMAL = 0.22,
	TREMOR_CRITICO = 0.7,
	TREMOR_MORTE = 0.45,

	-- -------------------------------------------------------------- crítico
	-- Repetição precisa de variância: sem crítico, dez mil golpes são o mesmo
	-- golpe dez mil vezes.
	CHANCE_CRITICO = 0.12,
	MULTIPLICADOR_CRITICO = 3,

	-- --------------------------------------------------------------- morte
	MORTE_ESPALHA = 0.45, -- quanto tempo as peças voam
	MORTE_FORCA = 14, -- quão longe

	-- --------------------------------------------------------------- sons
	SONS = {
		golpe = { id = "rbxasset://sounds/swordslash.wav", volume = 0.35, tom = 1 },
		impacto = { id = "rbxasset://sounds/snap.wav", volume = 0.55, tom = 0.9 },
		critico = { id = "rbxasset://sounds/swordlunge.wav", volume = 0.7, tom = 1 },
		arranhao = { id = "rbxasset://sounds/clickfast.wav", volume = 0.3, tom = 0.7 },
		morte = { id = "rbxasset://sounds/impact_explosion_03.mp3", volume = 0.45, tom = 1.35 },
		compra = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.5, tom = 1 },
	},

	-- Variação aleatória de tom por golpe. Sem isto, o mesmo som repetido
	-- centenas de vezes vira ruído irritante em poucos minutos.
	VARIACAO_TOM = 0.12,

	-- Alcance em que o som de impacto ainda se ouve.
	ALCANCE_SOM = 70,
}
