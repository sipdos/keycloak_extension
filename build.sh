#!/bin/bash
set -e

PROJECT="keycloak-extension"
mkdir -p "$PROJECT/icons"

# ---------- manifest.json ----------
cat > "$PROJECT/manifest.json" << 'EOF'
{
  "manifest_version": 3,
  "name": "KeyCloak - Key Reversible Offuscator",
  "version": "1.0.0",
  "description": "Ofusca claves/tokens/API keys al copiar y las restaura al pegar. Compatible con Chrome, Firefox y Opera.",
  "permissions": ["storage", "clipboardRead", "clipboardWrite", "activeTab"],
  "host_permissions": ["<all_urls>"],
  "background": {
    "service_worker": "background.js"
  },
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["content.js"],
      "run_at": "document_start",
      "all_frames": true
    }
  ],
  "action": {
    "default_popup": "popup.html",
    "default_title": "KeyCloak",
    "default_icon": {
      "16": "icons/icon16.svg",
      "48": "icons/icon48.svg",
      "128": "icons/icon128.svg"
    }
  },
  "icons": {
    "16": "icons/icon16.svg",
    "48": "icons/icon48.svg",
    "128": "icons/icon128.svg"
  },
  "browser_specific_settings": {
    "gecko": {
      "id": "keycloak@example.com",
      "strict_min_version": "109.0"
    }
  }
}
EOF

# ---------- background.js ----------
cat > "$PROJECT/background.js" << 'EOF'
// =====================================================
// KeyCloak - Background (Service Worker)
// =====================================================

const STORAGE_KEY = 'keycloak_map';
const MAX_MAP_SIZE = 500;

