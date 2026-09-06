# Falta Uno UY — V5

Versión de prueba Android con creación de partidos y persistencia.

## V5
- Fútbol 5 fijado en **10 titulares + 1 suplente de seguridad**.
- Crear partido con zona, cancha, fecha, hora, precio y nivel.
- En modo local, los partidos quedan guardados en el celular aunque cierres la app.
- Soporte Supabase para cuentas, partidos compartidos entre usuarios e inscripciones.
- El suplente se registra con rol `reserve`.
- Si un titular se baja en Supabase, el suplente se promueve automáticamente.
- GitHub Actions puede inyectar las credenciales de Supabase mediante Secrets.

## Probar sin Supabase
Compilá normalmente. La app usa almacenamiento local persistente.

## Activar Supabase real
1. Crear un proyecto en Supabase.
2. En SQL Editor ejecutar `supabase/schema.sql`.
3. En GitHub > repositorio > Settings > Secrets and variables > Actions, crear:
   - `SUPABASE_URL`
   - `SUPABASE_PUBLISHABLE_KEY`
4. Volver a Actions y ejecutar `Build Android APK`.

No uses una `service_role` key dentro de la app.

## Demo iPhone / Web PWA

Se agregó `web/` y el workflow `Deploy iPhone Web Demo`. Ver `WEB_IPHONE_DEMO.md`.
