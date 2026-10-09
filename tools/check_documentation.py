"""Check built documentation links and images without MATLAB or a browser."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit
import argparse


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.targets = set()
        self.links = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if attrs.get('id'):
            self.targets.add(attrs['id'])
        if tag == 'a' and attrs.get('name'):
            self.targets.add(attrs['name'])
        for key in ('href', 'src'):
            if attrs.get(key):
                self.links.append(attrs[key])


def check(folder):
    folder = folder.resolve()
    pages = {}
    for path in folder.rglob('*.html'):
        parser = Links()
        parser.feed(path.read_text(encoding='utf-8'))
        pages[path] = parser
    if not pages:
        raise SystemExit(f'No HTML pages found in {folder}')
    errors = []
    count = 0
    for source, parser in pages.items():
        for link in parser.links:
            url = urlsplit(link)
            if url.scheme or url.netloc:
                continue
            target = ((folder / unquote(url.path).lstrip('/')) if url.path.startswith('/')
                      else source.parent / unquote(url.path)) if url.path else source
            target = target.resolve()
            if target.is_dir():
                target /= 'index.html'
            count += 1
            if not target.is_relative_to(folder) or not target.is_file():
                errors.append(f'{source.relative_to(folder)}: missing target {link}')
            elif url.fragment and target in pages and unquote(url.fragment) not in pages[target].targets:
                errors.append(f'{source.relative_to(folder)}: missing anchor {link}')
    if errors:
        raise SystemExit('\n'.join(errors))
    print(f'Checked {len(pages)} HTML pages and {count} local links/images.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('folder', type=Path, nargs='?', default=Path('build/docs'))
    check(parser.parse_args().folder)
