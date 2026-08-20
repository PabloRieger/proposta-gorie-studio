--[[
	CARREGADOR DO CLIENTE.

	Como no servidor: este arquivo não conhece painel nenhum pelo nome.
	Adicionar interface é criar UM arquivo em paineis/.

	Contrato de um painel:

		local Painel = { ordem = 30 }

		function Painel.montar(ctx)   -- constrói a interface
		function Painel.ligar(ctx)    -- conecta remotes e sinais

		return Painel

	As duas fases existem porque `ligar` pode precisar de um painel que ainda
	não existia durante o `montar` — a Entrada usa o botão que o Golpe criou.
	Em `ligar`, `ctx.paineis` já está completo.

	Painel desenha em `ctx.raiz`, não na ScreenGui: a raiz carrega o UIScale
	que adapta tudo a tela pequena de uma vez só.

	Conversa entre painéis é por sinal (Compartilhado.Eventos), nunca por
	referência direta: o botão da loja no HUD emite "PedirLoja" sem saber que
	a Loja existe.

	Faixas em uso: 10 avisos · 20 placar · 25 ações · 26 golpe · 30 loja
	                40 bonecos · 50 barreiras · 60 entrada · 70 pedestais
]]

local Players = game:GetService("Players")

local Ui = require(script.Ui)

local player = Players.LocalPlayer

local gui = Ui.novo("ScreenGui", {
	Name = "InterfaceEvolucao",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

local raiz = Ui.novo("Frame", {
	Name = "Raiz",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Parent = gui,
})

--[[
	Uma escala só para telas pequenas, aplicada na raiz. É mais simples e mais
	previsível do que cada painel reposicionar em UDim2 relativo — e um painel
	novo herda o comportamento sem escrever nada.
]]
local escala = Ui.novo("UIScale", { Parent = raiz })
local camera = workspace.CurrentCamera

local function ajustarEscala()
	local largura = camera.ViewportSize.X
	escala.Scale = if largura < 640 then 0.72 elseif largura < 900 then 0.85 else 1
end

camera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustarEscala)
ajustarEscala()

local contexto = { gui = gui, raiz = raiz, paineis = {} }

local emOrdem = {}

for _, modulo in script.paineis:GetChildren() do
	if modulo:IsA("ModuleScript") then
		local painel = require(modulo)
		painel.nome = modulo.Name
		contexto.paineis[modulo.Name] = painel
		table.insert(emOrdem, painel)
	end
end

table.sort(emOrdem, function(a, b)
	return (a.ordem or 100) < (b.ordem or 100)
end)

for _, painel in emOrdem do
	if painel.montar then
		painel.montar(contexto)
	end
end

for _, painel in emOrdem do
	if painel.ligar then
		painel.ligar(contexto)
	end
end
