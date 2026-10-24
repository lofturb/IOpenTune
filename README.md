# OpenTune 9

Cliente de **YouTube Music** para **iPad mini 1 / iOS 9 (armv7)**, port nativo
en Objective-C/UIKit del [OpenTune](https://github.com/Arturo254/OpenTune) de
Arturo254.

- Nombre visible: **OpenTune 9**
- Bundle: `com.lofturb.opentune9`
- Ejecutable: `OpenTune9`
- Objetivo: armv7, iOS 9.0+, probado en iPad mini 1 (`iPad2,6`)
- Compilación: Theos + GitHub Actions; firma ad-hoc con `ldid`

La documentación completa (estructura, compilación, instalación y uso) está en
**[LEEME.md](LEEME.md)**.

## Compilar

```powershell
# local (Linux/macOS con Theos)
cd app
make clean && make package FINALPACKAGE=1 PACKAGE_FORMAT=ipa

# o sube el repositorio a GitHub y usa el workflow "Construir IPA"
```

El `.ipa` se publica en **Releases** y en **Artefactos**.

## Estado

✅ Compila en GitHub Actions (Theos, armv7 + SDK 9.3, ~1 min) y el Release
`build-…` contiene el IPA verificado: `armv7`, mínimo iOS 9.0, firmado con
`ldid` (listo para AppSync Unified).

## Licencia

GNU General Public License v3.0 — ver [LICENSE](LICENSE). Port no oficial; no
está afiliado a Google, YouTube ni Apple.
