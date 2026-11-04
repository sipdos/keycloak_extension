// =====================================================
// KeyCloak - Content Script
// Intercepta eventos copy/paste en la página.
// =====================================================

(() => {
  // ---------- COPY ----------
  document.addEventListener('copy', async (e) => {
    try {
      const sel = window.getSelection();
      if (!sel || sel.isCollapsed) return;
      const original = sel.toString();
      if (!original) return;

      const response = await chrome.runtime.sendMessage({
        type: 'COPY',
        text: original
      });

      if (response && response.changed) {
        e.preventDefault();
        e.clipboardData.setData('text/plain', response.text);
      }
    } catch (err) {
      console.warn('[KeyCloak] copy error', err);
    }
  }, true);

  // ---------- PASTE ----------
  document.addEventListener('paste', async (e) => {
    try {
      const clip = (e.clipboardData || window.clipboardData);
      if (!clip) return;
      const original = clip.getData('text/plain');
      if (!original) return;

      const response = await chrome.runtime.sendMessage({
        type: 'PASTE',
        text: original
      });

      if (response && response.changed) {
        e.preventDefault();
        // Insertar texto restaurado en el elemento activo
        const target = document.activeElement;
        if (target && (target.isContentEditable ||
            ['INPUT', 'TEXTAREA'].includes(target.tagName))) {
          insertText(target, response.text);
        }
      }
    } catch (err) {
      console.warn('[KeyCloak] paste error', err);
    }
  }, true);

  function insertText(el, text) {
    if (el.isContentEditable) {
      document.execCommand('insertText', false, text);
    } else {
      const start = el.selectionStart ?? el.value.length;
      const end = el.selectionEnd ?? el.value.length;
      el.value = el.value.slice(0, start) + text + el.value.slice(end);
      el.selectionStart = el.selectionEnd = start + text.length;
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
    }
  }
})();
