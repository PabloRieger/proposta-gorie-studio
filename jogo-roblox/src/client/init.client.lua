--[[
	Ponto de entrada do cliente: monta a interface e liga os pedidos ao servidor.
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Remotes = Compartilhado.Remotes

local Ui = require(script.Ui)
local HUD = require(script.HUD)
local Loja = require(script.Loja)
local Barreiras = require(script.Barreiras)
local Entrada = require(script.Entrada)
local Notificacoes = require(script.Notificacoes)

local player = Players.LocalPlayer
local remoteEvoluir = Remotes.obter("PedirEvolucao")

local gui = Ui.novo("ScreenGui", {
	Name = "InterfaceEvolucao",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

HUD.criar(gui)
Loja.criar(gui)
Notificacoes.criar(gui)

HUD.definirAcoes({
	abrirLoja = function()
		Loja.alternar()
	end,
	evoluir = function()
		remoteEvoluir:FireServer()
	end,
})

Entrada.iniciar(HUD.botaoTreinar())
Barreiras.iniciar()

Remotes.obter("EstadoAtualizado").OnClientEvent:Connect(Loja.aplicarEstado)
Remotes.obter("Notificar").OnClientEvent:Connect(Notificacoes.mostrar)

-- Pedestais do hub: o prompt é tratado no cliente para abrir a interface na hora.
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local nome = prompt.Parent and prompt.Parent.Name

	if nome == "Loja" then
		Loja.alternar(true)
	elseif nome == "Altar de Evolução" then
		remoteEvoluir:FireServer()
	end
end)
