--[[
	Treino ativo: clique, toque, tecla E ou o botão TREINAR.

	Segurar mantém o pedido em ritmo constante. O intervalo daqui é só de
	conforto — quem manda no limite real é o COOLDOWN_CLIQUE do servidor,
	que ignora pedidos rápidos demais.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Remotes = Compartilhado.Remotes

local Entrada = {}

local remoteTreinar = Remotes.obter("TreinarPedido")
local INTERVALO = Config.Geral.COOLDOWN_CLIQUE + 0.03

local segurando = false

local function comecar()
	if segurando then
		return
	end

	segurando = true

	task.spawn(function()
		while segurando do
			remoteTreinar:FireServer()
			task.wait(INTERVALO)
		end
	end)
end

local function parar()
	segurando = false
end

local function ehEntradaDeTreino(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.E
end

function Entrada.iniciar(botaoTreinar: GuiButton?)
	UserInputService.InputBegan:Connect(function(input, processadoPelaInterface)
		if processadoPelaInterface or not ehEntradaDeTreino(input) then
			return
		end
		comecar()
	end)

	UserInputService.InputEnded:Connect(function(input)
		if ehEntradaDeTreino(input) then
			parar()
		end
	end)

	if botaoTreinar then
		-- InputBegan/InputEnded do próprio botão cobrem mouse e toque com um só caminho.
		botaoTreinar.InputBegan:Connect(function(input)
			if ehEntradaDeTreino(input) then
				comecar()
			end
		end)
		botaoTreinar.InputEnded:Connect(function(input)
			if ehEntradaDeTreino(input) then
				parar()
			end
		end)
		botaoTreinar.MouseLeave:Connect(parar)
	end
end

return Entrada
