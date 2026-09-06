# Android V5

El workflow `.github/workflows/build-android-apk.yml` genera el APK automáticamente.

- Sin Secrets de Supabase: compila en modo local persistente.
- Con `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`: compila conectado al backend real.

El artefacto se llama `falta-uno-uy-v5-apk`.
