// =====================================================
// KeyCloak - Background (Service Worker)
// Gestiona el mapeo reversible entre claves originales
// y sus versiones ofuscadas.
// =====================================================

const STORAGE_KEY = 'keycloak_map';
const MAX_MAP_SIZE = 500; // Evita crecimiento infinito

// Patrones para detectar claves/tokens/API keys
const PATTERNS = [
  // JWT
  /\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b/g,
  // AWS Access Key
  /\bAKIA[0-9A-Z]{16}\b/g,
  // GitHub tokens
  /\b(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36,}\b/g,
  // Stripe
  /\b(sk|pk)_(live|test)_[0-9A-Za-z]{24,}\b/g,
  // Google API
  /\bAIza[0-9A-Za-z\-_]{35}\b/g,
  // Slack tokens
  /\bxox[baprs]-[0-9A-Za-z\-]{10,}\b/g,
  // Generic Bearer
  /\bBearer\s+[A-Za-z0-9._\-]{20,}\b/g,
  // Generic "token=..." o "api_key=..."
  /(?:token|api_?key|secret|password|auth)\s*[:=]\s*["']?([A-Za-z0-9_\-\.]{16,})["']?/gi,
  // Hex strings largos (32+ chars)
  /\b[0-9a-fA-F]{32,}\b/g,
  // Base64-like largos
  /\b[A-Za-z0-9+\/]{32,}={0,2}\b/g
];

// ---------- Utilidades ----------

function detectKeys(text) {
  const matches = new Set();
  for (const pattern of PATTERNS) {
    // Clonamos el regex porque tienen flag global
    const re = new RegExp(pattern.source, pattern.flags);
    let m;
    while ((m = re.exec(text)) !== null) {
      // Si el patrón tiene grupo capturador, usar el grupo; si no, el match completo
      const value = m[1] !== undefined ? m[1] : m[0];
      if (value && value.length >= 16) {
        matches.add(value);
      }
    }
  }
  return Array.from(matches);
}

function isOnlyOneKeyIsolated(text, keys) {
  // Si hay exactamente 1 clave y el texto es prácticamente esa clave,
  // no aplicamos ofuscación.
  if (keys.length !== 1) return false;
  const trimmed = text.trim();
  const key = keys[0];
  // Permitimos pequeños prefijos/sufijos (Bearer , comillas, etc.)
  const normalized = trimmed.replace(/^["'\s]+|["'\s]+$/g, '')
                            .replace(/^Bearer\s+/i, '');
  return normalized === key;
}

function obfuscate(value) {
  // Reemplaza cada carácter alfanumérico alternando X y x.
  // Los símbolos (-, _, .) se mantienen para que el formato sea reconocible.
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

// ---------- Mapeo en storage ----------

async function getMap() {
  const data = await chrome.storage.local.get(STORAGE_KEY);
  return data[STORAGE_KEY] || {};
}

async function saveMap(map) {
  // Limitar tamaño
  const keys = Object.keys(map);
  if (keys.length > MAX_MAP_SIZE) {
    const toRemove = keys.slice(0, keys.length - MAX_MAP_SIZE);
    for (const k of toRemove) delete map[k];
  }
  await chrome.storage.local.set({ [STORAGE_KEY]: map });
}

// ---------- Lógica principal ----------

export async function processCopy(text) {
  const keys = detectKeys(text);

  // Si no hay claves o solo hay una clave aislada → no tocar
  if (keys.length === 0) return { text, changed: false };
  if (isOnlyOneKeyIsolated(text, keys)) return { text, changed: false };

  // Ofuscar cada clave
  const map = await getMap();
  let result = text;
  let changed = false;

  for (const key of keys) {
    const obf = obfuscate(key);
    // Solo reemplazamos si realmente hay algo que cambiar
    if (obf !== key) {
      // Reemplazo global de esa clave específica
      const escaped = key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      result = result.replace(new RegExp(escaped, 'g'), obf);
      map[obf] = key; // Guardamos: ofuscado -> original
      changed = true;
    }
  }

  if (changed) await saveMap(map);
  return { text: result, changed };
}

export async function processPaste(text) {
  const map = await getMap();
  let result = text;
  let changed = false;

  // Ordenamos por longitud descendente para evitar colisiones parciales
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

export async function clearMap() {
  await chrome.storage.local.remove(STORAGE_KEY);
}

export async function getStats() {
  const map = await getMap();
  return { entries: Object.keys(map).length };
}

// ---------- Mensajes desde content/popup ----------

chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  (async () => {
    try {
      if (msg.type === 'COPY') {
        const r = await processCopy(msg.text);
        sendResponse(r);
      } else if (msg.type === 'PASTE') {
        const r = await processPaste(msg.text);
        sendResponse(r);
      } else if (msg.type === 'CLEAR') {
        await clearMap();
        sendResponse({ ok: true });
      } else if (msg.type === 'STATS') {
        const s = await getStats();
        sendResponse(s);
      }
    } catch (e) {
      console.error('[KeyCloak]', e);
      sendResponse({ error: e.message });
    }
  })();
  return true; // Indica respuesta asíncrona
});