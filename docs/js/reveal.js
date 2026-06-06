// Progressive enhancement: fade/rise each section in as it scrolls into view,
// with a light stagger for grouped content (hero, cards, steps).
//
// The `js-reveal` class is added to <html> by an inline head script (before
// paint) and the reveal hooks live in the markup, so: with JS off nothing is
// hidden, and with JS on the hidden-start styles apply before first paint (no
// flash). This script only decides *when* — and how — each reveal plays.
//
// anime.js owns the motion; the IntersectionObserver is just the trigger. On
// completion we hand the resting state back to CSS (`.is-visible`) and strip
// anime's inline styles, so nothing lingers to fight the scroll-driven hero
// parallax (which also animates transform on the glyph).

import { animate, stagger, utils } from "../vendor/anime/anime.esm.min.js";

const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

// Two kinds of reveal share one observer:
//  - `.reveal`            → the element itself rises in as one block.
//  - `[data-reveal-stagger]` → its `.reveal-item` descendants cascade in; the
//                              container itself is not hidden (see style.css).
const blocks = [...document.querySelectorAll(".reveal")].map((el) => ({
  el,
  items: [el],
}));
const groups = [...document.querySelectorAll("[data-reveal-stagger]")].map((el) => ({
  el,
  items: [...el.querySelectorAll(".reveal-item")],
}));
const entries = [...blocks, ...groups];

const settle = (items) => {
  for (const item of items) item.classList.add("is-visible");
};

if (entries.length) {
  if (reduceMotion || !("IntersectionObserver" in window)) {
    // No animation wanted (or no observer support): just show everything. The
    // reduced-motion CSS already neutralises the hidden-start styles, so this is
    // mostly belt-and-braces.
    for (const { items } of entries) settle(items);
  } else {
    const byEl = new Map(entries.map((entry) => [entry.el, entry]));

    const observer = new IntersectionObserver(
      (records, obs) => {
        for (const record of records) {
          if (!record.isIntersecting) continue;
          obs.unobserve(record.target); // reveal once, then stop watching

          const { items } = byEl.get(record.target);
          animate(items, {
            opacity: [0, 1],
            translateY: [16, 0],
            duration: 650,
            ease: "outExpo",
            // A single block (items.length === 1) gets delay 0; groups cascade.
            delay: stagger(80),
            onComplete: (self) => {
              // Hand the resting state to CSS and drop anime's inline styles so
              // no leftover transform/opacity competes with later animations.
              settle(items);
              utils.cleanInlineStyles(self);
            },
          });
        }
      },
      { rootMargin: "0px 0px -10% 0px", threshold: 0.1 }
    );

    for (const { el } of entries) observer.observe(el);
  }
}

// Hero glyph entrance: trace the cloud perimeter, then lift the arrow into place
// as it fades up. The hero sits above the fold, so this just plays on load. The
// `.js-reveal` gate (style.css) hides the cloud/arrow before this runs; under
// reduced-motion that gate is neutralised to the finished icon, so we bail here.
const cloud = document.querySelector(".glyph-cloud");
const arrow = document.querySelector(".glyph-arrow");

if (cloud && arrow && !reduceMotion) {
  // Dash the stroke to its own length so offset 0 = fully drawn. We start from
  // -length so the trace runs left-to-right (toward the arrow), the reverse of
  // the path's own right-to-left authoring direction.
  const length = cloud.getTotalLength();
  cloud.style.strokeDasharray = length;
  cloud.style.strokeDashoffset = -length;

  animate(cloud, {
    strokeDashoffset: [-length, 0],
    duration: 720,
    ease: "inOutSine",
  });

  animate(arrow, {
    translateY: [3, 0],
    opacity: [0.6, 1],
    duration: 520,
    delay: 380, // arrives just as the cloud finishes tracing
    ease: "outExpo",
  });
}
