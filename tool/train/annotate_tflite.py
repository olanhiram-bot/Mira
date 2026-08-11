#!/usr/bin/env python3
"""Añade metadata TFLite (normalización a [0,1] + etiquetas) al modelo
entrenado para que ML Kit devuelva etiquetas reales y preprocese como el
entrenamiento (dataset dividido por 255).

Se ejecuta con un venv aparte (protobuf 3.20, sin TensorFlow), porque
tflite-support no es compatible con el protobuf que exige TF 2.21:

    uv venv tool/train/.metaenv --python 3.11
    uv pip install --python tool/train/.metaenv/bin/python tflite-support
    tool/train/.metaenv/bin/python tool/train/annotate_tflite.py \
        --model tool/train/out/model.tflite \
        --labels tool/train/out/labels.txt

Sobrescribe el modelo con la versión anotada.
"""
import argparse
import os
import sys

from tflite_support.metadata_writers import image_classifier  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--model', required=True)
    ap.add_argument('--labels', required=True)
    args = ap.parse_args()

    with open(args.model, 'rb') as f:
        model_buffer = f.read()
    writer = image_classifier.MetadataWriter.create_for_inference(
        model_buffer,
        input_norm_mean=[0],
        input_norm_std=[255],
        label_file_paths=[args.labels],
    )
    annotated = writer.populate()
    with open(args.model, 'wb') as f:
        f.write(annotated)

    size = os.path.getsize(args.model)
    print(f'Metadata escrita: {args.model} ({size} bytes)')
    print('Normalización: [0,255] -> [0,1] (mean=0, std=255)')
    print(f'Etiquetas: {args.labels}')


if __name__ == '__main__':
    sys.exit(main())