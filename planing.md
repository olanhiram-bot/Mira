# Mira — Plan de trabajo

## Objetivo

Mira es una aplicación Flutter que usa la cámara para reconocer controles físicos —botones, perillas, pantallas e íconos— y explicar su función en lenguaje sencillo.

Caso principal del MVP: fotografiar una lavadora, seleccionar un control y entender qué hace en menos de un minuto.

## Estado actual

- Proyecto Flutter creado en `/home/daniel/Documentos/GitHub/mira`.
- Plataformas iniciales: Android y Web.
- Organización Android: `com.daniel`.
- Dependencias instaladas: `camera`, `shared_preferences` y
  `google_mlkit_text_recognition`.
- `lib/main.dart` contiene la pantalla inicial de Mira con el estilo visual base.
- `lib/main.dart` contiene un onboarding local de tres pasos antes de la pantalla principal.
- El onboarding persiste su estado localmente para mostrarse solo en el primer uso.
- La Fase 1 está implementada: cámara, permisos, estados de carga/error, captura y revisión local.
- La aceptación en Android queda pendiente porque no hay un dispositivo físico conectado.
- La Fase 2 ya tiene dos zonas locales seleccionables con nombre, función y ejemplo de uso.
- La selección incluye una corrección manual local mediante "Cambiar zona".
- La pantalla de cámara contempla pausa y reanudación del ciclo de vida de la app.
- El OCR local ya lee etiquetas en Android después de la captura.
- En Web, sin texto o ante un error, la selección manual sigue disponible.
- Las confirmaciones y correcciones se registran en un diario de aprendizaje
  local (`mira_learning.jsonl`, privado de la app) como ejemplos etiquetados:
  foto, etiqueta, confianza y si fue corrección. Este corpus es la fuente de
  datos para el entrenamiento del modelo de dominio en Fase 3; el modelo no se
  entrena dentro del teléfono.
- No existe backend, modelo visual generativo, clasificación visual abierta,
  detector de controles, autenticación ni realidad aumentada. La solución
  prevista es autónoma y debe usar un modelo local empaquetado.

## Alcance del MVP

1. Abrir la cámara.
2. Mostrar una previsualización estable.
3. Capturar una fotografía.
4. Mostrar la fotografía capturada.
5. Permitir seleccionar una zona de la imagen.
6. Mostrar una explicación temporal para esa zona.
7. Leer la explicación con voz si la plataforma lo permite.

La primera explicación puede ser local y basada en datos de demostración. La detección automática se agrega después de que el flujo de cámara funcione.

## Fases

### Fase 1 — Cámara funcional

- Reemplazar la pantalla contador.
- Crear pantalla inicial de Mira.
- Manejar permisos de cámara.
- Mostrar estados de carga y error.
- Capturar y revisar una imagen.

**Aceptación:** una persona puede abrir Mira, tomar una foto y verla dentro de la app en Android.

### Fase 2 — Controles seleccionables

- Dibujar zonas de demostración sobre la imagen.
- Permitir tocar una zona.
- Mostrar nombre, función y ejemplo de uso.
- Mantener el modelo de datos local y pequeño.

**Aceptación:** tocar un control muestra una explicación reproducible sin red.

### Fase 3 — Reconocimiento visual

- Leer etiquetas con OCR local en Android.
- Seleccionar o entrenar un modelo local compacto que identifique electrodomésticos.
- Integrar inferencia TFLite/Android sin depender de red.
- Detectar controles mediante imagen en una fase posterior.
- Reconocer texto e íconos comunes.
- Mostrar nivel de confianza.
- Permitir corregir una detección.

**Estado actual:** OCR y selección manual disponibles; el diario de aprendizaje
local recolecta confirmaciones y correcciones como datos etiquetados. El
pipeline de entrenamiento está verificado y re-ejecutado con la semilla
completa: `tool/fetch_seed_dataset.py` descarga imágenes públicas semilla,
`tool/sanitize_dataset.py` elimina corruptas, `tool/train/train_model.py`
entrena con transfer learning MobileNetV2 (fase 1 + fine-tune) y exporta
TFLite + labels + métricas, y `tool/train/annotate_tflite.py` añade la
metadata (normalización [0,1] + etiquetas). La semilla final son 2521 imágenes
válidas (lavadora 1015, refrigerador 1009, microondas 318, tostadora 180):
precisión global 73.92% con lavadora 75.3% y refrigerador 81.0%, pero
microondas 58.5% y tostadora 48.9% — el gate de ≥75% en CADA clase no se
alcanza. Por decisión explícita del usuario, el modelo se integró igualmente:
`assets/models/mira_appliances.tflite` (anotado con metadata de normalización
[0,1] y etiquetas) reemplaza al MobileNet ImageNet en
`ml_kit_image_recognition_service_io.dart`, manteniendo el flujo fail-closed
(confianza visible, umbral 0.55, confirmación/corrección y respaldo manual).
Sigue pendiente el corpus real (≥50 ejemplos por clase) que alcance ≥75% en
validación y la validación en el Moto G06.

### Fase 4 — Accesibilidad

- Lectura por voz: botón para escuchar la identificación (Android; oculto en Web).
- Texto grande: interruptor persistente de escala 1.3× aplicado a toda la app.
- Contraste: paleta base verificada contra WCAG AA (ratio mínimo real 5.25:1);
  pendiente revisar la navegación para baja visión.
- Navegación clara para personas con baja visión.
- Soporte inicial español/inglés.

### Fase 5 — Portafolio

- README con arquitectura y decisiones: hecho (`README.md`).
- Video corto de uso.
- Dataset de demostración sin datos privados.
- Pruebas de los estados principales.
- Demo desplegada o APK instalable.

## Fuera de alcance inicial

- Backend.
- Login y cuentas.
- Pagos.
- Realidad aumentada en tiempo real.
- Reconocimiento de cualquier aparato desde el primer día.
- Instrucciones para equipos médicos, industriales o situaciones peligrosas.

## Decisiones técnicas

- Flutter como aplicación principal.
- Dependencias mínimas.
- Material 3 con una paleta accesible y superficies tonales; evitar gradientes y decoración que distraiga.
- Primero cámara y flujo local; después reconocimiento.
- No guardar fotografías fuera del dispositivo durante el MVP.
- Las preferencias locales solo guardan el estado de onboarding.
- No afirmar instrucciones cuando la detección sea incierta.

## Verificación mínima

Desde la raíz del proyecto:

```bash
rtk dart format .
rtk flutter analyze
rtk flutter test
```

## Siguiente tarea

Acumular datos reales en el diario (≥50 ejemplos por clase en el Moto G06),
re-entrenar el modelo de dominio y validar ≥75% en CADA clase. El modelo actual
ya está integrado en `ml_kit_image_recognition_service_io.dart` (por decisión
explícita del usuario), pero microondas 58.5% y tostadora 48.9% quedan por
debajo del gate y deben re-evaluarse con el corpus real.
