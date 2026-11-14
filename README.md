# Gestor Cafetería ☕

Aplicación cliente en Flutter desarrollada para la gestión y visualización de pedidos en tiempo real en una cafetería, conectada a una API REST backend (`mini_backend`).

El proyecto implementa un cliente HTTP tipado (`ApiClient`), manejo estructurado de errores mediante una jerarquía sellada de fallos (`Failure`), persistencia segura de tokens de sesión y una completa suite de pruebas unitarias automatizadas con `MockClient`.

---

## Requisitos del sistema

- **Flutter SDK:** 3.13.0 o superior (con Dart SDK compatible).
- **Node.js:** Versión 22.13 o superior (para ejecutar el servidor `mini_backend`).
- **Git:** Para control de versiones y clonación de repositorios.
- **Navegador web (Chrome), emulador Android o dispositivo físico.**

---

## Servidor de pedidos (`mini_backend`)

La aplicación depende de la API REST provista en el repositorio oficial de la materia:

- **Repositorio:** [https://github.com/DMI-2026/mini_backend](https://github.com/DMI-2026/mini_backend)
- **Versión probada:** Rama `master`, commit `94d25` (Node.js nativo con SQLite).

> **Nota importante:** `mini_backend` es un proyecto independiente; no debe copiarse dentro de este repositorio.

### Cómo levantar el servidor localmente:

1. Clona el repositorio del backend en una carpeta externa:
   ```bash
   git clone https://github.com/DMI-2026/mini_backend.git
   cd mini_backend
   ```
2. Inicia el servidor HTTP (no requiere `npm install` ya que no tiene dependencias externas):
   ```bash
   node server.js
   ```
3. Comprueba que responda correctamente visitando en el navegador:
   ```text
   http://localhost:8000/health
   # Respuesta esperada: {"status":"ok"}
   ```

---

## Cómo ejecutar la aplicación Flutter

1. Descarga las dependencias del proyecto:
   ```bash
   flutter pub get
   ```

2. Ejecuta la aplicación según la plataforma elegida pasando la variable de entorno `API_URL`:

   * **En Chrome (Web):**
     ```bash
     flutter run -d chrome
     ```
     *(Por defecto apunta a `http://localhost:8000`)*.

   * **En Emulador Android:**
     ```bash
     flutter run
     ```
     *(Por defecto utiliza `http://10.0.2.2:8000` para comunicarse con el localhost de la máquina anfitriona)*.

   * **En Dispositivo físico (misma red local):**
     ```bash
     flutter run --dart-define=API_URL=http://<IP_DE_TU_COMPUTADORA>:8000
     ```

---

## Cómo ejecutar las pruebas automatizadas

El proyecto cuenta con pruebas unitarias para la jerarquía de fallos y para `ApiClient` utilizando `MockClient`, permitiendo validar todos los escenarios HTTP sin requerir conexión a internet ni servidor activo:

```bash
flutter test
```

Para ejecutar el análisis estático de código:
```bash
flutter analyze
```

---

## Estructura de carpetas

```text
lib/
├── core/                  # Componentes transversales del sistema
│   ├── failure.dart       # Jerarquía sellada de errores (Failure)
│   ├── http_client.dart   # Cliente HTTP tipado con mapeo de errores
│   └── token_storage.dart # Abstracción y persistencia segura de tokens
└── main.dart              # Punto de entrada de la aplicación Flutter
test/
└── core/                  # Pruebas automatizadas unitarias
    ├── failure_test.dart     # Verificación exhaustiva de la jerarquía Failure
    └── http_client_test.dart # Pruebas con MockClient de todos los códigos HTTP
```
