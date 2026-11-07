"""Fill private entity identifiers into Nix-generated Home Assistant templates."""

import argparse
import json
import os
from pathlib import Path
import re
import tempfile


def render(mapping_path, config_dir, template_dir):
    mapping = json.loads(mapping_path.read_text())
    required = {"__growatt_sph_id__", "__altherma_id__"}
    if set(mapping) != required or any(
        not isinstance(value, str) or not re.fullmatch(r"[a-z0-9]+", value)
        for value in mapping.values()
    ):
        raise ValueError("Invalid Home Assistant identifier mapping")

    files = [
        (config_dir / "configuration.yaml", config_dir / "configuration.yaml"),
        (config_dir / "ui-lovelace.yaml", config_dir / "ui-lovelace.yaml"),
        (
            template_dir / "dashboard-waermepumpe.yaml",
            config_dir / "dashboard-waermepumpe.yaml",
        ),
        (
            template_dir / "dashboard-zuhause.yaml",
            config_dir / "dashboard-zuhause.yaml",
        ),
    ]
    # Read everything before replacing any file, so missing templates fail
    # before a partially rendered set of files can be installed.
    rendered = []
    for source, target in files:
        text = source.read_text()
        for placeholder, identifier in mapping.items():
            text = text.replace(placeholder, identifier)
        rendered.append((target, text))

    for target, text in rendered:
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(
                mode="w", encoding="utf-8", dir=config_dir,
                prefix=f".{target.name}.", delete=False,
            ) as handle:
                temporary = Path(handle.name)
                handle.write(text)
                handle.flush()
                os.fsync(handle.fileno())
            # NamedTemporaryFile creates a private 0600 file. Replacing the
            # destination also avoids following a previous configuration link.
            os.replace(temporary, target)
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mapping", required=True, type=Path)
    parser.add_argument("--config-dir", required=True, type=Path)
    parser.add_argument("--template-dir", type=Path, default=Path("/etc/home-assistant"))
    args = parser.parse_args()
    render(args.mapping, args.config_dir, args.template_dir)
