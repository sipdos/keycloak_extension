# 🔐 KeyCloak - Extensión de Ofuscación Reversible de Claves

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Chrome](https://img.shields.io/badge/Chrome-Compatible-brightgreen.svg)]()
[![Firefox](https://img.shields.io/badge/Firefox-Compatible-orange.svg)]()
[![Opera](https://img.shields.io/badge/Opera-Compatible-red.svg)]()

**Protege tus claves, tokens y API keys al copiar texto sensible.** KeyCloak detecta automáticamente credenciales en tu portapapeles, las ofusca para que puedas pegarlas de forma segura, y las restaura cuando tú las necesitas.

---

## ✨ Características

- 🔍 **Detección automática** de claves, tokens y API keys en el texto copiado
- 🔒 **Ofuscación reversible** reemplazando caracteres por `X` y `x` alternados
- 💾 **Memoria local** que guarda el mapeo entre claves originales y ofuscadas
- 🔄 **Restauración automática** al pegar texto ofuscado
- ⚠️ **Inteligente**: si solo copias una clave aislada, **no la modifica**
- 🌐 **Multi-navegador**: compatible con Chrome, Firefox y Opera
- 🔐 **100% privado**: todo se procesa localmente, sin servidores externos

---

## 🎯 ¿Cómo funciona?

### Escenario 1: Copias texto con múltiples claves
Texto original:
"Mi API key es AIza1234567890abcdefghijklmnopqrstuv y el token ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefgh"
↓ Al copiar (KeyCloak interviene)
Texto en portapapeles:
"Mi API key es XxXx1234567890XxXxXxXxXxXxXxXxXxXxXxXxXxXx y el token XxX_XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXx"

123
Texto original:
"AIza1234567890abcdefghijklmnopqrstuv"
↓ Al copiar (KeyCloak NO interviene)
Texto en portapapeles:
"AIza1234567890abcdefghijklmnopqrstuv" (sin cambios)

123
Texto en portapapeles:
"XxXx1234567890XxXxXxXxXxXxXxXxXxXxXxXxXxXx"
↓ Al pegar (KeyCloak restaura)
Texto pegado:
"AIza1234567890abcdefghijklmnopqrstuv"

---

## 📥 Instalación

### Google Chrome / Opera

1. Descarga o clona este repositorio:
   ```bash
   git clone https://github.com/TU_USUARIO/keycloak-extension.git
   cd keycloak-extension
Abre tu navegador y ve a:
Chrome: chrome://extensions
Opera: opera://extensions
Activa el Modo desarrollador (esquina superior derecha)
Haz clic en "Cargar descomprimida" o "Cargar extensión sin empaquetar"
Selecciona la carpeta keycloak-extension
¡Listo! El icono 🔐 aparecerá en tu barra de extensiones
Mozilla Firefox
Abre about:debugging#/runtime/this-firefox
Haz clic en "Cargar complemento temporal..."
Selecciona el archivo manifest.json de la carpeta del proyecto
La extensión se cargará hasta que reinicies Firefox
💡 Para instalación permanente en Firefox, necesitas firmar la extensión en Mozilla Add-ons
🧪 Uso
Paso 1: Copia texto con claves
Selecciona y copia texto que contenga múltiples claves o texto mixto (claves + texto normal):
Configuración:
- API Key: AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6
- Token: ghp_1234567890ABCDEFGHIJKLMNOPQRSTUVWXyz
- Usuario: admin
Paso 2: Pega de forma segura
El texto en tu portapapeles ahora estará ofuscado:
Configuración:
- API Key: XxXxXxX1X2X3X4X5X6X7X8X9X0X1X2X3X4X5X6
- Token: XxX_1234567890XxXxXxXxXxXxXxXxXxXxXxXxXxXx
- Usuario: admin
Puedes pegarlo en:
✅ Chats (Slack, Discord, Teams)
✅ Emails
✅ Documentación
✅ Tickets de soporte
✅ Foros públicos
Paso 3: Recupera las claves originales
Cuando necesites las claves reales:
Copia el texto ofuscado
Pégalo en tu navegador (en cualquier campo)
KeyCloak lo restaurará automáticamente al original
🔍 Claves detectadas
KeyCloak detecta automáticamente:
Tipo
Ejemplo
JWT Tokens
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
AWS Access Keys
AKIA1234567890ABCDEF
GitHub Tokens
ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefgh
Stripe Keys
sk_live_1234567890ABCDEFGHIJKLMNOP
Google API Keys
AIza1234567890abcdefghijklmnopqrstuv
Slack Tokens
xoxb-1234567890-ABCDEFGHIJ
Bearer Tokens
Bearer eyJhbGciOiJIUzI1NiIs...
Generic Tokens
token=abc123..., api_key=xyz789...
Hex Strings
a1b2c3d4e5f6... (32+ caracteres)
Base64 Strings
SGVsbG8gV29ybGQ=... (32+ caracteres)
🛠️ Desarrollo
Estructura del proyecto
keycloak-extension/
├── manifest.json          # Configuración de la extensión
├── background.js          # Lógica de detección y mapeo (Service Worker)
├── content.js             # Intercepta eventos copy/paste
├── popup.html             # Interfaz del popup
├── popup.js               # Lógica del popup
├── popup.css              # Estilos del popup
├── README.md              # Este archivo
├── .gitignore             # Archivos ignorados por Git
└── icons/
    ├── icon16.svg         # Icono 16x16
    ├── icon48.svg         # Icono 48x48
    └── icon128.svg        # Icono 128x128
Personalización
Añadir más patrones de detección
Edita el array PATTERNS en background.js:
javascript
const PATTERNS = [
  // Tus patrones personalizados aquí
  /\bTU_PATRON_AQUI\b/g,
  // ...
];
Cambiar el estilo de ofuscación
Modifica la función obfuscate() en background.js:
javascript
function obfuscate(value) {
  // Tu lógica personalizada aquí
  // Por ejemplo, reemplazar todo con asteriscos:
  return value.replace(/[A-Za-z0-9]/g, '*');
}
Ajustar el límite de memoria
Cambia MAX_MAP_SIZE en background.js:
javascript
const MAX_MAP_SIZE = 1000; // Aumentar límite
📦 Compilación
Para generar un archivo ZIP listo para distribuir:
Linux / macOS
bash
chmod +x build.sh
./build.sh
Esto generará keycloak-extension.zip en el directorio actual.
Windows
Usa Git Bash o WSL para ejecutar el script bash, o crea el ZIP manualmente:
powershell
Compress-Archive -Path keycloak-extension -DestinationPath keycloak-extension.zip
🔒 Privacidad y Seguridad
✅ Todo se procesa localmente en tu navegador
✅ No se envían datos a servidores externos
✅ El mapeo se guarda en chrome.storage.local (solo accesible por la extensión)
✅ Código abierto y auditable
✅ Sin tracking ni analíticas
🐛 Problemas conocidos
Firefox: la extensión se desactiva al reiniciar
Solución: Carga la extensión como temporal cada vez, o firma el .xpi para instalación permanente
Algunos sitios web bloquean la interceptación de copy/paste
Solución: Usa el menú contextual (clic derecho → Copiar/Pegar) en lugar de atajos de teclado
Las claves muy cortas (< 16 caracteres) no se detectan
Esto es intencional para evitar falsos positivos
🤝 Contribuciones
¡Las contribuciones son bienvenidas! Si quieres mejorar KeyCloak:
Haz un fork del repositorio
Crea una rama para tu feature (git checkout -b feature/NuevaFuncionalidad)
Commit tus cambios (git commit -m 'Añadir nueva funcionalidad')
Push a la rama (git push origin feature/NuevaFuncionalidad)
Abre un Pull Request
Ideas para contribuir
Añadir más patrones de detección (cryptomonedas, bancos, etc.)
Soporte para ofuscación personalizada (usuario elige el patrón)
Notificaciones visuales cuando se ofusca/restaura
Lista visual de claves guardadas en el popup
Exportar/importar el mapeo
Soporte para múltiples perfiles
Autolimpieza de claves antiguas
📝 Licencia
Este proyecto está bajo la licencia MIT - ver el archivo LICENSE para más detalles.
MIT License

Copyright (c) 2026 KeyCloak

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
👤 Autor
Creado con ❤️ para proteger tus credenciales digitales.
🌟 ¿Te gustó?
Si esta extensión te fue útil, considera:
⭐ Darle una estrella en GitHub
🐛 Reportar bugs en Issues
💡 Sugerir mejoras
📢 Compartirlo con otros desarrolladores
📚 Recursos útiles
Documentación de Chrome Extensions
Documentación de Firefox Add-ons
Opera Extensions
⚠️ Disclaimer: Esta extensión es una herramienta de seguridad adicional. No reemplaza las buenas prácticas de manejo de credenciales. Nunca compartas claves reales en texto plano, incluso con esta extensión.

---

## 📄 LICENSE (archivo adicional)

Crea también un archivo `LICENSE` en la raíz del proyecto:
MIT License
Copyright (c) 2026 KeyCloak
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
