#!/usr/bin/env bash
set -euo pipefail

INPUT_NOTEBOOK="${1:-group_project_notebook.ipynb}"
OUTPUT_NOTEBOOK="${2:-group_project_notebook_quarto.ipynb}"
REPORT_TITLE="${REPORT_TITLE:-DSC259 Final Project: Power Outages}"
RENDER_TEX="${RENDER_TEX:-1}"
RENDER_PDF="${RENDER_PDF:-1}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

log() {
  echo "==> $*"
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

require_file() {
  [[ -f "$1" ]] || die "File not found: $1"
}

require_cmd() {
  have_cmd "$1" || die "Missing command: $1"
}

require_file "$INPUT_NOTEBOOK"
require_cmd python3
require_cmd quarto

if have_cmd pip3; then
  PIP="pip3"
elif python3 -m pip --version >/dev/null 2>&1; then
  PIP="python3 -m pip"
else
  die "Missing pip for python3"
fi

log "Checking Python packages"
python3 - <<'PY'
import importlib.util
mods = ["nbformat", "plotly", "kaleido"]
missing = [m for m in mods if importlib.util.find_spec(m) is None]
if missing:
    raise SystemExit(",".join(missing))
PY
PKG_STATUS=$?

if [[ "$PKG_STATUS" != "0" ]]; then
  log "Installing missing Python packages"
  # shellcheck disable=SC2086
  $PIP install --user nbformat plotly kaleido
fi

if [[ "$INPUT_NOTEBOOK" == "$OUTPUT_NOTEBOOK" ]]; then
  die "Output notebook must be different from input notebook"
fi

log "Copying notebook"
cp -f -- "$INPUT_NOTEBOOK" "$OUTPUT_NOTEBOOK"

log "Patching notebook for clean PDF code formatting"
python3 - "$OUTPUT_NOTEBOOK" "$REPORT_TITLE" <<'PY'
import copy
import re
import sys
from pathlib import Path
import nbformat as nbf

path = Path(sys.argv[1])
title = sys.argv[2]

authors = [
    "Scotty Rogers",
    "Jillian ONeel",
    "Hans Hanson",
]

nb = nbf.read(path, as_version=4)

def src_text(cell):
    s = cell.get("source", "")
    if isinstance(s, list):
        return "".join(s)
    return s

# Fixed YAML with proper code formatting settings
yaml_block = """---
title: "%s"
author:
  - "Scotty Rogers"
  - "Jillian ONeel"
  - "Hans Hanson"
format:
  pdf:
    toc: true
    toc-depth: 3
    number-sections: true
    colorlinks: true
    keep-tex: true
    fig-pos: H
    code-block-bg: true
    code-block-border-left: "#31BAE9"
    listings: true
    geometry:
      - margin=1in
    include-in-header:
      text: |
        \\usepackage{float}
        \\usepackage{fancyvrb}
        \\usepackage{listings}
        \\usepackage{longtable}
        \\usepackage{booktabs}
        \\usepackage{array}
        \\lstset{
          basicstyle=\\ttfamily\\small,
          breaklines=true,
          breakatwhitespace=true,
          columns=fullflexible,
          keepspaces=true,
          showstringspaces=false,
          frame=single,
          xleftmargin=2em,
          framexleftmargin=1.5em,
          numbers=none,
          numberstyle=\\tiny,
          stepnumber=1,
          tabsize=2
        }
        \\DefineVerbatimEnvironment{Highlighting}{Verbatim}{
          breaklines,
          breakanywhere=true,
          commandchars=\\\\\\{\\}
        }
execute:
  echo: true
  warning: false
  error: false
  cache: false
jupyter: python3
---
""" % title.replace('"', '\\"')

plotly_patch = """
# Quarto PDF patch for Plotly static rendering
import os
os.environ.setdefault("MPLBACKEND", "Agg")
try:
    import plotly.io as pio
    pio.renderers.default = "png"
    try:
        pio.kaleido.scope.default_format = "png"
        pio.kaleido.scope.default_width = 1400
        pio.kaleido.scope.default_height = 900
        pio.kaleido.scope.default_scale = 2
    except Exception:
        pass
except Exception as exc:
    print("Plotly static renderer setup warning:", exc)

try:
    import pandas as pd
    pd.options.plotting.backend = "plotly"
except Exception:
    pass
""".strip() + "\n"

toc_cell_re = re.compile(r'Table of Contents', re.IGNORECASE)
back_to_toc_re = re.compile(r'^\s*<a\s+href="#toc">Back to Table of Contents</a>\s*$', re.IGNORECASE | re.MULTILINE)
anchor_heading_re = re.compile(r'<h([1-6])>\s*<a\s+id="[^"]+">([^<]+)</a>\s*</h\1>', re.IGNORECASE)
html_nav_re = re.compile(r'</?(a|ul|li)\b[^>]*>', re.IGNORECASE)

new_cells = []

first_is_yaml = False
if nb.cells:
    first = nb.cells[0]
    if first.get("cell_type") == "raw":
        first_src = src_text(first).lstrip()
        if first_src.startswith("---") and "format:" in first_src:
            first_is_yaml = True

if first_is_yaml:
    nb.cells[0]["source"] = yaml_block
else:
    raw = nbf.v4.new_raw_cell(yaml_block)
    raw["metadata"] = {"raw_mimetype": "text/markdown"}
    new_cells.append(raw)

injected_plotly_patch = False

for cell in nb.cells:
    cell = copy.deepcopy(cell)
    cell.setdefault("metadata", {})
    text = src_text(cell)

    if cell.get("cell_type") == "markdown":
        lower = text.lower()

        if "table of contents" in lower and ("<ul>" in lower or "<li>" in lower):
            cell["metadata"].setdefault("tags", [])
            if "remove-cell" not in cell["metadata"]["tags"]:
                cell["metadata"]["tags"].append("remove-cell")
            cell["source"] = "<!-- removed manual html toc -->\n"
            new_cells.append(cell)
            continue

        text = back_to_toc_re.sub("", text)
        text = anchor_heading_re.sub(lambda m: ("#" * int(m.group(1))) + " " + m.group(2), text)
        text = html_nav_re.sub("", text)

        if text.strip():
            cell["source"] = text.strip() + "\n"
        else:
            cell["metadata"].setdefault("tags", [])
            if "remove-cell" not in cell["metadata"]["tags"]:
                cell["metadata"]["tags"].append("remove-cell")
            cell["source"] = "<!-- removed empty html nav cell -->\n"

    elif cell.get("cell_type") == "code":
        lower = text.lower()
        if (not injected_plotly_patch) and (
            "import plotly" in lower or
            "plotly.express" in lower or
            "plotly.graph_objects" in lower or
            "pd.options.plotting.backend" in lower
        ):
            if plotly_patch not in text:
                cell["source"] = text.rstrip() + "\n\n" + plotly_patch
            injected_plotly_patch = True

    new_cells.append(cell)

if not injected_plotly_patch:
    setup = nbf.v4.new_code_cell(plotly_patch)
    setup["metadata"] = {"tags": ["remove-input"]}
    insert_at = 1 if new_cells and new_cells[0].get("cell_type") == "raw" else 0
    new_cells.insert(insert_at, setup)

nb.cells = new_cells
nb.metadata.setdefault("kernelspec", {})
nb.metadata["kernelspec"]["name"] = "python3"
nb.metadata["kernelspec"]["display_name"] = "Python 3"
nb.metadata.setdefault("language_info", {})
nb.metadata["language_info"]["name"] = "python"

nbf.write(nb, path)
PY

BASE_NAME="$(basename "$OUTPUT_NOTEBOOK" .ipynb)"
OUT_DIR="$(dirname "$OUTPUT_NOTEBOOK")"
TEX_FILE="$OUT_DIR/$BASE_NAME.tex"
PDF_FILE="$OUT_DIR/$BASE_NAME.pdf"

render_one() {
  local fmt="$1"
  log "Rendering $fmt"
  quarto render "$OUTPUT_NOTEBOOK" --to "$fmt"
}

if [[ "$RENDER_TEX" == "1" ]]; then
  render_one latex
  [[ -f "$TEX_FILE" ]] || die "Missing tex output: $TEX_FILE"
  [[ -s "$TEX_FILE" ]] || die "Empty tex output: $TEX_FILE"
fi

if [[ "$RENDER_PDF" == "1" ]]; then
  render_one pdf
  [[ -f "$PDF_FILE" ]] || die "Missing pdf output: $PDF_FILE"
  [[ -s "$PDF_FILE" ]] || die "Empty pdf output: $PDF_FILE"
fi

log "Done"
echo "Patched notebook: $OUTPUT_NOTEBOOK"
[[ "$RENDER_TEX" == "1" ]] && echo "LaTeX output:   $TEX_FILE"
[[ "$RENDER_PDF" == "1" ]] && echo "PDF output:     $PDF_FILE"

