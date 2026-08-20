--[[
	Golpe: clique, toque, tecla E ou o botão BATER.

	Segurar mantém o pedido em ritmo constante. O intervalo daqui é só de
	conforto — quem manda no limite real é o COOLDOWN_GOLPE do servidor, que
	ignora pedidos rápidos demais. O cliente também não escolhe o alvo: manda
	"bati" e o servidor decide em qual monstro isso cai.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Config = Compartilhado.Config
local Remotes = Compartilhado.Remotes

local Entrada = { ordem = 60 }

local remoteBater = Remotes.obter("Bater")
local INTERVALO = Config.Geral.COOLDOWN_GOLPE + 0.03

local segurando = false

local function comecar()
	if segurando then
		return
	end

	segurando = true

	task.spawn(function()
		while segurando do
			remoteBater:FireServer()
			task.wait(INTERVALO)
		end
	end)
end

local function parar()
	segurando = false
end

local function ehGolpe(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.E
end

function Entrada.ligar(ctx)
	local botaoBater = ctx.paineis.Golpe.botao()
	UserInputService.InputBegan:Connect(function(input, processadoPelaInterface)
		if processadoPelaInterface or not ehGolpe(input) then
			return
		end
		comecar()
	end)

	UserInputService.InputEnded:Connect(function(input)
		if ehGolpe(input) then
			parar()
		end
	end)

	if botaoBater then
		-- InputBegan/InputEnded do próprio botão cobrem mouse e toque de uma vez.
		botaoBater.InputBegan:Connect(function(input)
			if ehGolpe(input) then
				comecar()
			end
		end)
		botaoBater.InputEnded:Connect(function(input)
			if ehGolpe(input) then
				parar()
			end
		end)
		botaoBater.MouseLeave:Connect(parar)
	end
end

return Entrada
