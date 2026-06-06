// Progressive enhancement: copy the workflow snippet to the clipboard.
// The <pre> is fully selectable without this script, so the page works with
// JavaScript disabled — this just adds a one-click convenience.

document.querySelectorAll(".copy-btn").forEach((button) => {
  button.addEventListener("click", async () => {
    // Resolved at click time, not load time, so the snippet toggle can repoint
    // data-copy-target at whichever snippet is currently visible.
    const target = document.querySelector(button.dataset.copyTarget);
    if (!target) {
      return;
    }

    try {
      await navigator.clipboard.writeText(target.textContent);
    } catch {
      return; // clipboard blocked (e.g. insecure context) — leave text to select
    }

    // Toggle state only — the "Copy"/"Copied" labels both live in the markup so
    // the button width is fixed and never reflows on click.
    button.classList.add("copied");
    window.setTimeout(() => {
      button.classList.remove("copied");
    }, 1500);
  });
});
