#!/usr/bin/env python3
"""
Gera um arquivo de lugar (.rbxlx) a partir de src/, sem precisar do Rojo.

Serve para abrir o jogo no Studio com dois cliques. Para desenvolver de
verdade, prefira `rojo serve`: aí o Studio reflete cada arquivo salvo na hora,
enquanto este arquivo é um retrato do código no momento em que foi gerado.

Segue as mesmas regras de nomes do Rojo:
    pasta/init.lua          -> ModuleScript com o nome da pasta
    pasta/init.server.lua   -> Script
    pasta/init.client.lua   -> LocalScript
    pasta/ (sem init)       -> Folder
    arquivo.lua             -> ModuleScript
    arquivo.server.lua      -> Script
    arquivo.client.lua      -> LocalScript
"""

import pathlib
import sys
from xml.sax.saxutils import escape

RAIZ = pathlib.Path(__file__).resolve().parent.parent
ORIGEM = RAIZ / "src"
SAIDA = RAIZ / "EvolucaoLendaria.rbxlx"

# Onde cada pasta de src/ é montada na árvore do jogo.
MONTAGENS = [
    (["ReplicatedStorage"], "shared", "Compartilhado"),
    (["ServerScriptService"], "server", "Servidor"),
    (["StarterPlayer", "StarterPlayerScripts"], "client", "Cliente"),
]

# Serviços criados vazios para o lugar abrir completo.
SERVICOS_EXTRA = ["Workspace", "Lighting", "SoundService"]

_contador = 0


def referente() -> str:
    global _contador
    _contador += 1
    return f"RBX{_contador}"


def classe_de(nome: str) -> tuple[str, str]:
    """(nome da instância, classe) a partir do nome do arquivo."""
    if nome.endswith(".server.lua"):
        return nome[: -len(".server.lua")], "Script"
    if nome.endswith(".client.lua"):
        return nome[: -len(".client.lua")], "LocalScript"
    return nome[: -len(".lua")], "ModuleScript"


def cdata(texto: str) -> str:
    # "]]>" encerraria o bloco no meio do código; parte em dois blocos.
    return "<![CDATA[" + texto.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def item(classe: str, nome: str, fonte: str | None, filhos: list[str], nivel: int) -> str:
    espaco = "\t" * nivel
    linhas = [f'{espaco}<Item class="{classe}" referent="{referente()}">']
    linhas.append(f"{espaco}\t<Properties>")
    linhas.append(f'{espaco}\t\t<string name="Name">{escape(nome)}</string>')
    if fonte is not None:
        linhas.append(f'{espaco}\t\t<ProtectedString name="Source">{cdata(fonte)}</ProtectedString>')
    linhas.append(f"{espaco}\t</Properties>")
    linhas.extend(filhos)
    linhas.append(f"{espaco}</Item>")
    return "\n".join(linhas)


def converter(caminho: pathlib.Path, nome: str, nivel: int) -> str:
    """Converte uma pasta de src/ na árvore de instâncias correspondente."""
    classe, fonte = "Folder", None

    for sufixo, alvo in (
        ("init.server.lua", "Script"),
        ("init.client.lua", "LocalScript"),
        ("init.lua", "ModuleScript"),
    ):
        arquivo = caminho / sufixo
        if arquivo.is_file():
            classe = alvo
            fonte = arquivo.read_text(encoding="utf-8")
            break

    filhos = []
    for entrada in sorted(caminho.iterdir()):
        if entrada.is_dir():
            filhos.append(converter(entrada, entrada.name, nivel + 2))
        elif entrada.suffix == ".lua" and not entrada.name.startswith("init."):
            filho_nome, filho_classe = classe_de(entrada.name)
            filhos.append(
                item(
                    filho_classe,
                    filho_nome,
                    entrada.read_text(encoding="utf-8"),
                    [],
                    nivel + 2,
                )
            )

    return item(classe, nome, fonte, filhos, nivel)


def main() -> int:
    if not ORIGEM.is_dir():
        print(f"não encontrei {ORIGEM}", file=sys.stderr)
        return 1

    servicos = []

    for caminho_servico, pasta, nome_instancia in MONTAGENS:
        origem = ORIGEM / pasta
        if not origem.is_dir():
            print(f"não encontrei {origem}", file=sys.stderr)
            return 1

        conteudo = converter(origem, nome_instancia, len(caminho_servico) + 1)

        # Monta de dentro para fora: StarterPlayerScripts dentro de StarterPlayer.
        for nivel, servico in reversed(list(enumerate(caminho_servico))):
            conteudo = item(servico, servico, None, [conteudo], nivel + 1)

        servicos.append(conteudo)

    for servico in SERVICOS_EXTRA:
        servicos.append(item(servico, servico, None, [], 1))

    documento = "\n".join(
        [
            '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
            'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
            'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" '
            'version="4">',
            "\t<External>null</External>",
            "\t<External>nil</External>",
            *servicos,
            "</roblox>",
            "",
        ]
    )

    SAIDA.write_text(documento, encoding="utf-8")
    print(f"{SAIDA.relative_to(RAIZ)} gerado ({SAIDA.stat().st_size // 1024} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
