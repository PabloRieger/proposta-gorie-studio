import gsap from "gsap";
import ScrollTrigger from "gsap/ScrollTrigger";
import { CINEMA_SCROLL_VH } from "./config.js";

gsap.registerPlugin(ScrollTrigger);

// 2x em tela Retina/4K significa desenhar até 4x mais pixels por frame do
// que numa tela comum, num vídeo que já não tem esse tanto de detalhe pra
// mostrar. 1.5x continua nítido e corta ~44% dos pixels de cada draw.
const MAX_DPR = 1.5;

// O clipe é 16:9 e a composição ocupa a largura toda. Cover puro em telas
// quadradas ou verticais corta metade do enquadramento, então limitamos o
// quanto pode sumir e preenchemos o resto com um fundo ambiente do próprio
// frame — nunca uma tarja preta.
const MIN_FRAME_VISIBLE = 0.74;
const AMBIENT_SAMPLE_W = 32;
const AMBIENT_SCRIM = 0.52;
const FEATHER = 0.055;
// O fundo ambiente é um zoom borrado — já abstrato o bastante pra ninguém
// notar se ele atualiza 9x por segundo em vez de 60x. Isso tira do caminho
// mais quente (todo frame, sempre ativo em celular em retrato) os dois
// draws de tamanho do canvas inteiro que ele exige.
const AMBIENT_UPDATE_MS = 110;

/**
 * Experiência cinematográfica: a posição de scroll é a única fonte de verdade
 * do currentTime do vídeo. O vídeo nunca toca sozinho; cada frame é desenhado
 * manualmente no canvas.
 */
