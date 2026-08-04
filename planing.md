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

**Estado actual:** OCR y selección manual disponibles; la identificación visual
abierta queda bloqueada hasta validar un modelo adecuado.

### Fase 4 — Accesibilidad

- Lectura por voz.
- Texto grande y alto contraste.
- Navegación clara para personas con baja visión.
- Soporte inicial español/inglés.

### Fase 5 — Portafolio

- README con arquitectura y decisiones.
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

Probar el flujo completo en Android físico, especialmente el OCR y su respaldo manual.
