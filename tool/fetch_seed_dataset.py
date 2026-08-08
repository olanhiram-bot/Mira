#!/usr/bin/env python3
"""Descarga un dataset semilla de demostración desde Wikimedia Commons
(solo imágenes libres con su licencia) para poder ejercitar el pipeline de
entrenamiento sin datos privados. Las fotos reales vendrán del diario de
aprendizaje de la app.

Uso:
    python3 tool/fetch_seed_dataset.py [--per-class 12]
"""
import argparse
import csv
import json
import os
import time
import urllib.parse
import urllib.request

API = 'https://commons.wikimedia.org/w/api.php'
HEADERS = {
    'User-Agent': 'MiraDatasetFetcher/0.1 (dataset semilla de demostracion; '
    'contacto: desarrollo@mira.local)',
}

# Términos de búsqueda por clase (etiquetas del dominio de Mira).
CLASSES = {
    'lavadora': 'washing machine laundry',
    'microondas': 'microwave oven kitchen',
    'refrigerador': 'refrigerator kitchen appliance',
    'tostadora': 'toaster kitchen appliance',
}


def search_images(term: str, limit: int) -> list[dict]:
    params = {
        'action': 'query',
        'generator': 'search',
        'gsrsearch': term,
        'gsrnamespace': '6',  # File:
        'gsrlimit': str(limit * 3),  # margen para descartar fallos
        'prop': 'imageinfo',
        'iiprop': 'url|extmetadata',
        'iiurlwidth': '256',
        'format': 'json',
    }
    url = API + '?' + urllib.parse.urlencode(params)
    request = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(request, timeout=30) as r:
        data = json.load(r)
    pages = data.get('query', {}).get('pages', {})
    results = []
    for page in pages.values():
        info = page.get('imageinfo', [{}])[0]
        meta = info.get('extmetadata', {})
        license_ = meta.get('LicenseShortName', {}).get('value', '?')
        thumb = info.get('thumburl') or info.get('url')
        if thumb:
            results.append({
                'title': page.get('title', ''),
                'url': thumb,
                'license': license_,
            })
    return results


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--per-class', type=int, default=12)
    ap.add_argument('--out', default='tool/dataset')
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)
    attribution = []
    for label, term in CLASSES.items():
        images = search_images(term, args.per_class)
        train_dir = os.path.join(args.out, 'train', label)
        val_dir = os.path.join(args.out, 'val', label)
        os.makedirs(train_dir, exist_ok=True)
        os.makedirs(val_dir, exist_ok=True)
        saved = 0
        for i, img in enumerate(images):
            if saved >= args.per_class:
                break
            split = 'val' if i % 4 == 0 else 'train'  # ~25% validación
            ext = os.path.splitext(img['url'].split('/')[-1])[1] or '.jpg'
            if ext.lower() not in ('.jpg', '.jpeg', '.png'):
                ext = '.jpg'
            dest = os.path.join(args.out, split, label, f'{i:03d}{ext}')
            try:
                request = urllib.request.Request(img['url'], headers=HEADERS)
                with urllib.request.urlopen(request, timeout=30) as r:
                    data = r.read()
                if len(data) < 2000:  # thumbnails rotos/transparentes
                    continue
                with open(dest, 'wb') as f:
                    f.write(data)
                attribution.append({
                    'clase': label,
                    'archivo': dest.replace(f'{args.out}/', ''),
                    'titulo': img['title'],
                    'licencia': img['license'],
                    'fuente': img['url'].split('/revision')[0],
                })
                saved += 1
                print(f'[{label}] {saved}/{args.per_class} {img["title"]} '
                      f'({img["license"]})')
                time.sleep(0.6)  # respetar la política de bots de Wikimedia
            except Exception as e:
                print(f'  omitido {img["title"]}: {e}')
        if saved < args.per_class:
            print(f'  Aviso: solo {saved}/{args.per_class} para {label}')

    attribution_path = os.path.join(args.out, 'attribution.csv')
    with open(attribution_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(
            f, fieldnames=['clase', 'archivo', 'titulo', 'licencia', 'fuente'],
        )
        writer.writeheader()
        writer.writerows(attribution)
    print(f'\nDataset semilla listo en {args.out} '
          f'({len(attribution)} imágenes, atribución en attribution.csv)')


if __name__ == '__main__':
    main()
