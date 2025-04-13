import { codeToHtml } from 'https://esm.sh/shiki@1.0.0';

window.renderShiki = async function (elementId, code, lang = 'javascript', theme = 'rose-pine') {
  const element = document.getElementById(elementId);
  if (!element) {
    console.error(`Element with ID "${elementId}" not found.`);
    return;
  }
  element.innerHTML = await codeToHtml(code, { lang, theme });
};
