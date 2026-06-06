// Progressive enhancement: toggle the setup snippet between the single-job and
// split build/publish layouts. The control starts `hidden` and is revealed here,
// so with JS off the single-job <pre> is the visible default and the split one
// stays hidden — the page still shows one complete, copyable example.
//
// Swapping panes used to be an instant `hidden` flip, which made the snippet
// jump (the split layout is taller). Instead we morph the figure's height and
// fade the incoming pane up, so the swap reads as one continuous motion.

import { animate } from "../vendor/anime/anime.esm.min.js";

const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

const toggle = document.querySelector(".snippet-toggle");

if (toggle) {
  const buttons = toggle.querySelectorAll(".snippet-toggle__btn");
  const panes = document.querySelectorAll("[data-snippet]");
  const copyBtn = document.querySelector(".copy-btn[data-copy-target]");
  const figure = toggle.parentElement.querySelector(".snippet");

  // Sliding active indicator. Created here (not in markup) because it's only
  // meaningful once JS drives the control — which is also the only time the
  // control is shown. It sits behind the labels; see .snippet-toggle__thumb.
  const thumb = document.createElement("span");
  thumb.className = "snippet-toggle__thumb";
  toggle.prepend(thumb);

  // Pin the thumb to a button's box. Measured against the toggle (its offset
  // parent), so this must run after the control is visible (offsetWidth is 0
  // while [hidden]). `animateMove` tweens it; otherwise it snaps (init/resize).
  const moveThumb = (btn, animateMove) => {
    const box = {
      left: btn.offsetLeft,
      top: btn.offsetTop,
      width: btn.offsetWidth,
      height: btn.offsetHeight,
    };
    if (animateMove) {
      animate(thumb, { ...box, duration: 280, ease: "outExpo" });
    } else {
      Object.assign(thumb.style, {
        left: `${box.left}px`,
        top: `${box.top}px`,
        width: `${box.width}px`,
        height: `${box.height}px`,
      });
    }
  };

  toggle.hidden = false; // reveal the control now that JS can drive it
  moveThumb(toggle.querySelector(".is-active"), false); // place it before paint

  // Keep the thumb aligned if the buttons reflow (font swap, viewport resize).
  window.addEventListener("resize", () => {
    moveThumb(toggle.querySelector(".is-active"), false);
  });

  // Swap which pane is shown and repoint the copy button + tab state. Returns
  // the newly visible pane (or null if it was already current).
  const swap = (targetId) => {
    let next = null;
    panes.forEach((pane) => {
      const show = pane.dataset.snippet === targetId;
      if (show && pane.hidden) next = pane;
      pane.hidden = !show;
    });
    buttons.forEach((btn) => {
      const active = btn.dataset.snippetTarget === targetId;
      btn.classList.toggle("is-active", active);
      btn.setAttribute("aria-selected", active ? "true" : "false");
    });
    // Repoint the copy button at the visible snippet; copy.js resolves the
    // target at click time, so this takes effect immediately.
    if (copyBtn) copyBtn.dataset.copyTarget = `#${targetId}`;
    return next;
  };

  const select = (targetId) => {
    // Measure → swap → measure, then animate the figure between the two heights
    // while the incoming pane fades up. Pin overflow so taller content doesn't
    // spill before the box has grown to fit it.
    const fromHeight = figure ? figure.offsetHeight : 0;
    const next = swap(targetId);
    if (!next) return; // already showing this layout — nothing to do

    // Slide the active indicator to the newly selected button.
    moveThumb(toggle.querySelector(".is-active"), !reduceMotion);

    if (reduceMotion || !figure) return;
    const toHeight = figure.offsetHeight;

    figure.style.overflow = "hidden";
    animate(figure, {
      height: [fromHeight, toHeight],
      duration: 320,
      ease: "outExpo",
      onComplete: () => {
        figure.style.height = "";
        figure.style.overflow = "";
      },
    });
    animate(next, {
      opacity: [0, 1],
      translateY: [8, 0],
      duration: 280,
      ease: "outExpo",
    });
  };

  buttons.forEach((btn) => {
    btn.addEventListener("click", () => select(btn.dataset.snippetTarget));
  });
}
