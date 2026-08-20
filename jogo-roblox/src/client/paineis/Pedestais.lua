--[[
	Os pedestais do hub (Altar e Loja).

	Fica separado do HUD de propósito: são objetos do MUNDO, não da tela. Somar
	um pedestal novo — forja, ovos, missões — é somar um caso aqui e nada mais.

	O prompt é tratado no cliente para a interface abrir na hora, sem ida e
	volta ao servidor. Quem valida a evolução continua sendo o servidor.
]]

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Eventos = Compartilhado.Eventos
local Remotes = Compartilhado.Remotes

local Pedestais = { ordem = 70 }

--- Nome do modelo no mundo -> o que fazer quando o prompt dispara.
local ACOES: { [string]: () -> () } = {
	["Loja"] = function()
		Eventos.emitir("PedirLoja")
	end,
	["Altar de Evolução"] = function()
		Remotes.obter("PedirEvolucao"):FireServer()
	end,
}

function Pedestais.ligar()
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local pai = prompt.Parent
		local acao = pai and ACOES[pai.Name]

		if acao then
			acao()
		end
	end)
end

return Pedestais