export function initCinemaScroll() {
  const spacer = document.querySelector("[data-cinema-spacer]");
  const pin = document.querySelector("[data-cinema-pin]");
  const canvas = document.querySelector("[data-cinema-canvas]");
  const video = document.querySelector("[data-cinema-video]");
  const hint = document.querySelector("[data-cinema-hint]");
  const flood = document.querySelector("[data-cinema-flood]");
  const vignette = document.querySelector("[data-cinema-vignette]");
  const texts = Array.from(document.querySelectorAll("[data-cinema-text]"));

  if (!spacer || !pin || !canvas || !video) return () => {};

  spacer.style.height = `${CINEMA_SCROLL_VH}vh`;

  const ctx = canvas.getContext("2d", { alpha: false });

  let disposed = false;
  let scrollTrigger = null;
  let textTimeline = null;
  let rvfcHandle = null;

  // ---------------------------------------------------------------- canvas
  let fit = { dx: 0, dy: 0, dw: 0, dh: 0, featherX: 0, featherY: 0, needsAmbient: false };

  // Canvas minúsculo: ampliá-lo produz o desfoque do fundo praticamente de
  // graça, sem custo de ctx.filter a cada frame.
  const ambient = document.createElement("canvas");
  const ambientCtx = ambient.getContext("2d", { alpha: false });

  const SCRIM_RGB = "15, 8, 14";

  function computeFit() {
    const vw = video.videoWidth;
    const vh = video.videoHeight;
    if (!vw || !vh) return;

    const cw = canvas.width;
    const ch = canvas.height;

    const contain = Math.min(cw / vw, ch / vh);
    const cover = Math.max(cw / vw, ch / vh);
    // Amplia além do contain só até o ponto em que ainda resta
    // MIN_FRAME_VISIBLE do enquadramento na dimensão apertada.
    const scale = Math.min(cover, contain / MIN_FRAME_VISIBLE);

    const dw = vw * scale;
    const dh = vh * scale;

    const rdw = Math.round(dw);
    const rdh = Math.round(dh);
    const needsAmbient = rdw < cw - 1 || rdh < ch - 1;

    fit = {
      dx: Math.round((cw - dw) / 2),
      dy: Math.round((ch - dh) / 2),
      dw: rdw,
      dh: rdh,
      needsAmbient,
    };

    ambient.width = AMBIENT_SAMPLE_W;
    ambient.height = Math.max(1, Math.round((AMBIENT_SAMPLE_W * ch) / cw));

    const feather = needsAmbient ? Math.round(Math.min(rdw, rdh) * FEATHER) : 0;
    fit.featherX = rdw < cw - 1 ? feather : 0;
    fit.featherY = rdh < ch - 1 ? feather : 0;
  }

  function resizeCanvas() {
    const dpr = Math.min(window.devicePixelRatio || 1, MAX_DPR);
    const rect = pin.getBoundingClientRect();
    const w = Math.round(rect.width * dpr);
    const h = Math.round(rect.height * dpr);
    if (canvas.width === w && canvas.height === h) return false;
    canvas.width = w;
    canvas.height = h;
    computeFit();
    lastAmbientUpdate = 0; // geometria mudou, força o ambiente a redesenhar já
    return true;
  }

  // Esmaece só a tira de borda (poucos % da área do canvas) com um
  // gradiente nativo — muito mais barato que recompor o frame inteiro
  // num canvas auxiliar a cada tick, e o resultado é visualmente idêntico.
  function featherEdge(x, y, w, h, x0, y0, x1, y1) {
    const g = ctx.createLinearGradient(x0, y0, x1, y1);
    g.addColorStop(0, `rgba(${SCRIM_RGB}, ${AMBIENT_SCRIM})`);
    g.addColorStop(1, `rgba(${SCRIM_RGB}, 0)`);
    ctx.fillStyle = g;
    ctx.fillRect(x, y, w, h);
  }

  let lastAmbientUpdate = 0;

  function drawFrame() {
    if (disposed || !fit.dw) return;

    if (!fit.needsAmbient) {
      // Tela 16:9: o frame já cobre tudo, um único draw resolve.
      ctx.drawImage(video, fit.dx, fit.dy, fit.dw, fit.dh);
      return;
    }

    // Os dois draws de tamanho do canvas inteiro (ampliar o ambiente +
    // pintar o véu) só rodam a cada ~110ms — o resultado já é um borrão de
    // cor, atualizar mais rápido que isso é gasto que ninguém percebe.
    const now = performance.now();
    if (now - lastAmbientUpdate >= AMBIENT_UPDATE_MS) {
      lastAmbientUpdate = now;

      // Recorte cover do frame reduzido ao extremo e reampliado: vira uma
      // extensão desfocada da própria cena atrás do vídeo.
      const vw = video.videoWidth;
      const vh = video.videoHeight;
      const aw = ambient.width;
      const ah = ambient.height;
      const s = Math.max(aw / vw, ah / vh);
      ambientCtx.drawImage(video, (aw - vw * s) / 2, (ah - vh * s) / 2, vw * s, vh * s);

      ctx.drawImage(ambient, 0, 0, aw, ah, 0, 0, canvas.width, canvas.height);
      ctx.fillStyle = `rgba(${SCRIM_RGB}, ${AMBIENT_SCRIM})`;
      ctx.fillRect(0, 0, canvas.width, canvas.height);
    }

    // Frame nítido desenhado direto — sem canvas auxiliar nem composição
    // pixel a pixel. Esse sim roda todo frame: é a parte que o olho segue.
    ctx.drawImage(video, fit.dx, fit.dy, fit.dw, fit.dh);

    const { dx, dy, dw, dh, featherX, featherY } = fit;
    if (featherX > 0) {
      featherEdge(dx, dy, featherX, dh, dx + featherX, 0, dx, 0);
      featherEdge(dx + dw - featherX, dy, featherX, dh, dx + dw - featherX, 0, dx + dw, 0);
    }
    if (featherY > 0) {
      featherEdge(dx, dy, dw, featherY, 0, dy + featherY, 0, dy);
      featherEdge(dx, dy + dh - featherY, dw, featherY, 0, dy + dh - featherY, 0, dy + dh);
    }
  }

  // ------------------------------------------------- frame-ready scheduling
  const hasRVFC = typeof video.requestVideoFrameCallback === "function";
  let fallbackTimer = null;

  function cancelPending() {
    if (rvfcHandle !== null && typeof video.cancelVideoFrameCallback === "function") {
      video.cancelVideoFrameCallback(rvfcHandle);
    }
    rvfcHandle = null;
    if (fallbackTimer) {
      clearTimeout(fallbackTimer);
      fallbackTimer = null;
    }
  }

  // Desenha assim que o decoder entregar o frame do seek. O timer é a rede de
  // segurança: se o seek cair no frame já exibido, nenhum callback dispara e
  // sem ele o canvas congelaria para sempre.
  function scheduleDraw() {
    if (disposed) return;
    cancelPending();

    if (hasRVFC) {
      rvfcHandle = video.requestVideoFrameCallback(() => {
        rvfcHandle = null;
        drawFrame();
      });
    } else {
      video.addEventListener("seeked", onSeeked, { once: true });
    }

    fallbackTimer = setTimeout(() => {
      fallbackTimer = null;
      drawFrame();
    }, 140);
  }

  function onSeeked() {
    drawFrame();
  }

  // O objeto que o GSAP interpola. Ao invés de escrever direto no vídeo a cada
  // tick, guardamos o alvo e aplicamos um único seek por frame do ticker.
  const state = { time: 0 };
  let lastAppliedTime = -1;

  // O vídeo é 30fps: um frame dura ~0.033s. Buscar mais fino que isso não
  // revela nenhum frame novo — só força o decoder a repetir trabalho.
  const SEEK_EPSILON = 1 / 60;

  // O epsilon acima só ajuda quando a posição quase não muda de um tick pro
  // outro (rolagem devagar ou freando). Num scroll RÁPIDO a posição salta
  // bastante a cada tick, então ele nunca barra nada — e é justo aí, sob
  // rolagem rápida, que o decodificador de vídeo de um celular mais fraco
  // sofre: buscar (seek) é bem mais caro que decodificar em sequência, e
  // pedir isso 60x/s pode empilhar mais rápido do que o hardware entrega.
  // Este teto por tempo limita a TAXA de busca real, não só a distância —
  // e a borda de saída (trailing edge) garante que a última posição pedida
  // sempre acaba sendo aplicada, mesmo que o scroll pare no meio do intervalo.
  const MIN_SEEK_INTERVAL_MS = 40; // ~25 buscas/s no máximo
  let lastSeekAt = 0;
  let pendingSeekTimer = null;

  function commitSeek() {
    pendingSeekTimer = null;
    const t = state.time;
    if (Math.abs(t - lastAppliedTime) < SEEK_EPSILON) return;
    lastAppliedTime = t;
    lastSeekAt = performance.now();
    if (video.readyState >= 1) {
      video.currentTime = t;
      scheduleDraw();
    }
  }

  function applyTime() {
    if (disposed) return;
    const elapsed = performance.now() - lastSeekAt;
    if (elapsed >= MIN_SEEK_INTERVAL_MS) {
      if (pendingSeekTimer) clearTimeout(pendingSeekTimer);
      commitSeek();
    } else if (!pendingSeekTimer) {
      pendingSeekTimer = setTimeout(commitSeek, MIN_SEEK_INTERVAL_MS - elapsed);
    }
  }

  // ------------------------------------------------------------ inicializar
  function build() {
    if (disposed) return;

    const duration = video.duration;
    if (!Number.isFinite(duration) || duration <= 0) return;

    // último frame real (evita travar no fim exato, que alguns decoders
    // devolvem como frame vazio)
    const endTime = Math.max(0, duration - 0.05);

    resizeCanvas();
    video.currentTime = 0;
    scheduleDraw();

    // Timeline dos textos: percorrida pelo mesmo progress do ScrollTrigger,
    // portanto reverte naturalmente ao rolar para cima.
    // Posições são fracções do progresso (0–1); a timeline dura exatamente 1.
    textTimeline = gsap.timeline({ paused: true, defaults: { ease: "power2.out" } });

    // O primeiro texto já nasce visível — quem chega na página lê a headline
    // sem precisar rolar. Ele só tem saída.
    const beats = [
      { el: texts[0], in: null, out: 0.15 },
      { el: texts[1], in: 0.34, out: 0.54 },
      { el: texts[2], in: 0.64, out: 0.82 },
    ];

    // Sem filter: blur() aqui — animar blur força o navegador a recompor a
    // região inteira a cada frame, e essas janelas de transição caem bem em
    // cima do scroll mais pesado da página. Opacidade + translateY já dão o
    // ar editorial sem esse custo.
    beats.forEach(({ el, in: tIn, out: tOut }) => {
      if (!el) return;
      if (tIn !== null) {
        textTimeline.fromTo(
          el,
          { autoAlpha: 0, y: 34 },
          { autoAlpha: 1, y: 0, duration: 0.1 },
          tIn
        );
      }
      textTimeline.to(
        el,
        { autoAlpha: 0, y: -26, duration: 0.1 },
        tOut
      );
    });

    if (hint) {
      textTimeline.to(hint, { autoAlpha: 0, duration: 0.04 }, 0.01);
    }
    if (vignette) {
      textTimeline.to(vignette, { opacity: 0, duration: 0.08, ease: "none" }, 0.9);
    }
    if (flood) {
      textTimeline.to(flood, { opacity: 1, duration: 0.06, ease: "power1.in" }, 0.94);
    }

    // Ancora o fim exato da timeline em 1 para o progress mapear 1:1.
    textTimeline.set({}, {}, 1);

    scrollTrigger = ScrollTrigger.create({
      trigger: spacer,
      start: "top top",
      end: "bottom bottom",
      pin: pin,
      pinSpacing: false,
      anticipatePin: 1,
      // O Lenis já suaviza a rolagem; scrub true evita empilhar um segundo
      // atraso e deixa o frame colado no gesto.
      scrub: true,
      invalidateOnRefresh: true,
      onUpdate: (self) => {
        state.time = self.progress * endTime;
        applyTime();
        textTimeline.progress(self.progress);
      },
      onRefresh: () => {
        resizeCanvas();
        drawFrame();
      },
    });

    ScrollTrigger.refresh();

    if (import.meta.env.DEV) {
      window.__cinema = { scrollTrigger, textTimeline, video, canvas, pin, ScrollTrigger, gsap, drawFrame, resizeCanvas, fit: () => fit };
    }
  }

  // -------------------------------------------------------------- metadados
  function onLoadedMetadata() {
    if (video.readyState >= 1) build();
  }

  if (video.readyState >= 1 && Number.isFinite(video.duration) && video.duration > 0) {
    build();
  } else {
    video.addEventListener("loadedmetadata", onLoadedMetadata, { once: true });
    video.load();
  }

  // -------------------------------------------------------------- resize
  let resizeRaf = null;
  function onResize() {
    if (resizeRaf) cancelAnimationFrame(resizeRaf);
    resizeRaf = requestAnimationFrame(() => {
      resizeRaf = null;
      const changed = resizeCanvas();
      if (changed) drawFrame();
      ScrollTrigger.refresh();
    });
  }

  window.addEventListener("resize", onResize);
  window.addEventListener("orientationchange", onResize);

  // -------------------------------------------------------------- cleanup
  return function destroy() {
    disposed = true;
    window.removeEventListener("resize", onResize);
    window.removeEventListener("orientationchange", onResize);
    video.removeEventListener("loadedmetadata", onLoadedMetadata);
    video.removeEventListener("seeked", onSeeked);
    if (resizeRaf) cancelAnimationFrame(resizeRaf);
    if (pendingSeekTimer) clearTimeout(pendingSeekTimer);
    cancelPending();
    if (scrollTrigger) scrollTrigger.kill();
    if (textTimeline) textTimeline.kill();
  };
}
