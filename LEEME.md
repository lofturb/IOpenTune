# OpenTune 9 — YouTube Music para iPad mini 1 (iOS 9, armv7)

Port nativo en **Objective-C/UIKit** del cliente **OpenTune** de
[Arturo254](https://github.com/Arturo254/OpenTune) para el iPad mini 1
(`iPad2,6`, iOS 9.3.6) y cualquier dispositivo armv7 con iOS 9.0 o superior.

La app mantiene la estructura, la estética Material Design 3 y las funciones
principales del OpenTune original (inicio, búsqueda, géneros, biblioteca,
reproductor, letras, descargas y listas), pero reescrita sin Flutter para que
funcione en 32 bits y con 512 MB de RAM.

- **Nombre visible:** OpenTune 9
- **Bundle:** `com.lofturb.opentune9` (convive con el OpenTune original)
- **Ejecutable:** `OpenTune9`
- **Objetivo:** armv7, iOS 9.0+, probado en iPad mini 1 (`iPad2,6`)
- **Firma:** ad-hoc con `ldid`; instalación con Filza + AppSync Unified
- **Compilación:** Theos en GitHub Actions (no hace falta Mac)

## Estructura

```
app/
  Makefile                     compilación Theos, armv7 y SDK 9.3
  control                      metadatos del paquete
  entitlements.plist           platform-application, no-sandbox y llavero
  main.m                       punto de entrada
  AppDelegate.h/.m             ventana, tema guardado y sesión de audio
  OTTheme.*                    colores M3, tipografía e iconos vectoriales
  OTItem.*                     modelos y parseo de la API de YouTube Music
  OTImageCache.*               caché de portadas en memoria y disco
  OTStore.*                    favoritos, historial, listas, descargas y ajustes
  OTInnertube.*                cliente Innertube (búsqueda, browse, stream)
  OTPlayer.*                   AVPlayer, cola, aleatorio, repetición y remoto
  OTLyrics.*                   letras de LRCLIB y YouTube Music
  OTDownloads.*                descarga de audio AAC a Documents/Descargas
  OTComponents.*               celdas, carruseles, chips, mini player y cabecera
  OTRootViewController.*       contenedor de pestañas y barra flotante
  OTFeedViewController.*       base de las pantallas de contenido
  OTHomeViewController.*       inicio, saludo y filtros de ánimo
  OTSearchViewController.*     búsqueda con sugerencias e historial
  OTMoodViewController.*       géneros y ánimos
  OTLibraryViewController.*    favoritos, descargas, listas, historial y stats
  OTCollectionViewController.* álbum, lista, artista y categoría
  OTPlayerViewController.*     reproductor completo, cola y letras
  OTSettingsViewController.*   cuenta, tema, calidad, datos y acerca de
  Resources/                   Info.plist, iconos y pantallas de arranque
tools/
  generar_recursos.py          genera iconos y arranque (sin Pillow)
  comprobar_fuentes.py         coherencia de Makefile, IDs, versión y entitlements
  verificar_ipa.py             comprueba armv7, iOS 9 y estructura del IPA
  afc_put.py / afc_ls.py       copia el IPA al iPad por USB/AFC
.github/
  workflows/build-ipa.yml      compila, verifica y publica el IPA
  notas-release.md             notas del Release
```

## Compilar en GitHub Actions

El proyecto ya está publicado en **https://github.com/lofturb/IOpenTune** y el
workflow compila el IPA automáticamente. El último Release con el `.ipa`
firmado está en **Releases** (etiqueta `build-…`).

Para recompilar tras cambios:

```powershell
git add .
git commit -m "cambios"
git push origin main
```

También puedes lanzarlo a mano con **Run workflow** en la pestaña Actions
(o `gh workflow run build-ipa.yml`). El IPA queda publicado en **Releases**
y en **Artefactos**.

El workflow comprueba antes de publicar:

- que las fuentes del Makefile y los metadatos son coherentes;
- que el ejecutable `OpenTune9` es armv7 y apunta a iOS 9;
- que el IPA contiene `Info.plist`, los iconos de iPad y las imágenes de arranque;
- que la app lleva firma ad-hoc (`ldid`) y los entitlements del proyecto.

## Instalar en el iPad

Con el iPad conectado por USB y el jailbreak activo:

```powershell
python tools\verificar_ipa.py OpenTune9.ipa
python tools\afc_put.py OpenTune9.ipa /OpenTune9.ipa
```

Después, en el iPad: **Filza → /var/mobile/Media → OpenTune9.ipa → Instalar**.

> Requiere **AppSync Unified** para aceptar la firma ad-hoc. No borres el
> OpenTune original: OpenTune 9 usa otro bundle ID y se instala al lado.

## Uso rápido

- **Inicio:** saludo según la hora, filtros de ánimo del servidor y secciones de
  YouTube Music. Desliza para cargar más.
- **Buscar:** escribe para ver sugerencias; elige Todo, Canciones, Vídeos,
  Álbumes, Artistas o Listas. Pulsa una canción para reproducirla.
- **Géneros:** tarjetas de ánimos y géneros; al tocar una se abre su contenido.
- **Biblioteca:** favoritos, descargas, listas locales, historial y estadísticas.
  Desliza una fila para borrarla.
- **Reproductor:** portada, controles, aleatorio, repetición, temporizador,
  velocidad, cola y letras sincronizadas.
- **Descargas:** se guardan en `Documents/Descargas` como `.m4a` y aparecen en
  la pestaña Descargas y en Filza.
- **Cuenta:** en Ajustes → Cuenta pega la cookie `SAPISID` de
  `music.youtube.com`. Es necesaria para reproducir la mayoría de canciones
  (ver la sección del bloqueo anti-bot).

## Reproducción: bloqueo anti-bot de YouTube (2026)

Desde 2026 YouTube exige un **token PO** o una **sesión iniciada** para servir
el audio de la mayoría de canciones. Sin sesión, Innertube responde
`LOGIN_REQUIRED` con el motivo *"Sign in to confirm you're not a bot"* y el
reproductor se queda sin URL. No es un fallo del port: el proyecto original fue
retirado por DMCA (GitHub, 2-sep-2026) y todas las apps de terceros sufren el
mismo bloqueo.

Solución en OpenTune 9 (1.0.1):

- **Inicia sesión** en Ajustes → Cuenta pegando la cookie `SAPISID` (o la línea
  completa de cookies) de `music.youtube.com`. Con sesión, YouTube entrega el
  audio con normalidad.
- La app reintenta cada cliente una vez y, cuando hay sesión, prueba primero los
  clientes que admiten login (`ANDROID_MUSIC`).
- Si el audio no llega, el reproductor muestra el motivo real devuelto por
  YouTube en lugar de un error genérico.

Cómo obtener la cookie: en un ordenador entra en `music.youtube.com`, pulsa F12
→ Application/Storage → Cookies → `music.youtube.com` y copia el valor de
`SAPISID`. Caduca al cerrar sesión en el navegador.

## Notas técnicas

- `TARGET = iphone:clang:9.3:9.0`, `ARCHS = armv7`, `GO_EASY_ON_ME = 1`.
- Audio con **AVPlayer** y sesión `AVAudioSessionCategoryPlayback`; se admiten
  pistas AAC (`audio/mp4`), que es lo que entrega Innertube a clientes de iOS.
- El cliente Innertube preferido es `ANDROID_VR` (URLs directas); con sesión se
  prueba antes `ANDROID_MUSIC`. Si falla, se prueban `IOS`, `IPADOS` y
  `WEB_REMIX`, con un reintento por cliente (el control anti-bot es
  intermitente).
- Las letras se piden primero a **LRCLIB** (LRC sincronizado) y después al
  endpoint de letras de YouTube Music.
- El tema oscuro M3 se genera a partir de la semilla `#ED5564` del OpenTune
  original; el acento y el negro puro se guardan en `NSUserDefaults`.
- La app usa `platform-application` y `no-sandbox` para escribir las descargas
  fuera del contenedor y conserva los entitlements de llavero.

## Licencia y marcas

OpenTune 9 es software libre bajo la **GNU General Public License v3.0**
(ver `LICENSE`). Es un port no oficial del proyecto OpenTune de Arturo254,
también publicado bajo GPL-3.0.

YouTube Music es una marca de Google. Este proyecto no está afiliado a Google,
a YouTube ni a Apple.
