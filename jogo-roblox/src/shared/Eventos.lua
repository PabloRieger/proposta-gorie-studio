--[[
	Barramento de sinais, servidor e cliente.

	Existe para uma coisa só: deixar um sistema NOVO reagir a algo que já
	acontece, sem editar quem emite. Quando o baú precisar reagir ao chefe
	derrotado, ele escuta aqui — o serviço do chefe não fica sabendo que o
	baú existe, e nenhuma linha dele muda.

		Eventos.sinal("ChefeDerrotado"):Connect(function(player, chefe) end)
		Eventos.emitir("ChefeDerrotado", player, chefe)

	Regra de uso: sinal é para AVISO entre sistemas. Quando um sistema precisa
	de uma RESPOSTA (o saldo, o dano, o perfil), chame o serviço direto — não
	transforme pergunta em evento, que é o caminho mais rápido para código
	impossível de seguir.
]]

local Eventos = {}

local sinais: { [string]: BindableEvent } = {}

local function bindable(nome: string): BindableEvent
	local sinal = sinais[nome]

	if not sinal then
		sinal = Instance.new("BindableEvent")
		sinal.Name = nome
		sinais[nome] = sinal
	end

	return sinal
end

function Eventos.sinal(nome: string): RBXScriptSignal
	return bindable(nome).Event
end

function Eventos.emitir(nome: string, ...: any)
	bindable(nome):Fire(...)
end

return Eventos
