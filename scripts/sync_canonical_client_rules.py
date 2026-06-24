from pathlib import Path
import re
import sys

ROOT = Path("/data/data/com.termux/files/home/projects")
REGISTRY = ROOT / "helpy/docs/architecture/Helpy_Architecture_Registry_v1.md"
OUT = Path("assets/canonical_client_rules_ru.txt")

PREFIXES = (
    "Вы не обязаны",
    "Подготовьте",
    "Уберите",
)

if not REGISTRY.exists():
    raise SystemExit(f"Registry not found: {REGISTRY}")

text = REGISTRY.read_text(encoding="utf-8")

match = re.search(
    r"## Client Rules Language & Translation Standard(?P<body>.*?)(?:\n## |\Z)",
    text,
    flags=re.S,
)

if not match:
    raise SystemExit("Client Rules Language & Translation Standard block not found")

body = match.group("body")
phrases: list[str] = []

for raw_line in body.splitlines():
    line = raw_line.strip()
    if not line.startswith("- "):
        continue

    phrase = line[2:].strip()

    if phrase.startswith(PREFIXES):
        phrases.append(phrase)

unique_phrases = list(dict.fromkeys(phrases))

if not unique_phrases:
    raise SystemExit("No canonical client rules extracted")

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text("\n".join(unique_phrases) + "\n", encoding="utf-8")

print(f"Synced canonical rules: {len(unique_phrases)}")
print(f"Output: {OUT}")
