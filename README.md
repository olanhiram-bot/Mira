# Mira

Mira traduce interfaces físicas usando la cámara: fotografías un aparato,
seleccionas un botón, una perilla, una pantalla o un símbolo y recibes una
explicación sencilla de su función, sin conexión y sin salir del dispositivo.

La utilidad está en hacer comprensibles aparatos desconocidos para personas
mayores, viajeros, personas con dificultades visuales y cualquier persona
frente a una interfaz que no entiende.

> Estado: MVP local funcional en Android y Web. El reconocimiento visual
> abierto (identificación de cualquier aparato) está en camino; hoy la app
> combina OCR local, etiquetas amplias y selección manual con explicación.

## Cómo funciona

1. Abre Mira y enfoca el aparato (permiso de cámara incluido).
2. Captura una fotografía y revísala en la app.
3. El OCR local lee etiquetas visibles como ayuda orientativa; también puedes
   seleccionar manualmente la zona que quieres entender.
4. Recibe una explicación sencilla: nombre, función y ejemplo de uso.
5. Si confirmas o corriges la identificación, el ejemplo se guarda en un
   diario de aprendizaje local que alimenta el entrenamiento del modelo de
   dominio. Nada sale del dispositivo durante el MVP.

## Accesibilidad

- **Texto grande**: interruptor en la pantalla principal que escala toda la
  app (1.3×) y persiste entre sesiones.
- **Lectura por voz**: botón para escuchar la identificación en Android
  (español, velocidad lenta); se oculta donde no hay motor de voz y sus
  fallos nunca rompen el flujo.
- **Contraste**: la paleta base (fondo marfil, tinta azul verdosa, acento
  coral) cumple WCAG AA en todos los pares de texto y componentes usados
  (verificación con ratios reales: mínimo 5.25:1).
- **Incertidumbre honesta**: la app presenta las detecciones como
  observaciones con confianza ("Parece ser: lavadora · 88%"), nunca como
  instrucciones seguras, y siempre ofrece confirmación o corrección.

## Arquitectura

Proyecto Flutter (Android + Web), Material 3, dependencias mínimas.

```
lib/
  main.dart                        App, onboarding, home, cámara y revisión
  accessibility/
    text_scale.dart                Escalado de texto global (InheritedWidget + prefs)
  speech/
    tts_service.dart               Contrato de lectura por voz
    tts_platform_io.dart           Motor real (Android, flutter_tts)
    tts_platform_stub.dart         No-op en plataformas sin voz
  recognition/
    image_recognition.dart         Modelo de datos normalizado (labels + confianza + estado)
    ml_kit_image_recognition_service*.dart  Servicio reemplazable (IO + stub Web)
    recognition_panel.dart         Panel de resultados: etiquetas, confianza, corrección y voz
    learning_journal*.dart         Diario de aprendizaje local (JSONL + copia durable de fotos)
tool/
  fetch_seed_dataset.py            Descarga imágenes públicas semilla (Wikimedia)
  export_dataset.dart              Convierte el diario en dataset train/val
  train/train_model.py             Transfer learning MobileNetV2 → TFLite + métricas
```

Decisiones clave:

- **Límite claro entre UI y ML**: el servicio de reconocimiento es una
  interfaz reemplazable (`ImageRecognitionService`) con implementaciones IO y
  stub; la UI nunca depende del plugin concreto. El OCR y las etiquetas son
  *evidencia con confianza*, no instrucciones.
- **Sin red, sin nube**: todo el flujo es local; el modelo de dominio se
  entrenará offline y se empaquetará en la app.
- **Diario de aprendizaje como fuente de datos**: cada confirmación/corrección
  guarda foto (copia durable), etiqueta, confianza y timestamp. El pipeline de
  entrenamiento (fuera del teléfono) convierte ese diario en dataset.
- **Import condicional para Web**: los plugins de Android (ML Kit, TTS) se
  aíslan detrás de stubs para que Web compile y degrade sin romper el flujo.
- **Privacidad por defecto**: las fotos viven en almacenamiento privado de la
  app; no hay cuentas, backend ni datos personales en el repositorio.

## Requisitos

- Flutter 3.x con soporte Android y Web.
- Se usa el envoltorio `rtk` para los comandos de Flutter (proyecto).

## Ejecutar

```bash
rtk flutter run -d chrome          # Navegador
rtk flutter run -d <android-id>    # Dispositivo físico (recomendado)
rtk flutter devices                # Listar dispositivos
```

## Verificación

```bash
rtk dart format .
rtk flutter analyze
rtk flutter test
rtk flutter build apk --debug      # Valida plugins Android
rtk flutter build web --release    # Valida stubs Web
```

El comportamiento de cámara, permisos, OCR, voz y escalado de texto requiere
validación en dispositivo físico (Moto G06).

## Estado del plan

El detalle operativo vive en `context.md` y el plan completo en `planing.md`.
Resumen:

- Fase 1 — Cámara funcional: completa (falta aceptación en físico).
- Fase 2 — Controles seleccionables: completa.
- Fase 3 — Reconocimiento visual: OCR y diario de aprendizaje listos; el
  pipeline de entrenamiento está verificado con semilla (58.3%); falta el
  corpus real (≥50 ejemplos/clase) para validar ≥75% e integrar el TFLite.
- Fase 4 — Accesibilidad: texto grande y lectura por voz listos; contraste AA
  verificado; pendiente revisión de navegación para baja visión e i18n.
- Fase 5 — Portafolio: este README; pendiente video de uso y demo/APK.

## Fuera de alcance del MVP

Backend, login y cuentas, pagos, realidad aumentada en tiempo real,
reconocimiento de cualquier aparato desde el primer día e instrucciones para
equipos médicos, industriales o situaciones peligrosas.
