--[[
	Formatação de números grandes. Em jogo de evolução os valores explodem
	rápido (10^12 em poucas horas), então tudo que aparece na tela passa por aqui.
]]

local Formato = {}

local SUFIXOS = {
	"",
	"K",
	"M",
	"B",
	"T",
	"Qa",
	"Qi",
	"Sx",
	"Sp",
	"Oc",
	"No",
	"Dc",
}

--- Converte 1234567 em "1.23M".
function Formato.abreviar(valor: number?): string
	local numero = tonumber(valor) or 0
	local sinal = numero < 0 and "-" or ""
	numero = math.abs(numero)

	if numero < 1000 then
		return sinal .. tostring(math.floor(numero))
	end

	local indice = math.floor(math.log10(numero) / 3)
	indice = math.clamp(indice, 1, #SUFIXOS - 1)

	local reduzido = numero / (1000 ^ indice)

	-- Arredondamento pode empurrar 999.999 para "1000.00"; sobe um degrau.
	if reduzido >= 999.995 and indice < #SUFIXOS - 1 then
		indice += 1
		reduzido /= 1000
	end

	local texto = string.format("%.2f", reduzido)
	texto = string.gsub(texto, "0+$", "")
	texto = string.gsub(texto, "%.$", "")

	return sinal .. texto .. SUFIXOS[indice + 1]
end

--- Converte 1.75 em "+75%".
function Formato.bonus(multiplicador: number): string
	local percentual = (multiplicador - 1) * 100
	return string.format("+%d%%", math.floor(percentual + 0.5))
end

--- Converte 3725 segundos em "1h 02m".
function Formato.tempo(segundos: number): string
	local total = math.max(math.floor(segundos), 0)
	local horas = math.floor(total / 3600)
	local minutos = math.floor((total % 3600) / 60)

	if horas > 0 then
		return string.format("%dh %02dm", horas, minutos)
	end

	return string.format("%dm %02ds", minutos, total % 60)
end

return Formato
