#!/usr/bin/env python3
"""Saneado del dataset semilla: elimina imágenes corruptas o minúsculas que
pasarían el filtro de magic bytes pero romperían el entrenamiento de TF.

Es idempotente: se puede ejecutar antes y después de cada descarga.

Uso:
    tool/train/.venv/bin/python tool/sanitize_dataset.py [--min-side 96]
"""
import argparse
import os

from PIL import Image, UnidentifiedImageError

VALID = ('.jpg', '.jpeg', '.png')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dataset', default='tool/dataset')
    ap.add_argument('--min-side', type=int, default=96)
    args = ap.parse_args()

    removed = 0
    kept = 0
    for split in ('train', 'val'):
        base = os.path.join(args.dataset, split)
        if not os.path.isdir(base):
            continue
        for label in sorted(os.listdir(base)):
            label_dir = os.path.join(base, label)
            if not os.path.isdir(label_dir):
                continue
            for name in sorted(os.listdir(label_dir)):
                if not name.lower().endswith(VALID):
                    continue
                path = os.path.join(label_dir, name)
                try:
                    with Image.open(path) as im:
                        im.verify()
                    with Image.open(path) as im:
                        im.load()  # decodifica completa: detecta truncados
                        w, h = im.size
                    if w < args.min_side or h < args.min_side:
                        raise ValueError(f'muy pequeña {w}x{h}')
                    kept += 1
                except (UnidentifiedImageError, OSError, ValueError) as e:
                    os.remove(path)
                    removed += 1
                    print(f'  eliminada {path}: {e}')

    # Conteo final por clase.
    print(f'\nOK: {kept} imágenes válidas, {removed} eliminadas')
    for split in ('train', 'val'):
        base = os.path.join(args.dataset, split)
        if not os.path.isdir(base):
            continue
        for label in sorted(os.listdir(base)):
            n = len([f for f in os.listdir(os.path.join(base, label))
                     if f.lower().endswith(VALID)])
            print(f'  {split}/{label}: {n}')


if __name__ == '__main__':
    main()