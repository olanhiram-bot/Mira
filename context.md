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
- Las confirmaciones y correcciones del panel de reconocimiento se guardan en
  un diario de aprendizaje local (JSONL privado de la app, `mira_learning.jsonl`)
  con foto, etiqueta confirmada, confianza y si fue corrección. La foto se copia
  al almacenamiento durable de la app (`<documentos>/images/`) para que el
  dataset sobreviva a la limpieza de la carpeta temporal de la cámara. Nada sale
  del dispositivo y alimenta los futuros ciclos de entrenamiento del modelo de dominio.
- La lectura por voz lee en voz alta la identificación mostrada en Android
  (flutter_tts, español, velocidad lenta) con un botón en el panel de
  reconocimiento; el botón se oculta donde no hay motor de voz y los fallos
  del motor nunca rompen el flujo (Web degrada sin voz).
- La home incluye un interruptor de texto grande (escala 1.3×) que se aplica a
  toda la app, persiste en preferencias locales y se carga al iniciar.
- La paleta base (marfil, tinta azul verdosa, acento coral) cumple WCAG AA en
  todos los pares de texto y componentes usados: verificación por ratio real
  (mínimo 5.25:1, texto y UI) sobre los colores de `lib/main.dart`.
- El README de portafolio documenta el producto, la arquitectura y las
  decisiones técnicas (Fase 5, pendiente video y demo/APK).
- El pipeline de entrenamiento se re-ejecutó completo con la semilla real de
  Wikimedia: 2521 imágenes válidas (train 1827 / val 694; lavadora 1015,
  refrigerador 1009, microondas 318, tostadora 180) tras saneado PIL. Resultado:
  73.92% global en validación (lavadora 75.3%, refrigerador 81.0%, microondas
  58.5%, tostadora 48.9%). El gate de integración (≥75% en CADA clase) NO se
  alcanzó: el desbalance de clases y el ruido de las categorías pequeñas de
  Commons (tostadoras históricas/museo) hunden microondas y tostadora. El modelo
  de dominio NO se integró; la app sigue con MobileNet ImageNet.
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

Entrenar el modelo con un corpus real (no de demostración) a partir del diario de
aprendizaje: al menos 50 ejemplos por clase con buenas fotos en el Moto G06.
Si la precisión supera 75% en validación, integrar el modelo TFLite en la app
para sustituir o complementar el MobileNet ImageNet actual.

## Riesgos conocidos

- La cámara puede comportarse distinto en Web y Android.
- Los permisos deben probarse en dispositivo real.
- El reconocimiento visual puede producir respuestas incorrectas.
- Las instrucciones de aparatos peligrosos no deben presentarse como confiables sin validación.
- La captura todavía debe probarse en un Android físico para confirmar el permiso nativo.
