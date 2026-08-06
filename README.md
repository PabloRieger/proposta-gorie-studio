# GORIE Studio — Landing page

Landing page da GORIE Studio com uma seção cinematográfica onde a rolagem
controla diretamente o tempo do vídeo (sem autoplay, totalmente reversível).

## Rodar localmente

```bash
npm install
npm run dev
```

## Publicar

```bash
npm run build
```

O conteúdo de `dist/` é o site pronto — pode ser enviado para qualquer
hospedagem estática (HostGator, Hostinger, GitHub Pages).

**No ar:** https://pablorieger.github.io/proposta-gorie-studio/

Este repositório usa duas branches:

| Branch | Conteúdo |
| --- | --- |
| `main` | código-fonte |
| `master` | o conteúdo de `dist/` na raiz — é daqui que o GitHub Pages publica |

Para republicar depois de um `npm run build`, envie os arquivos de `dist/`
para a raiz da branch `master`.

## Onde editar

| O quê | Arquivo |
| --- | --- |
| Número de WhatsApp (usado em todos os CTAs) | `src/config.js` |
| Duração da experiência de scroll (`CINEMA_SCROLL_VH`) | `src/config.js` |
| Textos e seções | `index.html` |
| Cores, tipografia e espaçamentos | `src/style.css` |
| Sincronia vídeo ↔ scroll e animação dos textos | `src/cinema-scroll.js` |
| Navegação, reveals e Lenis | `src/main.js` |

## Como a seção cinematográfica funciona

O vídeo nunca é reproduzido. Um `<video>` invisível serve apenas como
decodificador: o ScrollTrigger converte a posição da rolagem em um `progress`
de 0 a 1, esse valor vira `currentTime` do vídeo, e o frame resultante é
desenhado em um `<canvas>` fullscreen com recorte equivalente a
`object-fit: cover`.

Os textos sobrepostos são HTML real, animados por uma única timeline GSAP
percorrida pelo mesmo `progress` — por isso tudo reverte ao rolar para cima.
