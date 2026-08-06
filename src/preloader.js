const MIN_VISIBLE_MS = 1500;
const MAX_WAIT_MS = 9000;

/**
 * Segura a página com a animação da marca até o vídeo da experiência ter
 * dados suficientes para o scrub. Resolve sempre — nunca prende o visitante.
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
    const startedAt = performance.now();
    let finished = false;

    const progress = () => {
      if (!bar) return;
      let ratio = cinemaVideo.readyState / 4;
      if (cinemaVideo.buffered.length && cinemaVideo.duration) {
        ratio = Math.max(ratio, cinemaVideo.buffered.end(0) / cinemaVideo.duration);
      }
      const elapsed = (performance.now() - startedAt) / MIN_VISIBLE_MS;
      bar.style.width = `${Math.min(100, Math.max(ratio, elapsed) * 100)}%`;
    };

    const finish = () => {
      if (finished) return;
      finished = true;
      clearInterval(ticker);
      cinemaVideo.removeEventListener("canplaythrough", ready);

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

    const ready = () => {
      const remaining = MIN_VISIBLE_MS - (performance.now() - startedAt);
      setTimeout(finish, Math.max(0, remaining));
    };

    const ticker = setInterval(progress, 120);

    if (cinemaVideo.readyState >= 3) ready();
    else cinemaVideo.addEventListener("canplaythrough", ready);

    setTimeout(finish, MAX_WAIT_MS);
  });
}
