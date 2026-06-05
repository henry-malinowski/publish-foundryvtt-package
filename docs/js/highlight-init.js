// Syntax-highlight the workflow snippet using a self-hosted minimal build of
// highlight.js (core + YAML only, v11.11.1 — see ../vendor/highlight/LICENSE). Loaded as
// a module, so it's deferred and runs after the DOM is parsed. Purely additive:
// if anything here fails, the <pre> still shows plain, readable YAML.

import hljs from "../vendor/highlight/core.min.js";
import yaml from "../vendor/highlight/yaml.min.js";

hljs.registerLanguage("yaml", yaml);

// Highlight every snippet, including the toggle's hidden one — highlightElement
// works on hidden elements, so a snippet is already styled when it's revealed.
document.querySelectorAll(".snippet code.language-yaml").forEach((block) => {
  hljs.highlightElement(block);
});
