--[[
	Melhorias compradas com Moedas. Sobrevivem à evolução — é isso que faz
	cada ciclo novo ser mais rápido que o anterior.

	`preco(def, nivel)` é usado pelos DOIS lados: a loja do cliente mostra o
	valor e o servidor recalcula antes de cobrar. Nunca confie no preço que
	vier do cliente.
]]

local Melhorias = {}

Melhorias.lista = {
	{
		id = "treino",
		icone = "💪",
		nome = "Treino Intenso",
		descricao = "+18% de Força em cada ganho.",
		precoBase = 100,
		crescimento = 1.7,
		nivelMaximo = 40,
		bonusPorNivel = 0.18,
	},
	{
		id = "fortuna",
		icone = "💰",
		nome = "Fortuna",
		descricao = "+22% de Moedas em cada ganho.",
		precoBase = 150,
		crescimento = 1.75,
		nivelMaximo = 30,
		bonusPorNivel = 0.22,
	},
	{
		id = "punho",
		icone = "👊",
		nome = "Punho de Ferro",
		descricao = "+10% de Força por clique de treino.",
		precoBase = 400,
		crescimento = 2.1,
		nivelMaximo = 10,
		bonusPorNivel = 0.10,
	},
	{
		id = "velocidade",
		icone = "🥾",
		nome = "Botas Velozes",
		descricao = "+2 de velocidade de corrida.",
		precoBase = 250,
		crescimento = 1.7,
		nivelMaximo = 20,
		bonusPorNivel = 2,
	},
	{
		id = "salto",
		icone = "🪽",
		nome = "Salto Sobrenatural",
		descricao = "+6 de altura de salto.",
		precoBase = 300,
		crescimento = 1.7,
		nivelMaximo = 15,
		bonusPorNivel = 6,
	},
}

Melhorias.porId = {}
for _, definicao in Melhorias.lista do
	Melhorias.porId[definicao.id] = definicao
end

--- Preço da PRÓXIMA compra para quem já está no nível informado.
function Melhorias.preco(definicao, nivelAtual: number): number
	return math.floor(definicao.precoBase * definicao.crescimento ^ nivelAtual)
end

--- Bônus acumulado do nível (0 = nenhum bônus).
function Melhorias.bonus(id: string, nivel: number): number
	local definicao = Melhorias.porId[id]
	if not definicao then
		return 0
	end
	return definicao.bonusPorNivel * math.max(nivel, 0)
end

return Melhorias
