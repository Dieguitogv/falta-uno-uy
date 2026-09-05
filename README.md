# Falta Uno UY — MVP Flutter 0.2

Segunda base funcional de la app.

## Ya funciona
- Navegación: Inicio / Explorar / Crear / Mis partidos / Perfil
- Crear partidos
- Explorar y filtrar por texto y nivel
- Sumarse y bajarse de un partido
- Detección de partido completo
- Botón “Me falta uno” para organizadores
- Perfil con historial de cuadros
- Modo demo sin configurar backend
- Soporte Supabase real
- Registro/login por email y contraseña
- Persistencia de perfiles, partidos e inscripciones
- Esquema de equipos e historial de pertenencia
- Row Level Security inicial

## Probar sin Supabase
1. Instalar Flutter.
2. Abrir esta carpeta en Android Studio o VS Code.
3. Ejecutar `flutter pub get`.
4. Ejecutar `flutter run`.

La app arranca automáticamente en modo demo.

## Activar Supabase
1. Crear un proyecto en Supabase.
2. Abrir SQL Editor y ejecutar `supabase/schema.sql`.
3. En Authentication habilitar Email.
4. Ejecutar Flutter pasando URL y publishable key:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_PUBLISHABLE_KEY
```

No usar una secret/service_role key dentro de la app.

## Siguiente etapa
- Perfil editable real
- “Me falta uno” con búsqueda de jugadores
- Invitaciones
- Chat por partido
- Notificaciones
- Confirmación previa de asistencia
- No-show y reputación
- Equipos reales y “Buscar rival”

## V3 — suplente de seguridad + “Me falta uno”
- En fútbol 5, `maxPlayers=10` representa los 10 titulares.
- La capacidad real del evento es 11: **10 titulares + 1 suplente de seguridad**.
- Al llegar a 10/10, el partido sigue abierto únicamente para el suplente.
- El botón del organizador cambia de **ME FALTA UNO** a **BUSCAR SUPLENTE**.
- La pantalla de búsqueda muestra jugadores compatibles con posición, zona, reputación, asistencia, distancia y cuadro/historial.
- Cuando el partido llega a 11 participantes queda **PARTIDO CUBIERTO**.
- La regla funcional prevista es que, si un titular se baja, el suplente sea promovido automáticamente.

## V4 visual
- Tema oscuro deportivo con verde Falta Uno.
- Inicio con hero, accesos rápidos y tarjetas de partidos.
- Flujo 10 titulares + 1 suplente de seguridad.
- “Me falta uno” cambia a “Buscar suplente” cuando se completan los titulares.
- Perfil mantiene cuadros actuales/anteriores e historial.
