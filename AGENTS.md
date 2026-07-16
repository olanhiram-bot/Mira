# Instrucciones para Mira

## Antes de trabajar

- Ejecuta los comandos desde `/home/daniel/Documentos/GitHub/mira`.
- Lee `context.md` y `planing.md` antes de modificar código.
- Comprueba el estado real del repositorio; no des por terminada una fase porque exista un archivo.

## Reglas del proyecto

- Mantén el cambio mínimo que complete la tarea actual.
- Reutiliza Flutter y las dependencias ya instaladas antes de agregar otra.
- No construyas backend, login, pagos, nube o realidad aumentada antes de que el MVP local funcione.
- No guardes fotografías privadas, tokens ni secretos en el repositorio.
- No presentes una detección incierta como una instrucción segura.
- Toda pantalla nueva debe contemplar carga, error y estado vacío cuando aplique.
- La accesibilidad es parte del producto: texto legible, contraste y controles claros.

## Comandos de verificación

```bash
rtk dart format .
rtk flutter analyze
rtk flutter test
```

Para ejecutar en navegador:

```bash
rtk flutter run -d chrome
```

Para revisar dispositivos:

```bash
rtk flutter devices
```

## Flujo de implementación

1. Revisar el objetivo en `planing.md`.
2. Inspeccionar los archivos que realmente participan.
3. Implementar una sola fase pequeña.
4. Ejecutar formato, análisis y pruebas.
5. Actualizar `context.md` con el estado confirmado.
6. Actualizar `planing.md` solo si cambia el alcance o una decisión.

## Primera tarea autorizada

Reemplazar la plantilla contador por una pantalla inicial que abra la cámara, maneje permisos y permita capturar una imagen. Mantener el reconocimiento visual para una fase posterior.
