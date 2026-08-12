# M-INTEL WMS RF — Android / GitHub

Cliente móvil RF para el WMS M-INTEL. El proyecto conserva la interfaz móvil existente y corrige la lógica para alinearla con el esquema actual del sistema web.

## Qué se corrigió

- Se elimina la lógica de contraseña demo (`admin123`, `1234`, nombre del usuario).
- El operador se valida contra la tabla `operadores` y se deja preparada la migración para PIN hash.
- La selección de almacén respeta `wh_id` del operador cuando existe.
- Picking RF utiliza `rf_tasks` como fuente operativa, en lugar de crear tareas ficticias únicamente desde `ps_lineas`.
- Recepción valida la cantidad pendiente de `pe_lineas` antes de actualizar stock.
- Picking valida disponibilidad y cantidad pendiente antes de descontar stock.
- Reubicación valida origen, destino y stock antes de modificar ubicación.
- Ajustes y movimientos quedan registrados con operador.
- Las operaciones críticas se realizan mediante funciones RPC transaccionales en Supabase.
- Se evita guardar claves privadas en el repositorio.
- La compilación Android se ejecuta mediante GitHub Actions, sin necesidad de subir `node_modules`.

## Estructura

```text
m-intel-wms-rf/
├── .github/workflows/android.yml
├── docs/
│   └── ARQUITECTURA.md
├── scripts/
│   └── build-android.sh
├── supabase/migrations/
│   └── 001_rf_atomic_operations.sql
├── www/
│   ├── index.html
│   └── rf-v3.js
├── .env.example
├── .gitignore
├── capacitor.config.ts
├── package.json
└── README.md
```

## 1. Supabase

Ejecuta primero el esquema actual del WMS y después:

`supabase/migrations/001_rf_atomic_operations.sql`

La migración agrega las operaciones transaccionales utilizadas por la APK.

## 2. Configuración

La aplicación conserva la pantalla de conexión para que puedas introducir:

- Project URL
- Anon Public Key

No publiques una `service_role` key en GitHub ni dentro de la APK.

## 3. GitHub

Sube esta carpeta completa a un repositorio.

En GitHub abre:

`Actions → Build M-INTEL WMS RF APK → Run workflow`

El APK aparecerá como artifact `m-intel-wms-rf-debug`.

## 4. Compilación local

Requiere Node 22, Java 21 y Android SDK.

```bash
npm install
npx cap add android
npx cap sync android
cd android
./gradlew assembleDebug
```

## Importante

El proyecto generado es una base Android compilable. El APK final debe probarse contra una copia de pruebas de Supabase antes de utilizarse en operación real.
