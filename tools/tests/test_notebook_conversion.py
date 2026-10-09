import importlib.util
import json
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('conversion', Path(__file__).resolve().parents[2] / 'utils/setupIpynbForH2sim.py')
conversion = importlib.util.module_from_spec(spec)
spec.loader.exec_module(conversion)


class NotebookConversionTest(unittest.TestCase):
    def test_preserves_metadata_attachments_and_braces(self):
        notebook = {'cells': [{'cell_type': 'markdown', 'source': [':doc:`installation` {example}'],
                              'metadata': {'tags': ['keep']}, 'attachments': {'plot.png': {'image/png': 'abc'}}}],
                    'nbformat': 4, 'nbformat_minor': 5, 'metadata': {'kernelspec': {'name': 'matlab'}}}
        actual = json.loads(conversion.fixH2simCells(json.dumps(notebook)))
        expected = json.loads(json.dumps(notebook))
        expected['cells'][0]['cell_type'] = 'raw'
        expected['cells'][0]['metadata']['raw_mimetype'] = 'text/restructuredtext'
        self.assertEqual(actual, expected)

    def test_leaves_code_and_ordinary_markdown_unchanged(self):
        notebook = {'cells': [{'cell_type': 'code', 'source': [":ref:`label`"], 'metadata': {}, 'outputs': []},
                              {'cell_type': 'markdown', 'source': '# Hydrogen storage', 'metadata': {}}]}
        self.assertEqual(json.loads(conversion.fixH2simCells(json.dumps(notebook))), notebook)
