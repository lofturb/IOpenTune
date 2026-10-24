# OpenTune 9 para iOS 9 (iPad mini 1 / armv7)

Cliente de **YouTube Music** para iPad de 32 bits con iOS 9, port nativo del
OpenTune de Arturo254. Pensado para el iPad mini 1 (`iPad2,6`, iOS 9.3.6),
pero funciona en cualquier dispositivo armv7 con iOS 9.0 o superior.

## Qué necesitas

- Un dispositivo con **jailbreak** y **AppSync Unified**.
- Descargar el `.ipa` de este Release y abrirlo con **Filza** (o instalarlo por
  AFC/SSH con `ipainstaller`).
- No se necesita cuenta de desarrollador de Apple ni un Mac.

## Qué trae esta versión

- **Inicio** con saludo, filtros de ánimo y secciones de YouTube Music.
- **Búsqueda** con sugerencias, historial y filtros (canciones, vídeos, álbumes,
  artistas y listas).
- **Géneros y ánimos** con tarjetas y contenido completo.
- **Biblioteca** con favoritos, descargas, listas locales, historial y
  estadísticas de reproducción.
- **Reproductor** con portada, cola, aleatorio, repetición, temporizador,
  velocidad y controles remotos/audio en segundo plano.
- **Letras** sincronizadas (LRCLIB y YouTube Music).
- **Descargas** en `Documents/Descargas` (AAC `.m4a`), visibles desde Filza.
- **Tema** Material Design 3 oscuro con acento configurable y negro puro.
- **Cuenta** mediante cookie `SAPISID` de `music.youtube.com`.
- Interfaz en español, adaptada a la pantalla del iPad mini.

## Cómo se instala

1. Copia el `.ipa` al iPad (`/var/mobile/Media`) por USB/AFC o desde Filza.
2. Ábrelo con Filza y toca **Instalar**.
3. Si iOS pide confianza, acepta el perfil.

La app se instala como **OpenTune 9** (`com.lofturb.opentune9`) y convive con el
OpenTune original sin reemplazarlo.

## Verificación

El `.ipa` se comprueba en cada build: contiene el ejecutable armv7 `OpenTune9`,
`Info.plist`, los iconos de iPad, las imágenes de arranque y la firma ad-hoc
generada con `ldid`, además de los entitlements necesarios.

## Aviso legal

OpenTune 9 es software libre bajo **GPL-3.0**. Es un port no oficial de OpenTune
(Arturo254). YouTube Music es una marca de Google; este proyecto no está
afiliado a Google, YouTube ni Apple.
