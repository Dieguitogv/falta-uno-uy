# Falta Uno UY - corrección de conexión Android

Esta versión corrige el caso típico en el que el navegador abre Supabase pero el APK release muestra:
`SocketException: Failed host lookup`.

Cambio principal: el APK release incluye explícitamente el permiso Android `INTERNET`.
El workflow también vuelve a comprobarlo después de ejecutar `flutter create`, valida los Repository Secrets y compila pasando los valores con `--dart-define`.

Repository Secrets necesarios:
- `SUPABASE_URL` = URL base del proyecto, por ejemplo `https://xxxxxxxxxxxxxxxxxxxx.supabase.co` (sin `/rest/v1/` ni `/auth/v1/`).
- `SUPABASE_PUBLISHABLE_KEY` = publishable key del proyecto.
