# Mira — Contexto operativo

## Qué estamos construyendo

Mira traduce interfaces físicas usando la cámara. El usuario fotografía un aparato, selecciona un botón, perilla, pantalla o símbolo y recibe una explicación sencilla de su función.

La utilidad está en hacer comprensibles aparatos desconocidos para personas mayores, viajeros, personas con dificultades visuales y cualquier usuario frente a una interfaz que no entiende.

## Estado confirmado

- Ruta: `/home/daniel/Documentos/GitHub/mira`.
- Flutter Android/Web creado correctamente.
- Paquete: `mira`.
- Organización Android: `com.daniel`.
- `camera`, `shared_preferences` y `google_mlkit_text_recognition` están
  declarados en `pubspec.yaml`.
- La pantalla inicial ya tiene un estilo visual propio y accesible.
- El estilo base es "Quiet Tech accesible": fondo marfil, tinta azul verdosa,
  acento coral, superficies amplias y controles grandes.
- El onboarding presenta tres pasos y permite saltarlo o llegar a la pantalla principal.
- El onboarding se guarda como completado en preferencias locales y no se repite en cada apertura.
- La pantalla de cámara implementa apertura de la cámara disponible, estados de
  carga, permiso, error, captura y revisión local de la fotografía.
- La cámara libera recursos al salir de la app y se reintenta al volver a primer plano.
- La revisión de la fotografía ahora incluye dos zonas de demostración
  seleccionables con explicación local; no simula detección automática.
- La explicación permite cambiar manualmente la zona desde una hoja de selección.
- El OCR local lee etiquetas en Android después de capturar una imagen y muestra
  los textos como ayuda orientativa, sin convertirlos automáticamente en instrucciones.
- En Web y cuando el OCR falla se conserva la selección manual como respaldo.
- No hay backend ni reconocimiento visual generativo; la identificación abierta
  todavía no está implementada. La decisión vigente es mantener el reconocimiento
  autónomo en el dispositivo mediante un modelo local empaquetado.

## Decisiones vigentes

- El MVP empieza con una foto, no con realidad aumentada.
- El MVP funciona localmente.
- Las explicaciones iniciales pueden ser datos de demostración.
- Se prioriza una experiencia estable y accesible antes que una arquitectura grande.
- No agregar autenticación, nube, pagos ni más paquetes sin una necesidad comprobada.
- No usar datos privados reales en ejemplos o pruebas.

## Lenguaje del producto

- Nombre: Mira.
- Interfaz y documentación de usuario: español inicialmente.
- Tono: claro, directo y no técnico.
- Si la detección no es segura, la app debe decirlo.

## Cómo continuar una sesión

1. Leer `AGENTS.md`.
2. Leer este archivo y `planing.md`.
3. Revisar el estado real de `lib/`, `test/` y `pubspec.yaml`.
4. Ejecutar una validación antes de asumir que algo funciona.
5. Trabajar únicamente en la siguiente tarea del plan, salvo instrucción explícita.
6. Actualizar este archivo y `planing.md` cuando cambie el estado o una decisión.

## Próximo paso

Seleccionar/entrenar un modelo local compacto para electrodomésticos y validar su
rendimiento en el Moto G06 antes de integrarlo en la app.

## Riesgos conocidos

- La cámara puede comportarse distinto en Web y Android.
- Los permisos deben probarse en dispositivo real.
- El reconocimiento visual puede producir respuestas incorrectas.
- Las instrucciones de aparatos peligrosos no deben presentarse como confiables sin validación.
- La captura todavía debe probarse en un Android físico para confirmar el permiso nativo.
