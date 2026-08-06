#!/usr/bin/env python3
"""Safely apply a small TOML localization overlay to Fields of Mistria assets.zip."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import tempfile
import tomllib
import zipfile
from pathlib import Path, PurePosixPath

STATE_SUFFIX = ".fom-localization-state.json"

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while chunk := f.read(1024 * 1024): h.update(chunk)
    return h.hexdigest()

def validate_toml(path: Path) -> bytes:
    data = path.read_bytes()
    tomllib.loads(data.decode("utf-8-sig"))
    return data

def read_overlay(root: Path) -> dict[str, bytes]:
    files: dict[str, bytes] = {}
    for path in sorted((root / "localization").rglob("*.toml")):
        rel = path.relative_to(root / "localization").as_posix()
        validate_toml(path)
        files[f"assets/localization/{rel}"] = path.read_bytes()
    if not files: raise ValueError("Overlay has no localization TOML files")
    return files

def ensure_meta_fragment_is_safe(data: bytes) -> None:
    meta = tomllib.loads(data.decode("utf-8-sig"))
    languages = meta.get("asset_properties", {}).get("languages", {})
    if set(languages) != {"bul"}: raise ValueError("POC metadata must define only the bul language fragment")

def copy_backup_once(archive: Path, backup: Path) -> None:
    if backup.exists(): raise FileExistsError(f"Refusing to overwrite existing backup: {backup}")
    with archive.open("rb") as source, backup.open("xb") as target:
        shutil.copyfileobj(source, target, 1024 * 1024)
    if sha256_file(archive) != sha256_file(backup): raise IOError("Backup hash verification failed")

def updated_zip_bytes(archive: Path, overlay: dict[str, bytes]) -> tuple[bytes, list[dict[str, object]]]:
    changed: list[dict[str, object]] = []
    with zipfile.ZipFile(archive, "r") as source:
        names = {info.filename for info in source.infolist()}
        if "assets/localization/l10n.meta.toml" not in names:
            raise ValueError("Archive lacks assets/localization/l10n.meta.toml")
        replacement = dict(overlay)
        original_meta = source.read("assets/localization/l10n.meta.toml")
        fragment = replacement.pop("assets/localization/l10n.meta.toml", None)
        if fragment is not None:
            ensure_meta_fragment_is_safe(fragment)
            # Append a validated language table fragment; preserve the game's
            # existing metadata/comments and unrelated registration order.
            addition = fragment.decode("utf-8-sig")
            marker = "[asset_properties.languages.bul]"
            if marker not in original_meta.decode("utf-8-sig"):
                replacement["assets/localization/l10n.meta.toml"] = original_meta.rstrip(b"\r\n") + b"\n\n" + addition.encode("utf-8") + b"\n"
            else:
                replacement["assets/localization/l10n.meta.toml"] = original_meta
        out = tempfile.SpooledTemporaryFile(max_size=64 * 1024 * 1024)
        with zipfile.ZipFile(out, "w") as target:
            for info in source.infolist():
                payload = replacement.pop(info.filename, source.read(info))
                new_info = zipfile.ZipInfo(info.filename, info.date_time)
                new_info.comment = info.comment; new_info.extra = info.extra
                new_info.create_system = info.create_system; new_info.create_version = info.create_version
                new_info.extract_version = info.extract_version; new_info.flag_bits = info.flag_bits
                new_info.internal_attr = info.internal_attr; new_info.external_attr = info.external_attr
                new_info.compress_type = info.compress_type
                target.writestr(new_info, payload)
                old_hash = hashlib.sha256(source.read(info)).hexdigest()
                new_hash = hashlib.sha256(payload).hexdigest()
                if old_hash != new_hash: changed.append({"path": info.filename, "old_sha256": old_hash, "new_sha256": new_hash, "action": "replace"})
            for name, payload in sorted(replacement.items()):
                target.writestr(name, payload, compress_type=zipfile.ZIP_DEFLATED)
                changed.append({"path": name, "old_sha256": None, "new_sha256": hashlib.sha256(payload).hexdigest(), "action": "add"})
        out.seek(0); data = out.read(); out.close()
    return data, changed

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--archive", type=Path, required=True)
    ap.add_argument("--overlay", type=Path)
    ap.add_argument("--backup", type=Path, required=True)
    ap.add_argument("--report", type=Path, required=True)
    ap.add_argument("--restore", action="store_true")
    args = ap.parse_args()
    archive, backup, report = args.archive, args.backup, args.report
    if not zipfile.is_zipfile(archive): raise ValueError(f"Not a readable ZIP: {archive}")
    if args.restore:
        if not backup.is_file() or not zipfile.is_zipfile(backup): raise ValueError("Backup is missing or unreadable")
        before, restored = sha256_file(archive), sha256_file(backup)
        fd, temp_name = tempfile.mkstemp(prefix=archive.name + ".", suffix=".restore.tmp", dir=archive.parent); os.close(fd)
        temp = Path(temp_name)
        try:
            shutil.copyfile(backup, temp)
            with zipfile.ZipFile(temp) as check:
                if check.testzip(): raise IOError("Backup ZIP failed validation")
            os.replace(temp, archive)
        finally:
            if temp.exists(): temp.unlink()
        report.parent.mkdir(parents=True, exist_ok=True)
        report.write_text(json.dumps({"action": "restore", "before_sha256": before, "after_sha256": restored, "backup_sha256": restored}, indent=2) + "\n", encoding="utf-8")
        state_path = Path(str(archive) + STATE_SUFFIX)
        state_path.write_text(json.dumps({"original_sha256": restored, "backup_sha256": restored, "last_output_sha256": restored}, indent=2) + "\n", encoding="utf-8")
        print(json.dumps({"action": "restore", "before_sha256": before, "after_sha256": restored}, indent=2))
        return 0
    if args.overlay is None: raise ValueError("--overlay is required unless --restore is used")
    overlay_root = args.overlay
    state_path = Path(str(archive) + STATE_SUFFIX)
    current_hash = sha256_file(archive)
    if not backup.exists(): copy_backup_once(archive, backup)
    backup_hash = sha256_file(backup)
    state = json.loads(state_path.read_text(encoding="utf-8")) if state_path.exists() else {}
    if state and state.get("backup_sha256") != backup_hash: raise RuntimeError("Backup hash does not match recorded state")
    if state and current_hash != state.get("last_output_sha256"):
        raise RuntimeError("Archive changed since the last injection; possible game update or external edit. Re-inspect before applying.")
    overlay = read_overlay(overlay_root)
    new_bytes, changed = updated_zip_bytes(archive, overlay)
    new_hash = hashlib.sha256(new_bytes).hexdigest()
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps({"archive": str(archive), "before_sha256": current_hash, "after_sha256": new_hash, "backup": str(backup), "backup_sha256": backup_hash, "changed_entries": changed}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if new_hash != current_hash:
        fd, temp_name = tempfile.mkstemp(prefix=archive.name + ".", suffix=".tmp", dir=archive.parent)
        os.close(fd)
        temp = Path(temp_name)
        try:
            temp.write_bytes(new_bytes)
            with zipfile.ZipFile(temp) as check: bad = check.testzip()
            if bad: raise IOError(f"Resulting ZIP failed validation at {bad}")
            os.replace(temp, archive)
        finally:
            if temp.exists(): temp.unlink()
    state_path.write_text(json.dumps({"original_sha256": backup_hash, "backup_sha256": backup_hash, "last_output_sha256": new_hash}, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"before_sha256": current_hash, "after_sha256": new_hash, "changed_entries": changed}, ensure_ascii=False, indent=2))
    return 0

if __name__ == "__main__": raise SystemExit(main())
