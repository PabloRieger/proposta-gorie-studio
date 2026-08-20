--[[
	CARREGADOR DO SERVIDOR.

	Este arquivo não conhece nenhum serviço pelo nome, e é assim de propósito:
	adicionar um sistema novo é criar UM arquivo em servicos/ — nada aqui muda.

	Contrato de um serviço (tudo opcional menos o retorno):

		local Servico = { ordem = 40 }

		function Servico.iniciar(servicos)   -- uma vez, na subida
		function Servico.aoEntrar(player)    -- jogador entrou; false aborta
		function Servico.aoSair(player)      -- jogador saiu

		return Servico

	`ordem` decide quem sobe primeiro (menor primeiro) e em que sequência os
	jogadores são processados. Dependência não se resolve com require: ela
	chega pronta em `iniciar(servicos)`, o que evita ciclo e deixa o que cada
	serviço usa visível nas primeiras linhas dele.

	Faixas em uso: 10 dados · 20 progresso · 30 mundo · 40 combate
	                50 personagem · 60 loja · 70 evolução
]]

local Players = game:GetService("Players")

local servicos = {}
local emOrdem = {}

for _, modulo in script.servicos:GetChildren() do
	if modulo:IsA("ModuleScript") then
		local servico = require(modulo)
		servico.nome = modulo.Name
		servicos[modulo.Name] = servico
		table.insert(emOrdem, servico)
	end
end

table.sort(emOrdem, function(a, b)
	return (a.ordem or 100) < (b.ordem or 100)
end)

for _, servico in emOrdem do
	if servico.iniciar then
		servico.iniciar(servicos)
	end
end

--[[
	Ciclo de vida do jogador, na mesma ordem da subida.

	Um serviço que devolve `false` em aoEntrar interrompe a sequência — quem
	interrompe é responsável por avisar o jogador. É como Dados recusa a
	entrada quando não conseguiu ler o perfil.
]]
local function aoEntrar(player: Player)
	for _, servico in emOrdem do
		if servico.aoEntrar and servico.aoEntrar(player) == false then
			return
		end
	end
end

local function aoSair(player: Player)
	for _, servico in emOrdem do
		if servico.aoSair then
			servico.aoSair(player)
		end
	end
end

Players.PlayerAdded:Connect(aoEntrar)
Players.PlayerRemoving:Connect(aoSair)

-- Cobre quem já estava no servidor quando o script subiu (comum no Studio).
for _, player in Players:GetPlayers() do
	task.spawn(aoEntrar, player)
end

print(("[Evolução Lendária] %d serviços no ar."):format(#emOrdem))
