# Generar APK de Falta Uno UY

## Opción recomendada: GitHub Actions
1. Crear un repositorio vacío en GitHub.
2. Subir todo el contenido de esta carpeta al repositorio.
3. Ir a **Actions** > **Build Android APK**.
4. Pulsar **Run workflow**.
5. Cuando termine, abrir la ejecución y descargar el artefacto **falta-uno-uy-apk**.
6. Dentro estará `app-release.apk`, listo para instalar en Android.

El workflow crea automáticamente la estructura Android si todavía no existe, instala dependencias y compila el APK Release.

## Opción local
Con Flutter instalado:
```bash
flutter create . --platforms android --org uy.faltauno --project-name falta_uno_uy
flutter pub get
flutter build apk --release
```
El APK queda en:
`build/app/outputs/flutter-apk/app-release.apk`
