--[[
	Fachada do módulo compartilhado.

	Uso:
		local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
		local Config = Compartilhado.Config
]]

return {
	Config = require(script.Config),
	Formato = require(script.Formato),
	Remotes = require(script.Remotes),
}
