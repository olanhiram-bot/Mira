#!/usr/bin/env python3
"""Descarga un dataset semilla grande desde Wikimedia Commons usando
CATEGORÍAS (miembros = fotos reales del aparato, mucho más relevante que la
búsqueda por texto) con paginación hasta 1000 imágenes por clase.

Solo imágenes libres con su licencia registrada en attribution.csv.
Las fotos reales del dominio vendrán del diario de aprendizaje de la app.

Uso:
    python3 tool/fetch_seed_dataset.py [--per-class 800] [--out tool/dataset]
"""
import argparse
import csv
import hashlib
import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request

API = 'https://commons.wikimedia.org/w/api.php'
HEADERS = {
    'User-Agent': 'MiraDatasetFetcher/0.2 (dataset semilla de demostracion; '
    'contacto: desarrollo@mira.local)',
}

# Categorías de Commons por clase (pueden existir categorías con 0 archivos
# directos; el script las expande a sus subcategorías con archivos).
# Volumen plano real verificado por sonda: lavadora ~550, microondas ~190,
# refrigerador ~430, tostadora ~120.
CLASSES = {
    'lavadora': [
        'Washing_machines',
        'Front-loading_washing_machines',
        'Top-loading_washing_machines',
        'Coin-operated_washing_machines',
        'Washing_machines_by_country',
        'Washing_machines_by_manufacturer',
    ],
    'microondas': [
        'Microwave_ovens',
        'Open_microwave_ovens',
        'Microwave_ovens_by_country',
    ],
    'refrigerador': [
        'Refrigerators',
        'Fridge_freezers',
        'Domestic_refrigerators',
        'Smart_refrigerators',
        'Monitor_top_refrigerators',
        'Refrigerators_by_country',
        'Refrigerators_by_brand',
        'Refrigerators_by_type',
    ],
    # Sin Early_toasters: las históricas/no eléctricas parecen estufas y
    # ensuciaban la clase. Solo tostadoras modernas (pop-up incluidas).
    'tostadora': [
        'Toasters',
        'Pop-up_toasters',
    ],
}

VALID_EXT = ('.jpg', '.jpeg', '.png')
MIN_BYTES = 5000
SLEEP = 0.4
JPEG_MAGIC = b'\xff\xd8'
PNG_MAGIC = b'\x89PNG'

# Subcategorías que no aportan fotos del aparato (arte, anuncios, etc.).
JUNK_SUBCATS = (
    'art', 'advertising', 'history', 'chemistry', 'popcorn', 'icons',
    'pastries', 'sounds', 'videos', 'cats', 'ads', 'posters', 'drawings',
    'paintings', 'models', 'toys', 'people', 'smelter', 'discs', 'meme',
    'in_use', 'in use', 'early', 'nonelectric', 'toaster_oven', 'toaster oven',
)


def api_query(params: dict) -> dict:
    url = API + '?' + urllib.parse.urlencode(params)
    for attempt in range(3):
        request = urllib.request.Request(url, headers=HEADERS)
        try:
            with urllib.request.urlopen(request, timeout=30) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < 2:
                time.sleep(5 + attempt * 5)
                continue
            raise
    raise RuntimeError(f'API sin respuesta: {url}')


