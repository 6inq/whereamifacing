"""Packages the plugin for upload: plugin.json, main.lua, src/ and resources/."""
import json
import pathlib
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent


def main():
    version = json.loads((ROOT / "plugin.json").read_text(encoding="utf-8"))["version"]
    out = ROOT / "dist" / f"where-am-i-facing-{version}.zip"
    out.parent.mkdir(exist_ok=True)
    files = [ROOT / "plugin.json", ROOT / "main.lua", *sorted((ROOT / "src").rglob("*.lua")), *sorted((ROOT / "resources").glob("*.png"))]
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in files:
            archive.write(path, path.relative_to(ROOT).as_posix())
    print(f"wrote {out} ({len(files)} files)")


if __name__ == "__main__":
    main()
