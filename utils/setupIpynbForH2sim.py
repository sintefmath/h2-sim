"""Preserve Sphinx cross-reference cells when exporting MATLAB notebooks."""
import argparse
import json
import re
from pathlib import Path

SPHINX_ROLE = re.compile(r":(?:doc|ref|download):`[^`]+`")


def fixH2simCells(inputstr):
    """Convert Markdown cells containing explicit Sphinx roles to raw RST.

    Parse the notebook as JSON so braces in cell text, metadata and attachments
    remain intact. Ordinary Markdown and executable cells retain their types.
    """
    notebook = json.loads(inputstr)
    for cell in notebook['cells']:
        source = cell.get('source', [])
        text = source if isinstance(source, str) else ''.join(source)
        if cell.get('cell_type') == 'markdown' and SPHINX_ROLE.search(text):
            cell['cell_type'] = 'raw'
            cell.setdefault('metadata', {})['raw_mimetype'] = 'text/restructuredtext'
    return json.dumps(notebook, indent=1, ensure_ascii=False) + '\n'


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path)
    parser.add_argument('output', type=Path, nargs='?')
    args = parser.parse_args()
    converted = fixH2simCells(args.input.read_text(encoding='utf-8'))
    (args.output or args.input).write_text(converted, encoding='utf-8')
