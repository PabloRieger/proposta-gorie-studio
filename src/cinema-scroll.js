import gsap from "gsap";
import ScrollTrigger from "gsap/ScrollTrigger";
import { CINEMA_SCROLL_VH } from "./config.js";

gsap.registerPlugin(ScrollTrigger);

const MAX_DPR = 2;

// O clipe é 16:9 e a composição ocupa a largura toda. Cover puro em telas
// quadradas ou verticais corta metade do enquadramento, então limitamos o
// quanto pode sumir e preenchemos o resto com um fundo ambiente do próprio
// frame — nunca uma tarja preta.
const MIN_FRAME_VISIBLE = 0.74;
const AMBIENT_SAMPLE_W = 32;
const AMBIENT_SCRIM = 0.52;
const FEATHER = 0.055;

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
  let fit = { dx: 0, dy: 0, dw: 0, dh: 0, needsAmbient: false };

  // Canvas minúsculo: ampliá-lo produz o desfoque do fundo praticamente de
  // graça, sem custo de ctx.filter a cada frame.
  const ambient = document.createElement("canvas");
  const ambientCtx = ambient.getContext("2d", { alpha: false });

  // Frame nítido com as bordas esmaecidas, para a emenda com o fundo sumir.
  // A máscara é remontada só no resize.
  const framed = document.createElement("canvas");
  const framedCtx = framed.getContext("2d");
  const mask = document.createElement("canvas");

  // Opaca no miolo, desaparecendo rumo às bordas: usada com destination-in
  // para o frame nítido perder alfa exatamente onde encosta no fundo.
  function buildMask(dw, dh, fadeX, fadeY) {
    mask.width = dw;
    mask.height = dh;
    const m = mask.getContext("2d");
    m.clearRect(0, 0, dw, dh);
    m.fillStyle = "#000";
    m.fillRect(0, 0, dw, dh);

    // Apaga progressivamente da borda para dentro.
    m.globalCompositeOperation = "destination-out";
    const band = (x, y, w, h, x0, y0, x1, y1) => {
      const g = m.createLinearGradient(x0, y0, x1, y1);
      g.addColorStop(0, "rgba(0,0,0,1)");
      g.addColorStop(1, "rgba(0,0,0,0)");
      m.fillStyle = g;
      m.fillRect(x, y, w, h);
    };

    if (fadeY > 0) {
      band(0, 0, dw, fadeY, 0, 0, 0, fadeY);
      band(0, dh - fadeY, dw, fadeY, 0, dh, 0, dh - fadeY);
    }
    if (fadeX > 0) {
      band(0, 0, fadeX, dh, 0, 0, fadeX, 0);
      band(dw - fadeX, 0, fadeX, dh, dw, 0, dw - fadeX, 0);
    }
  }

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

    if (needsAmbient) {
      framed.width = rdw;
      framed.height = rdh;
      const feather = Math.round(Math.min(rdw, rdh) * FEATHER);
      buildMask(rdw, rdh, rdw < cw - 1 ? feather : 0, rdh < ch - 1 ? feather : 0);
    }
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
    return true;
  }

  function drawFrame() {
    if (disposed || !fit.dw) return;

    if (!fit.needsAmbient) {
      // Tela 16:9: o frame já cobre tudo, um único draw resolve.
      ctx.drawImage(video, fit.dx, fit.dy, fit.dw, fit.dh);
      return;
    }

    // Recorte cover do frame reduzido ao extremo e reampliado: vira uma
    // extensão desfocada da própria cena atrás do vídeo.
    const vw = video.videoWidth;
    const vh = video.videoHeight;
    const aw = ambient.width;
    const ah = ambient.height;
    const s = Math.max(aw / vw, ah / vh);
    ambientCtx.drawImage(video, (aw - vw * s) / 2, (ah - vh * s) / 2, vw * s, vh * s);

    ctx.drawImage(ambient, 0, 0, aw, ah, 0, 0, canvas.width, canvas.height);
    ctx.fillStyle = `rgba(15, 8, 14, ${AMBIENT_SCRIM})`;
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    framedCtx.globalCompositeOperation = "source-over";
    framedCtx.drawImage(video, 0, 0, fit.dw, fit.dh);
    framedCtx.globalCompositeOperation = "destination-in";
    framedCtx.drawImage(mask, 0, 0);

    ctx.drawImage(framed, fit.dx, fit.dy);
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

  function applyTime() {
    if (disposed) return;
    const t = state.time;
    if (Math.abs(t - lastAppliedTime) < 0.001) return;
    lastAppliedTime = t;
    if (video.readyState >= 1) {
      video.currentTime = t;
      scheduleDraw();
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

    beats.forEach(({ el, in: tIn, out: tOut }) => {
      if (!el) return;
      if (tIn !== null) {
        textTimeline.fromTo(
          el,
          { autoAlpha: 0, y: 34, filter: "blur(8px)" },
          { autoAlpha: 1, y: 0, filter: "blur(0px)", duration: 0.1 },
          tIn
        );
      }
      textTimeline.to(
        el,
        { autoAlpha: 0, y: -26, filter: "blur(8px)", duration: 0.1 },
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
    cancelPending();
    if (scrollTrigger) scrollTrigger.kill();
    if (textTimeline) textTimeline.kill();
  };
}