const PATTERNS = [
  /\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b/g,
  /\bAKIA[0-9A-Z]{16}\b/g,
  /\b(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36,}\b/g,
  /\b(sk|pk)_(live|test)_[0-9A-Za-z]{24,}\b/g,
  /\bAIza[0-9A-Za-z\-_]{35}\b/g,
  /\bxox[baprs]-[0-9A-Za-z\-]{10,}\b/g,
  /\bBearer\s+[A-Za-z0-9._\-]{20,}\b/g,
  /(?:token|api_?key|secret|password|auth)\s*[:=]\s*["']?([A-Za-z0-9_\-\.]{16,})["']?/gi,
  /\b[0-9a-fA-F]{32,}\b/g,
  /\b[A-Za-z0-9+\/]{32,}={0,2}\b/g
];

function detectKeys(text) {
  const matches = new Set();
  for (const pattern of PATTERNS) {
    const re = new RegExp(pattern.source, pattern.flags);
    let m;
    while ((m = re.exec(text)) !== null) {
      const value = m[1] !== undefined ? m[1] : m[0];
      if (value && value.length >= 16) matches.add(value);
    }
  }
  return Array.from(matches);
}

function isOnlyOneKeyIsolated(text, keys) {
  if (keys.length !== 1) return false;
  const trimmed = text.trim();
  const key = keys[0];
  const normalized = trimmed.replace(/^["'\s]+|["'\s]+$/g, '')
                            .replace(/^Bearer\s+/i, '');
  return normalized === key;
}

function obfuscate(value) {
  let toggle = false;
  let out = '';
  for (const ch of value) {
    if (/[A-Za-z0-9]/.test(ch)) {
      out += toggle ? 'x' : 'X';
      toggle = !toggle;
    } else {
      out += ch;
    }
  }
  return out;
}

async function getMap() {
  const data = await chrome.storage.local.get(STORAGE_KEY);
  return data[STORAGE_KEY] || {};
}

async function saveMap(map) {
  const keys = Object.keys(map);
  if (keys.length > MAX_MAP_SIZE) {
    const toRemove = keys.slice(0, keys.length - MAX_MAP_SIZE);
    for (const k of toRemove) delete map[k];
  }
  await chrome.storage.local.set({ [STORAGE_KEY]: map });
}

async function processCopy(text) {
  const keys = detectKeys(text);
  if (keys.length === 0) return { text, changed: false };
  if (isOnlyOneKeyIsolated(text, keys)) return { text, changed: false };

  const map = await getMap();
  let result = text;
  let changed = false;

  for (const key of keys) {
    const obf = obfuscate(key);
    if (obf !== key) {
      const escaped = key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      result = result.replace(new RegExp(escaped, 'g'), obf);
      map[obf] = key;
      changed = true;
    }
  }

  if (changed) await saveMap(map);
  return { text: result, changed };
}

async function processPaste(text) {
  const map = await getMap();
  let result = text;
  let changed = false;

  const entries = Object.entries(map).sort((a, b) => b[0].length - a[0].length);
  for (const [obf, original] of entries) {
    if (result.includes(obf)) {
      const escaped = obf.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      result = result.replace(new RegExp(escaped, 'g'), original);
      changed = true;
    }
  }
  return { text: result, changed };
}

async function clearMap() {
  await chrome.storage.local.remove(STORAGE_KEY);
}

async function getStats() {
  const map = await getMap();
  return { entries: Object.keys(map).length };
}

chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  (async () => {
    try {
      if (msg.type === 'COPY') sendResponse(await processCopy(msg.text));
      else if (msg.type === 'PASTE') sendResponse(await processPaste(msg.text));
      else if (msg.type === 'CLEAR') { await clearMap(); sendResponse({ ok: true }); }
      else if (msg.type === 'STATS') sendResponse(await getStats());
    } catch (e) {
      console.error('[KeyCloak]', e);
      sendResponse({ error: e.message });
    }
  })();
  return true;
});
EOF

# ---------- content.js ----------
cat > "$PROJECT/content.js" << 'EOF'
(() => {
  document.addEventListener('copy', async (e) => {
    try {
      const sel = window.getSelection();
      if (!sel || sel.isCollapsed) return;
      const original = sel.toString();
      if (!original) return;

      const response = await chrome.runtime.sendMessage({ type: 'COPY', text: original });
      if (response && response.changed) {
        e.preventDefault();
        e.clipboardData.setData('text/plain', response.text);
      }
    } catch (err) {
      console.warn('[KeyCloak] copy error', err);
    }
  }, true);

  document.addEventListener('paste', async (e) => {
    try {
      const clip = e.clipboardData || window.clipboardData;
      if (!clip) return;
      const original = clip.getData('text/plain');
      if (!original) return;

      const response = await chrome.runtime.sendMessage({ type: 'PASTE', text: original });
      if (response && response.changed) {
        e.preventDefault();
        const target = document.activeElement;
        if (target && (target.isContentEditable || ['INPUT', 'TEXTAREA'].includes(target.tagName))) {
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
EOF

# ---------- popup.html ----------
cat > "$PROJECT/popup.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <link rel="stylesheet" href="popup.css">
</head>
<body>
  <h1>🔐 KeyCloak</h1>
  <p class="desc">Ofusca claves al copiar y las restaura al pegar.</p>
  <div class="stat">Claves en memoria: <strong id="count">0</strong></div>
  <div class="actions">
    <button id="clear">🗑️ Limpiar memoria</button>
  </div>
  <div class="status" id="status"></div>
  <script src="popup.js"></script>
</body>
</html>
EOF

# ---------- popup.js ----------
cat > "$PROJECT/popup.js" << 'EOF'
document.addEventListener('DOMContentLoaded', async () => {
  const countEl = document.getElementById('count');
  const statusEl = document.getElementById('status');
  const clearBtn = document.getElementById('clear');

  async function refresh() {
    const stats = await chrome.runtime.sendMessage({ type: 'STATS' });
    countEl.textContent = stats?.entries ?? 0;
  }

  clearBtn.addEventListener('click', async () => {
    await chrome.runtime.sendMessage({ type: 'CLEAR' });
    statusEl.textContent = '✅ Memoria limpiada';
    setTimeout(() => statusEl.textContent = '', 2000);
    refresh();
  });

  refresh();
});
EOF

# ---------- popup.css ----------
cat > "$PROJECT/popup.css" << 'EOF'
body { width: 280px; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; padding: 14px; color: #222; }
h1 { margin: 0 0 6px; font-size: 18px; }
.desc { font-size: 12px; color: #666; margin: 0 0 12px; }
.stat { background: #f4f4f4; padding: 10px; border-radius: 6px; font-size: 13px; margin-bottom: 10px; }
.actions { display: flex; gap: 6px; }
button { flex: 1; padding: 8px; border: 0; background: #2563eb; color: white; border-radius: 6px; cursor: pointer; font-size: 13px; }
button:hover { background: #1d4ed8; }
.status { margin-top: 8px; font-size: 12px; color: #16a34a; min-height: 16px; }
EOF

# ---------- Iconos SVG ----------
ICON_SVG='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128"><rect width="128" height="128" rx="20" fill="#2563eb"/><text x="64" y="88" font-size="80" text-anchor="middle" fill="white" font-family="Arial" font-weight="bold">🔐</text></svg>'
echo "$ICON_SVG" > "$PROJECT/icons/icon16.svg"
echo "$ICON_SVG" > "$PROJECT/icons/icon48.svg"
echo "$ICON_SVG" > "$PROJECT/icons/icon128.svg"

# ---------- README.md ----------
cat > "$PROJECT/README.md" << 'EOF'
# 🔐 KeyCloak - Extensión de ofuscación reversible de claves

Extensión WebExtension compatible con **Chrome**, **Firefox** y **Opera** que protege tus claves, tokens y API keys al copiar/pegar texto.

## ✨ Características

- 🔍 Detecta automáticamente claves, tokens y API keys en el texto copiado.
- 🔒 Ofusca las claves reemplazando caracteres alfanuméricos por `X` y `x` alternados.
- 💾 Guarda el mapeo en memoria local.
- 🔄 Al volver a pegar el texto ofuscado, lo restaura al original automáticamente.
- ⚠️ Si solo copias **una clave aislada**, **no la modifica**.

## 📥 Instalación

### Chrome / Opera
1. Descarga o clona este repositorio.
2. Abre `chrome://extensions` (o `opera://extensions`).
3. Activa **Modo desarrollador**.
4. Clic en **Cargar descomprimida** → selecciona la carpeta del proyecto.

### Firefox
1. Abre `about:debugging#/runtime/this-firefox`.
2. Clic en **Cargar complemento temporal** → selecciona `manifest.json`.
3. Para instalación permanente, firma el `.xpi` en [AMO](https://addons.mozilla.org).

## 🧪 Uso

1. Copia un bloque de texto que contenga **varias claves** o **texto + claves**.
2. La extensión ofusca las claves automáticamente al copiar.
3. Pégalo donde quieras (GitHub, chat, email...).
4. Cuando tú mismo vuelvas a copiar ese texto ofuscado y lo pegues en tu navegador, se restaura al original.

## 🛠️ Desarrollo

Estructura: