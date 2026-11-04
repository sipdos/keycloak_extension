# 🔐 KeyCloak — Ofuscación reversible de claves al copiar/pegar

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Chrome](https://img.shields.io/badge/Chrome-MV3-brightgreen.svg)
![Opera](https://img.shields.io/badge/Opera-MV3-red.svg)
![Firefox](https://img.shields.io/badge/Firefox-experimental-orange.svg)

**Evita pegar tus contraseñas, tokens y API keys en LLMs públicos, chats o tickets.**
KeyCloak detecta credenciales en el texto que copias, las sustituye por una versión ofuscada en el portapapeles y guarda localmente el mapeo para poder restaurarlas cuando tú las necesites.

---

## ✨ Características

- 🔍 **Detección automática** de claves, tokens y API keys en el texto copiado.
- 🔒 **Ofuscación reversible**: cada carácter alfanumérico se sustituye por `X` / `x` alternados (los separadores como `_`, `-` o `.` se conservan).
- 💾 **Mapeo local** ofuscado → original en `chrome.storage.local` (máx. 500 entradas; las más antiguas se descartan).
- 🔄 **Restauración automática** al pegar texto ofuscado en un campo del navegador.
- ⚠️ **Clave aislada = sin cambios**: si copias *solo* una clave, se deja tal cual (asume que la quieres usar).
- 🔐 **100 % local**: sin servidores, sin tracking, sin analíticas.

---

## 🎯 Cómo funciona

### 1. Copias texto que contiene claves → se ofuscan

```text
Original:      Mi API key es AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q y el token ghp_1234567890ABCDEFGHIJKLMNOPQRSTUVWXyz
Portapapeles:  Mi API key es XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX y el token XxX_xXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX
```

### 2. Copias una clave sola → no se toca

```text
Original:      AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q
Portapapeles:  AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q   (sin cambios)
```

### 3. Pegas texto ofuscado en el navegador → se restaura

```text
Portapapeles:  XxX_xXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX
Pegado:        ghp_1234567890ABCDEFGHIJKLMNOPQRSTUVWXyz
```

La restauración solo ocurre en campos `<input>`, `<textarea>` y elementos `contenteditable` de páginas donde la extensión está activa. Fuera del navegador el texto sigue ofuscado.

---

## 📥 Instalación

> **Nota:** el repositorio no incluye `manifest.json` ni la carpeta `icons/`. Ambos los genera `build.sh`, que crea la carpeta `keycloak-extension/` con la extensión completa lista para cargar.

### 1. Generar la extensión

```bash
git clone https://github.com/sipdos/keycloak_extension.git
cd keycloak_extension
chmod +x build.sh
./build.sh
```

En Windows ejecuta `build.sh` con **Git Bash** o **WSL** (`build.ps1` todavía es solo un esqueleto).

### 2. Cargarla en el navegador

**Chrome / Opera / Edge / Brave**

1. Abre `chrome://extensions` (Opera: `opera://extensions`).
2. Activa **Modo desarrollador**.
3. Pulsa **Cargar descomprimida** y selecciona la carpeta `keycloak-extension/`.

**Firefox** (experimental)

1. Abre `about:debugging#/runtime/this-firefox`.
2. Pulsa **Cargar complemento temporal…** y selecciona `keycloak-extension/manifest.json`.
3. El complemento se descarga al cerrar Firefox. Para instalarlo de forma permanente hay que firmarlo en [addons.mozilla.org](https://addons.mozilla.org).

### 3. Empaquetar (opcional)

```bash
cd keycloak-extension && zip -r ../keycloak-extension.zip . && cd ..
```

```powershell
Compress-Archive -Path keycloak-extension\* -DestinationPath keycloak-extension.zip
```

---

## 🔍 Claves detectadas

| Tipo | Ejemplo |
|------|---------|
| JWT | `eyJhbGciOiJIUzI1NiIs...` (3 segmentos) |
| AWS Access Key | `AKIA` + 16 caracteres |
| GitHub token | `ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_` + 36+ caracteres |
| Stripe | `sk_live_…`, `sk_test_…`, `pk_live_…`, `pk_test_…` |
| Google API Key | `AIza` + 35 caracteres |
| Slack token | `xoxb-…`, `xoxa-…`, `xoxp-…`, `xoxr-…`, `xoxs-…` |
| Bearer | `Bearer <token de 20+ caracteres>` |
| Genérico clave=valor | `token=`, `api_key=`, `apikey:`, `secret=`, `password:`, `auth=` + valor de 16+ caracteres |
| Hexadecimal | cadenas hex de 32+ caracteres |
| Base64 | cadenas tipo Base64 de 32+ caracteres |

Las coincidencias de menos de **16 caracteres** se ignoran para reducir falsos positivos.

---

## 🛠️ Desarrollo

### Estructura del repositorio

```text
keycloak_extension/
├── background.js   # Service worker: detección, ofuscación y mapeo
├── content.js      # Intercepta los eventos copy / paste
├── popup.html      # Interfaz del popup
├── popup.js        # Lógica del popup (contador y limpiar memoria)
├── popup.css       # Estilos del popup
├── build.sh        # Genera keycloak-extension/ (manifest, iconos y código)
├── build.ps1       # Esqueleto para Windows (pendiente)
├── LICENSE
└── README.md
```

### Popup

- **Claves en memoria**: número de mapeos guardados.
- **🗑️ Limpiar memoria**: borra todos los mapeos. Tras limpiar, el texto ofuscado ya no se podrá restaurar.

### Personalización (en `background.js`)

Añadir patrones de detección:

```javascript
const PATTERNS = [
  /\bMI_PATRON_[A-Za-z0-9]{20,}\b/g,
  // ...
];
```

Cambiar el estilo de ofuscación:

```javascript
function obfuscate(value) {
  return value.replace(/[A-Za-z0-9]/g, '*');
}
```

Ajustar el límite de memoria:

```javascript
const MAX_MAP_SIZE = 1000;
```

> `build.sh` contiene su propia copia de los archivos. Si cambias el código en la raíz, replica el cambio en `build.sh` o copia los archivos a `keycloak-extension/` después de generarla.

---

## 🔒 Privacidad

- Todo se procesa en el navegador; no hay peticiones a servidores externos.
- El mapeo se guarda en `chrome.storage.local`, accesible solo para la extensión.
- Ojo: ese mapeo contiene tus **claves reales en texto plano** dentro del perfil del navegador. Usa **Limpiar memoria** cuando ya no lo necesites.

---

## 🐛 Problemas conocidos

- **Firefox**: el manifest usa `background.service_worker` (MV3 de Chrome). Firefox puede requerir `background.scripts` para cargar el service worker.
- **Firefox**: los complementos temporales se descargan al reiniciar.
- **Sitios que bloquean copy/paste**: algunas webs interceptan esos eventos antes que la extensión.
- **Claves cortas** (< 16 caracteres): no se detectan, de forma intencionada.

---

## 🤝 Contribuciones

1. Haz un fork del repositorio.
2. Crea una rama: `git checkout -b feature/nueva-funcionalidad`
3. Haz commit: `git commit -m "Añade nueva funcionalidad"`
4. Sube la rama: `git push origin feature/nueva-funcionalidad`
5. Abre un Pull Request.

Ideas: más patrones (wallets, IBAN…), notificaciones al ofuscar/restaurar, lista de claves en el popup, exportar/importar el mapeo, autolimpieza de entradas antiguas, `build.ps1` funcional.

---

## 📝 Licencia

MIT — ver [LICENSE](LICENSE).

---

> ⚠️ **Aviso:** KeyCloak es una capa extra de protección, no sustituye las buenas prácticas de gestión de secretos. Rota cualquier credencial que sospeches que se ha expuesto.
