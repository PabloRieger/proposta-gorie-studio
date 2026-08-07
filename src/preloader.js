// Teto de segurança: se a rede estiver muito ruim, entra assim mesmo em vez
// de prender o visitante. O canvas já sabe desenhar com o vídeo parcial.
const MAX_WAIT_MS = 16000;
// Rede se o evento "ended" não disparar (acontece em alguns navegadores).
const ENDED_FALLBACK_MS = 900;

/**
 * Segura a página até a animação da marca terminar por completo E o vídeo da
 * experiência ter dados suficientes para o scrub. Resolve sempre.
 */
export function runPreloader(cinemaVideo) {
  const root = document.querySelector("[data-preloader]");
  const bar = document.querySelector("[data-preloader-bar]");
  const logo = document.querySelector("[data-preloader-video]");

  if (!root || window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    root?.remove();
    return Promise.resolve();
  }

  document.body.classList.add("is-loading");
  logo?.play().catch(() => {});

  return new Promise((resolve) => {
    let finished = false;
    let logoDone = !logo;
    let videoDone = false;
    let endedTimer = null;

    const logoRatio = () => {
      if (logoDone) return 1;
      if (!logo?.duration) return 0;
      return Math.min(1, logo.currentTime / logo.duration);
    };

    const videoRatio = () => {
      if (videoDone) return 1;
      let ratio = cinemaVideo.readyState / 4;
      if (cinemaVideo.buffered.length && cinemaVideo.duration) {
        ratio = Math.max(ratio, cinemaVideo.buffered.end(0) / cinemaVideo.duration);
      }
      return Math.min(1, ratio);
    };

    // Só chega a 100% quando as duas frentes terminam — por isso o menor dos dois.
    const progress = () => {
      if (bar) bar.style.width = `${Math.min(logoRatio(), videoRatio()) * 100}%`;
    };

    const finish = () => {
      if (finished) return;
      finished = true;
      clearInterval(ticker);
      clearTimeout(endedTimer);
      clearTimeout(ceiling);
      cinemaVideo.removeEventListener("canplaythrough", onVideoReady);
      logo?.removeEventListener("ended", onLogoEnded);
      logo?.removeEventListener("timeupdate", watchLogoTail);

      if (bar) bar.style.width = "100%";
      root.classList.add("is-done");
      document.body.classList.remove("is-loading");

      root.addEventListener(
        "transitionend",
        () => {
          if (logo) logo.pause();
          root.remove();
        },
        { once: true }
      );

      resolve();
    };

    const maybeFinish = () => {
      if (logoDone && videoDone) finish();
    };

    const onLogoEnded = () => {
      logoDone = true;
      maybeFinish();
    };

    // Alguns navegadores não disparam "ended" com o vídeo em loop de decode;
    // ao chegar no fim, agenda o fallback.
    const watchLogoTail = () => {
      if (!logo.duration || endedTimer) return;
      if (logo.duration - logo.currentTime < 0.25) {
        endedTimer = setTimeout(onLogoEnded, ENDED_FALLBACK_MS);
      }
    };

    const onVideoReady = () => {
      videoDone = true;
      maybeFinish();
    };

    const ticker = setInterval(progress, 120);

    if (logo) {
      logo.addEventListener("ended", onLogoEnded, { once: true });
      logo.addEventListener("timeupdate", watchLogoTail);
    }

    if (cinemaVideo.readyState >= 3) onVideoReady();
    else cinemaVideo.addEventListener("canplaythrough", onVideoReady);

    const ceiling = setTimeout(finish, MAX_WAIT_MS);
  });
}
