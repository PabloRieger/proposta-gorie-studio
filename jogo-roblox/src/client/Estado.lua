--[[
	Leitura do estado do jogador na tela.

	O servidor publica tudo em atributos do Player; o cliente nunca guarda
	cópia. Este módulo existe só para que cada painel não repita o mesmo
	`GetAttribute` com valor padrão e o mesmo laço de conexões.

	Um painel novo que reage a números vira três linhas:

		Estado.observar({ "Forca", "Dano" }, atualizar)
]]

local Players = game:GetService("Players")

local Estado = {}

local player = Players.LocalPlayer

function Estado.ler(nome: string, padrao: any): any
	local valor = player:GetAttribute(nome)
	return if valor == nil then padrao else valor
end

--- Chama `callback` agora e a cada mudança de qualquer atributo da lista.
function Estado.observar(nomes: { string }, callback: () -> ())
	for _, nome in nomes do
		player:GetAttributeChangedSignal(nome):Connect(callback)
	end
	callback()
end

return Estado
