--[[
	Avisos curtos no topo da tela (compra recusada, rank novo, evolução alheia).
]]

local TweenService = game:GetService("TweenService")

local Ui = require(script.Parent.Ui)

local Notificacoes = {}

local DURACAO = 3.5
local MAXIMO = 4

local container: Frame? = nil
local ativas = 0

local CORES = {
	sucesso = Ui.cores.sucesso,
	erro = Ui.cores.erro,
	info = Ui.cores.texto,
}

function Notificacoes.criar(pai: ScreenGui)
	container = Ui.novo("Frame", {
		Name = "Notificacoes",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 16),
		Size = UDim2.fromOffset(420, 200),
		BackgroundTransparency = 1,
		Parent = pai,
	}, {
		Ui.novo("UIListLayout", {
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

function Notificacoes.mostrar(mensagem: string, tipo: string?)
	if not container or ativas >= MAXIMO then
		return
	end

	ativas += 1

	local cartao = Ui.novo("Frame", {
		Name = "Aviso",
		Size = UDim2.fromOffset(420, 42),
		BackgroundColor3 = Ui.cores.cartao,
		BackgroundTransparency = 0.06,
		Parent = container,
	}, {
		Ui.canto(10),
		Ui.contorno(CORES[tipo or "info"] or Ui.cores.texto, 1.5),
		Ui.texto({
			Size = UDim2.fromScale(1, 1),
			Text = mensagem,
			TextColor3 = CORES[tipo or "info"] or Ui.cores.texto,
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = Ui.fonteTitulo,
			TextSize = 16,
		}),
	})

	local entrada = TweenService:Create(cartao, TweenInfo.new(0.18), { BackgroundTransparency = 0.06 })
	cartao.BackgroundTransparency = 1
	entrada:Play()

	task.delay(DURACAO, function()
		local saida = TweenService:Create(cartao, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
		saida:Play()
		saida.Completed:Wait()
		cartao:Destroy()
		ativas -= 1
	end)
end

return Notificacoes
