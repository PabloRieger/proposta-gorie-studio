--[[
	ÍNDICE do módulo compartilhado (ReplicatedStorage.Compartilhado).

		local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
		local Config = Compartilhado.Config
]]

return {
	Config = require(script.Config),
	Formato = require(script.Formato),
	Remotes = require(script.Remotes),
	Eventos = require(script.Eventos),
}
