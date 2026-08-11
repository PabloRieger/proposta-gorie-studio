import "./style.css";

import gsap from "gsap";
import ScrollTrigger from "gsap/ScrollTrigger";
import Lenis from "lenis";

import { buildWhatsAppLink } from "./config.js";
import { initCinemaScroll } from "./cinema-scroll.js";
import { runPreloader } from "./preloader.js";

gsap.registerPlugin(ScrollTrigger);

const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

// ---------------------------------------------------------------- WhatsApp
function wireWhatsApp() {
  document.querySelectorAll("[data-whatsapp]").forEach((el) => {
    const message = el.dataset.waMessage || "";
    el.setAttribute("href", buildWhatsAppLink(message));
    el.setAttribute("target", "_blank");
    el.setAttribute("rel", "noopener noreferrer");
  });
}

// --------------------------------------------------------------------- Nav
function wireNav(lenis) {
  const nav = document.querySelector("[data-nav]");
  const toggle = document.querySelector("[data-nav-toggle]");
  const mobile = document.querySelector("[data-nav-mobile]");
  if (!nav) return;

  const lightZones = Array.from(document.querySelectorAll(".manifesto, .footer"));
  const flood = document.querySelector("[data-cinema-flood]");
  let zoneBounds = [];

  const measureZones = () => {
    zoneBounds = lightZones.map((zone) => {
      const r = zone.getBoundingClientRect();
      const top = r.top + window.scrollY;
      return [top, top + r.height];
    });
  };

  const onScroll = () => {
    nav.classList.toggle("is-scrolled", window.scrollY > 40);

    const probe = window.scrollY + nav.offsetHeight * 0.6;
    const overLight = zoneBounds.some(([top, bottom]) => probe >= top && probe < bottom);
    const floodCovering = flood && Number(gsap.getProperty(flood, "opacity")) > 0.55;

    nav.classList.toggle("is-light", overLight || floodCovering);
  };

  measureZones();
  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });
  window.addEventListener("resize", measureZones);
  ScrollTrigger.addEventListener("refresh", measureZones);
  gsap.ticker.add(onScroll);

  const closeMenu = () => {
    nav.classList.remove("is-open");
    toggle?.setAttribute("aria-expanded", "false");
  };

  toggle?.addEventListener("click", () => {
    const open = nav.classList.toggle("is-open");
    toggle.setAttribute("aria-expanded", String(open));
  });

  mobile?.querySelectorAll("a").forEach((a) => a.addEventListener("click", closeMenu));

  // âncoras internas via Lenis para o mesmo easing do resto da página
  document.querySelectorAll('a[href^="#"]').forEach((link) => {
    link.addEventListener("click", (event) => {
      const id = link.getAttribute("href");
      if (!id || id === "#") return;
      const target = document.querySelector(id);
      if (!target) return;
      event.preventDefault();
      closeMenu();
      if (lenis) {
        lenis.scrollTo(target, { offset: -70 });
      } else {
        target.scrollIntoView({ behavior: "smooth" });
      }
    });
  });
}

// ------------------------------------------------------- Botão flutuante
function wireFloatingCta() {
  const float = document.querySelector("[data-wa-float]");
  const spacer = document.querySelector("[data-cinema-spacer]");
  const footer = document.querySelector(".footer");
  if (!float || !spacer) return;

  const update = () => {
    const pastCinema = window.scrollY > spacer.offsetHeight - window.innerHeight * 0.5;
    const atFooter = footer.getBoundingClientRect().top < window.innerHeight - 40;
    float.classList.toggle("is-visible", pastCinema && !atFooter);
  };

  update();
  window.addEventListener("scroll", update, { passive: true });
  window.addEventListener("resize", update);
}

// ------------------------------------------------------------ Reveal geral
function wireReveals() {
  const candidates = document.querySelectorAll(
    ".section .eyebrow, .section__title, .service-card, .process__list li, .offer__hero, .offer__subtitle, .plan-card, .offer__footnote, .pillar, .contact__text, .contact .btn, .contact__meta"
  );

  candidates.forEach((el) => el.setAttribute("data-reveal", ""));

  if (prefersReducedMotion) {
    candidates.forEach((el) => el.classList.add("is-visible"));
    return;
  }

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.style.transitionDelay = `${(Number(entry.target.dataset.revealIndex) || 0) * 70}ms`;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    },
    { rootMargin: "0px 0px -12% 0px", threshold: 0.08 }
  );

  // stagger dentro de cada grid
  document.querySelectorAll(".services__grid, .plans, .pillars__grid").forEach((grid) => {
    Array.from(grid.children).forEach((child, i) => {
      child.dataset.revealIndex = String(i);
    });
  });

  candidates.forEach((el) => observer.observe(el));
}

// ------------------------------------------------------------------- Lenis
function initLenis() {
  if (prefersReducedMotion) return null;

  const lenis = new Lenis({
    duration: 1.05,
    easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
    smoothWheel: true,
    syncTouch: false,
  });

  lenis.on("scroll", ScrollTrigger.update);

  gsap.ticker.add((time) => {
    lenis.raf(time * 1000);
  });
  gsap.ticker.lagSmoothing(0);

  if (import.meta.env.DEV) window.__lenis = lenis;

  return lenis;
}

// -------------------------------------------------------------------- Boot
function boot() {
  document.querySelector("[data-year]").textContent = String(new Date().getFullYear());

  wireWhatsApp();

  const lenis = initLenis();
  wireNav(lenis);
  wireFloatingCta();
  wireReveals();

  const cinema = initCinemaScroll();

  runPreloader(cinema).then(() => {
    ScrollTrigger.refresh();
    gsap.to("[data-intro]", {
      opacity: 1,
      y: 0,
      filter: "blur(0px)",
      duration: 1.1,
      ease: "power3.out",
      stagger: 0.14,
      delay: 0.1,
    });
  });

  window.addEventListener("pagehide", () => {
    cinema.destroy();
    lenis?.destroy();
  });
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", boot);
} else {
  boot();
}
