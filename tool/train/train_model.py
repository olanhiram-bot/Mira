#!/usr/bin/env python3
"""Entrena un clasificador compacto de electrodomésticos para Mira y exporta
un modelo TFLite con sus etiquetas y un reporte de métricas.

Transfer learning: MobileNetV2 congelado + cabeza propia entrenada.
El modelo se entrena FUERA del teléfono; la app solo ejecuta inferencia.

Uso:
    python3 tool/train/train_model.py --dataset tool/dataset [--epochs 20]
"""
import argparse
import json
import os
import sys

import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

AUTOTUNE = tf.data.AUTOTUNE


def build_datasets(dataset_dir: str, img_size: int, batch: int):
    train_dir = os.path.join(dataset_dir, 'train')
    val_dir = os.path.join(dataset_dir, 'val')
    if not os.path.isdir(train_dir) or not os.path.isdir(val_dir):
        sys.exit(f'El dataset debe contener train/ y val/: {dataset_dir}')
    labels = sorted(
        d for d in os.listdir(train_dir)
        if os.path.isdir(os.path.join(train_dir, d))
    )
    if len(labels) < 2:
        sys.exit('Se necesitan al menos 2 clases en train/')

    def _load(path):
        ds = keras.utils.image_dataset_from_directory(
            path,
            image_size=(img_size, img_size),
            batch_size=batch,
            label_mode='categorical',
            shuffle=True,
        )
        return ds.map(lambda x, y: (x / 255.0, y)).prefetch(AUTOTUNE)

    train = _load(train_dir)
    val = _load(val_dir)
    return train, val, labels


def build_model(img_size: int, n_classes: int):
    augmentation = keras.Sequential([
        layers.RandomFlip('horizontal'),
        layers.RandomRotation(0.12),
        layers.RandomZoom(0.12),
        layers.RandomContrast(0.15),
    ])
    base = keras.applications.MobileNetV2(
        weights='imagenet',
        include_top=False,
        input_shape=(img_size, img_size, 3),
    )
    base.trainable = False
    model = keras.Sequential([
        layers.Input((img_size, img_size, 3)),
        augmentation,
        base,
        layers.GlobalAveragePooling2D(),
        layers.Dropout(0.2),
        layers.Dense(n_classes, activation='softmax'),
    ])
    model.compile(
        optimizer=keras.optimizers.Adam(1e-3),
        loss='categorical_crossentropy',
        metrics=['accuracy'],
    )
    return model


def evaluate_per_class(model, val, labels: list[str]):
    total = {label: 0 for label in labels}
    correct = {label: 0 for label in labels}
    for x, y in val:
        preds = model.predict(x, verbose=0)
        for p, t in zip(preds, y):
            predicted = int(np.argmax(p))
            true = int(np.argmax(t))
            total[labels[true]] += 1
            if predicted == true:
                correct[labels[true]] += 1
    per_class = {}
    for label in labels:
        n = total[label]
        per_class[label] = {
            'correct': correct[label],
            'total': n,
            'accuracy': round(correct[label] / n, 4) if n else None,
        }
    overall = sum(correct.values()) / sum(total.values()) if total else 0.0
    return overall, per_class


def export_tflite(model, out_dir: str):
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_bytes = converter.convert()
    model_path = os.path.join(out_dir, 'model.tflite')
    with open(model_path, 'wb') as f:
        f.write(tflite_bytes)
    return model_path, len(tflite_bytes)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dataset', required=True, help='Carpeta con train/ y val/')
    ap.add_argument('--epochs', type=int, default=25)
    ap.add_argument('--img-size', type=int, default=160)
    ap.add_argument('--batch', type=int, default=16)
    ap.add_argument('--out', default='tool/train/out')
    args = ap.parse_args()

    train, val, labels = build_datasets(args.dataset, args.img_size, args.batch)
    print(f'Clases: {labels}')

    model = build_model(args.img_size, len(labels))
    os.makedirs(args.out, exist_ok=True)
    callbacks = [
        keras.callbacks.EarlyStopping(
            patience=5, restore_best_weights=True, verbose=1,
        ),
        keras.callbacks.ModelCheckpoint(
            os.path.join(args.out, 'best.h5'),
            save_best_only=True,
            verbose=1,
        ),
    ]

    history = model.fit(
        train,
        validation_data=val,
        epochs=args.epochs,
        callbacks=callbacks,
        verbose=1,
    )

    overall, per_class = evaluate_per_class(model, val, labels)
    print('\n=== Reporte de validación ===')
    for label, stats in per_class.items():
        print(f'{label}: {stats}')
    print(f'Precisión global: {overall:.2%}')

    model_path, size = export_tflite(model, args.out)
    labels_path = os.path.join(args.out, 'labels.txt')
    with open(labels_path, 'w') as f:
        f.write('\n'.join(labels))

    metrics = {
        'classes': labels,
        'overall_accuracy': round(overall, 4),
        'per_class_accuracy': per_class,
        'epochs': len(history.history['accuracy']),
        'img_size': args.img_size,
        'tflite_bytes': size,
        'tflite_path': model_path,
    }
    with open(os.path.join(args.out, 'metrics.json'), 'w') as f:
        json.dump(metrics, f, indent=2, ensure_ascii=False)

    print(f'\nModelo TFLite: {model_path} ({size} bytes)')
    print(f'Etiquetas: {labels_path}')
    print(f'Métricas: {os.path.join(args.out, "metrics.json")}')


if __name__ == '__main__':
    main()