def category_members(category: str, limit: int) -> list[dict]:
    """Archivos directos de una categoría (con paginación) más, si no se
    alcanza `limit`, una expansión de un nivel por sus subcategorías con
    archivos (saltando las de arte/anuncios/uso)."""
    results: list[dict] = []
    seen_urls: set[str] = set()

    def _files_of(cat: str, wanted: int) -> list[dict]:
        params = {
            'action': 'query',
            'generator': 'categorymembers',
            'gcmtitle': f'Category:{cat}',
            'gcmtype': 'file',
            'gcmlimit': '500',
            'prop': 'imageinfo',
            'iiprop': 'url|extmetadata',
            'iiurlwidth': '512',
            'format': 'json',
        }
        out: list[dict] = []
        while len(out) < wanted:
            data = api_query(params)
            pages = data.get('query', {}).get('pages', {})
            for page in pages.values():
                info = page.get('imageinfo', [{}])[0]
                meta = info.get('extmetadata', {})
                license_ = meta.get('LicenseShortName', {}).get('value', '')
                thumb = info.get('thumburl') or info.get('url')
                title = page.get('title', '')
                if not thumb or not title:
                    continue
                ext = os.path.splitext(urllib.parse.unquote(
                    title.split(':')[-1]))[1].lower()
                if ext not in VALID_EXT:
                    continue
                out.append({
                    'title': title,
                    'url': thumb,
                    'license': license_,
                })
            cont = data.get('continue')
            if not cont or len(out) >= wanted:
                break
            for key, value in cont.items():
                if key != 'continue':  # fusiona gcmcontinue y otras claves
                    params[key] = value
        return out[:wanted]

    results.extend(_files_of(category, limit))
    seen_urls.update(r['url'] for r in results)

    # Expansión de un nivel por subcategorías con archivos.
    if len(results) < limit:
        params = {
            'action': 'query',
            'generator': 'categorymembers',
            'gcmtitle': f'Category:{category}',
            'gcmtype': 'subcat',
            'gcmlimit': '500',
            'format': 'json',
        }
        data = api_query(params)
        subcats = [
            page.get('title', '').replace('Category:', '')
            for page in data.get('query', {}).get('pages', {}).values()
        ]
        for sub in subcats:
            if len(results) >= limit:
                break
            if any(junk in sub.lower() for junk in JUNK_SUBCATS):
                continue
            for img in _files_of(sub, limit - len(results)):
                if img['url'] in seen_urls:
                    continue
                seen_urls.add(img['url'])
                results.append(img)
                if len(results) >= limit:
                    break
            time.sleep(SLEEP)
    return results[:limit]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--per-class', type=int, default=800,
                    help='Máximo de imágenes por clase (hasta 1000)')
    ap.add_argument('--out', default='tool/dataset')
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)
    attribution = []

    for label, categories in CLASSES.items():
        images: list[dict] = []
        for cat in categories:
            remain = args.per_class - len(images)
            if remain <= 0:
                break
            print(f'[{label}] categoría {cat}: consultando...')
            images.extend(category_members(cat, remain))
            time.sleep(SLEEP)

        # Dedup por URL manteniendo el primer resultado.
        seen = set()
        unique = []
        for img in images:
            if img['url'] in seen:
                continue
            seen.add(img['url'])
            unique.append(img)

        train_dir = os.path.join(args.out, 'train', label)
        val_dir = os.path.join(args.out, 'val', label)
        os.makedirs(train_dir, exist_ok=True)
        os.makedirs(val_dir, exist_ok=True)

        saved = 0
        skipped_existing = 0
        for i, img in enumerate(unique):
            if saved >= args.per_class:
                break
            # Nombre determinista por hash de URL: dedup y reanudación segura.
            digest = hashlib.md5(img['url'].encode()).hexdigest()[:12]
            ext = os.path.splitext(img['url'].split('/')[-1])[1].lower()
            if ext not in VALID_EXT:
                ext = '.jpg'
            split = 'val' if i % 4 == 0 else 'train'  # ~25% validación
            dest = os.path.join(args.out, split, label, f'{digest}{ext}')
            if os.path.exists(dest) and os.path.getsize(dest) >= MIN_BYTES:
                skipped_existing += 1
                saved += 1
                continue
            try:
                request = urllib.request.Request(img['url'], headers=HEADERS)
                data = None
                for attempt in range(3):
                    try:
                        with urllib.request.urlopen(request, timeout=30) as r:
                            data = r.read()
                        break
                    except urllib.error.HTTPError as e:
                        if e.code == 429 and attempt < 2:
                            time.sleep(5 + attempt * 5)
                            continue
                        raise
                if data is None or len(data) < MIN_BYTES:
                    continue
                # Solo imágenes reales: firma JPEG/PNG, no SVG/HTML/placeholders.
                if not (data.startswith(JPEG_MAGIC) or
                        data.startswith(PNG_MAGIC)):
                    continue
                with open(dest, 'wb') as f:
                    f.write(data)
                attribution.append({
                    'clase': label,
                    'archivo': dest.replace(f'{args.out}/', ''),
                    'titulo': img['title'],
                    'licencia': img['license'] or 'sin dato',
                    'fuente': img['url'].split('/revision')[0],
                })
                saved += 1
                if saved % 50 == 0 or saved == args.per_class:
                    print(f'[{label}] {saved}/{args.per_class} '
                          f'(dedup {len(unique)} candidatas)')
                time.sleep(SLEEP)
            except Exception as e:
                print(f'  omitido {img["title"]}: {e}')
        if skipped_existing:
            print(f'[{label}] {skipped_existing} ya existían (reanudado)')
        if saved < args.per_class:
            print(f'  Aviso: solo {saved}/{args.per_class} para {label} '
                  f'(categoría agotada)')

    attribution_path = os.path.join(args.out, 'attribution.csv')
    new_attribution = not os.path.exists(attribution_path)
    with open(attribution_path, 'a', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(
            f, fieldnames=['clase', 'archivo', 'titulo', 'licencia', 'fuente'],
        )
        if new_attribution:
            writer.writeheader()
        writer.writerows(attribution)
    print(f'\nDataset semilla listo en {args.out} '
          f'({len(attribution)} imágenes nuevas en esta ejecución, '
          f'atribución en attribution.csv)')


if __name__ == '__main__':
    main()