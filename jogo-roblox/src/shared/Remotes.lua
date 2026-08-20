--[[
	Ponto único de criação/consulta dos RemoteEvents.

	Regra do projeto: o cliente só PEDE coisas ("treinei", "quero comprar").
	Quem decide, calcula e grava é sempre o servidor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NOMES = {
	-- cliente -> servidor
	"Bater",
	"AlternarAuto",
	"ComprarMelhoria",
	"PedirEvolucao",
	-- servidor -> cliente
	"GolpeResolvido",
	"EstadoAtualizado",
	"Notificar",
}

local ESPERA_MAXIMA = 30

local Remotes = {}

local function prepararNoServidor(): Folder
	local pasta = ReplicatedStorage:FindFirstChild("Remotes")

	if not pasta then
		pasta = Instance.new("Folder")
		pasta.Name = "Remotes"
		pasta.Parent = ReplicatedStorage
	end

	for _, nome in NOMES do
		if not pasta:FindFirstChild(nome) then
			local evento = Instance.new("RemoteEvent")
			evento.Name = nome
			evento.Parent = pasta
		end
	end

	return pasta
end

local pasta: Instance? = if RunService:IsServer()
	then prepararNoServidor()
	else ReplicatedStorage:WaitForChild("Remotes", ESPERA_MAXIMA)

function Remotes.obter(nome: string): RemoteEvent
	assert(pasta, "Pasta Remotes não apareceu em ReplicatedStorage")
	local evento = pasta:WaitForChild(nome, ESPERA_MAXIMA)
	assert(evento, "RemoteEvent inexistente: " .. nome)
	return evento :: RemoteEvent
end

return Remotes
