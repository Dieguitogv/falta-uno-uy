# Demo de Falta Uno UY en iPhone

Esta versión agrega soporte Web/PWA para probar Falta Uno UY desde Safari en iPhone sin generar todavía un IPA.

## Publicar con GitHub Pages

1. Subí estos archivos al repositorio de Falta Uno UY.
2. En GitHub abrí **Settings > Pages**.
3. En **Build and deployment > Source**, elegí **GitHub Actions**.
4. Abrí **Actions > Deploy iPhone Web Demo > Run workflow**.
5. Cuando termine, abrí la URL publicada por GitHub Pages desde Safari en el iPhone.

## Instalar como demo en el iPhone

1. Abrí la URL en **Safari**.
2. Tocá **Compartir**.
3. Elegí **Agregar a pantalla de inicio**.
4. Confirmá con **Agregar**.

La demo abrirá a pantalla completa desde el icono, similar a una app instalada.

## Supabase

Si el repositorio ya tiene los Secrets `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`, la demo usará el mismo backend que Android. Si no están configurados, la app entra en modo local.
