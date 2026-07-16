# Mira — Contexto operativo

## Qué estamos construyendo

Mira traduce interfaces físicas usando la cámara. El usuario fotografía un aparato, selecciona un botón, perilla, pantalla o símbolo y recibe una explicación sencilla de su función.

La utilidad está en hacer comprensibles aparatos desconocidos para personas mayores, viajeros, personas con dificultades visuales y cualquier usuario frente a una interfaz que no entiende.

## Estado confirmado

- Ruta: `/home/daniel/Documentos/GitHub/mira`.
- Flutter Android/Web creado correctamente.
- Paquete: `mira`.
- Organización Android: `com.daniel`.
- `camera` está declarado en `pubspec.yaml`.
- La interfaz actual sigue siendo la plantilla contador de Flutter.
- No hay reconocimiento visual implementado.
- No hay backend.

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

Implementar la pantalla inicial de cámara en `lib/main.dart`, incluyendo permiso, carga, error y captura básica.

## Riesgos conocidos

- La cámara puede comportarse distinto en Web y Android.
- Los permisos deben probarse en dispositivo real.
- El reconocimiento visual puede producir respuestas incorrectas.
- Las instrucciones de aparatos peligrosos no deben presentarse como confiables sin validación.
