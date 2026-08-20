--[[
	Rodapé de combate: botão BATER, botão AUTO, rótulo da zona e os números
	de ganho que sobem na tela.

	MEXER AQUI para: qualquer coisa do momento de bater. O alvo, o dano e a
	recompensa são decididos no servidor — daqui só sai o pedido.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Compartilhado = require(ReplicatedStorage:WaitForChild("Compartilhado"))
local Formato = Compartilhado.Formato
local Remotes = Compartilhado.Remotes

local Ui = require(script.Parent.Parent.Ui)
local Estado = require(script.Parent.Parent.Estado)

local player = Players.LocalPlayer

local Golpe = { ordem = 26 }

local INTERVALO_POPUP = 0.18

local w: { [string]: any } = {}
local remoteAuto = Remotes.obter("AlternarAuto")
local forcaAnterior = 0
local ultimoPopup = 0

--- Número flutuante de "+X" quando a Força sobe.
local function mostrarGanho(quantidade: number)
	local agora = os.clock()
	if agora - ultimoPopup < INTERVALO_POPUP or quantidade <= 0 then
		return
	end
	ultimoPopup = agora

	local rotulo = Ui.texto({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, math.random(-70, 70), 0.62, 0),
		Size = UDim2.fromOffset(200, 34),
		Text = "+" .. Formato.abreviar(quantidade),
		TextColor3 = Ui.cores.forca,
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Ui.fonteTitulo,
		TextSize = 26,
		TextStrokeTransparency = 0.5,
		Parent = w.raiz,
	})

	local subida = TweenService:Create(rotulo, TweenInfo.new(0.85, Enum.EasingStyle.Quad), {
		Position = rotulo.Position - UDim2.fromOffset(0, 70),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})

	subida:Play()
	subida.Completed:Once(function()
		rotulo:Destroy()
	end)
end

local function atualizar()
	local ligado = Estado.ler("AutoLigado", false)
	w.auto.BackgroundColor3 = if ligado then Ui.cores.sucesso else Ui.cores.cartaoClaro
	w.auto.TextColor3 = if ligado then Ui.cores.fundo else Ui.cores.texto
	w.auto.Text = if ligado then "AUTO ON" else "AUTO"

	local zona = Estado.ler("ZonaAtual", "")
	if zona == "" then
		w.zona.Text = "Siga em frente e mate os monstros para ganhar Força"
		w.zona.TextColor3 = Ui.cores.textoFraco
	elseif Estado.ler("ZonaBloqueada", false) then
		w.zona.Text = "🔒 " .. zona .. " — Força insuficiente"
		w.zona.TextColor3 = Ui.cores.erro
	else
		w.zona.Text = "⚡ " .. zona
		w.zona.TextColor3 = Ui.cores.sucesso
	end

	local forca = Estado.ler("Forca", 0)
	if forca > forcaAnterior then
		mostrarGanho(forca - forcaAnterior)
	end
	forcaAnterior = forca
end

function Golpe.montar(ctx)
	w.raiz = ctx.raiz
	forcaAnterior = Estado.ler("Forca", 0)

	w.zona = Ui.texto({
		Name = "Zona",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -178),
		Size = UDim2.fromOffset(460, 26),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Ui.fonteTitulo,
		TextSize = 16,
		TextStrokeTransparency = 0.7,
		Parent = ctx.raiz,
	})

	w.bater = Ui.novo("TextButton", {
		Name = "Bater",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -28),
		Size = UDim2.fromOffset(140, 140),
		BackgroundColor3 = Ui.cores.forca,
		BackgroundTransparency = 0.08,
		AutoButtonColor = true,
		Text = "BATER",
		Font = Ui.fonteTitulo,
		TextSize = 20,
		TextColor3 = Ui.cores.fundo,
		Parent = ctx.raiz,
	}, {
		Ui.novo("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		Ui.contorno(Ui.cores.forca, 3),
	})

	w.auto = Ui.novo("TextButton", {
		Name = "Auto",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 118, 1, -62),
		Size = UDim2.fromOffset(96, 44),
		BackgroundColor3 = Ui.cores.cartaoClaro,
		AutoButtonColor = true,
		Text = "AUTO",
		Font = Ui.fonteTitulo,
		TextSize = 14,
		TextColor3 = Ui.cores.texto,
		Parent = ctx.raiz,
	}, { Ui.canto(12), Ui.contorno() })

	w.auto.Activated:Connect(function()
		-- O estado real é do servidor; daqui só sai o pedido de inverter.
		remoteAuto:FireServer(not player:GetAttribute("AutoLigado"))
	end)

	Estado.observar({ "Forca", "AutoLigado", "ZonaAtual", "ZonaBloqueada" }, atualizar)
end

--- Usado pela Entrada para ligar segurar-para-bater ao botão.
function Golpe.botao(): TextButton
	return w.bater
end

return Golpe
