--[[
	Libera as barreiras das zonas já conquistadas.

	A colisão é desligada LOCALMENTE. Isso funciona porque o cliente é dono da
	física do próprio personagem, e evita o problema clássico de tentar fazer
	uma parte ser sólida para uns jogadores e não para outros no servidor
	(que exigiria grupos de colisão por faixa de progresso).

	Isto é conveniência visual, não segurança: quem burlar a barreira entra na
	zona, mas o CombateService revalida o requisito e não concede nada.
]]

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local Barreiras = { ordem = 50 }

local TRANSPARENCIA_BLOQUEADA = 0.55
local TRANSPARENCIA_LIBERADA = 0.94

local function atualizarUma(barreira: Instance, forca: number)
	if not barreira:IsA("BasePart") then
		return
	end

	local minima = barreira:GetAttribute("ForcaMinima") or 0
	local liberada = forca >= minima

	barreira.CanCollide = not liberada
	barreira.Transparency = if liberada then TRANSPARENCIA_LIBERADA else TRANSPARENCIA_BLOQUEADA
end

function Barreiras.montar()
	local pasta = workspace:WaitForChild("Barreiras", 30)
	if not pasta then
		warn("[Barreiras] pasta não encontrada em Workspace")
		return
	end

	local function atualizarTodas()
		local forca = player:GetAttribute("Forca") or 0
		for _, barreira in pasta:GetChildren() do
			atualizarUma(barreira, forca)
		end
	end

	player:GetAttributeChangedSignal("Forca"):Connect(atualizarTodas)
	pasta.ChildAdded:Connect(function(barreira)
		atualizarUma(barreira, player:GetAttribute("Forca") or 0)
	end)

	atualizarTodas()
end

return Barreiras
