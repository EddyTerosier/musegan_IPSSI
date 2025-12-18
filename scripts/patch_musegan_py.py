#!/usr/bin/env python3
import sys
from pathlib import Path

def patch_tensorflow_imports(src_dir: Path):
    patched = 0
    for py_file in src_dir.rglob("*.py"):
        try:
            content = py_file.read_text(encoding="utf-8", errors="ignore")
            if "import tensorflow as tf" in content and "tensorflow.compat.v1 as tf" not in content:
                content = content.replace(
                    "import tensorflow as tf",
                    "import tensorflow.compat.v1 as tf\ntf.disable_v2_behavior()",
                    1
                )
                py_file.write_text(content, encoding="utf-8")
                patched += 1
        except Exception as e:
            print(f"Erreur sur {py_file}: {e}", file=sys.stderr)
    
    print(f"[OK] TF1-compat appliqué sur {patched} fichier(s)")

def patch_config_yaml(config_path: Path):
    if not config_path.exists():
        print(f"[WARN] Config non trouvée: {config_path}")
        return
    
    content = config_path.read_text(encoding="utf-8")
    replacements = {
        "save_pianoroll_samples:": "save_pianoroll_samples: False",
        "save_image_samples:": "save_image_samples: False",
        "save_array_samples:": "save_array_samples: True"
    }
    
    for key, value in replacements.items():
        import re
        content = re.sub(f"^{key}.*", value, content, flags=re.MULTILINE)
    
    config_path.write_text(content, encoding="utf-8")
    print(f"[OK] Config patchée: {config_path}")

def patch_io_utils(io_utils_path: Path):
    if not io_utils_path.exists():
        print(f"[WARN] io_utils.py non trouvé: {io_utils_path}")
        return
    
    content = io_utils_path.read_text(encoding="utf-8")
    content = content.replace("beat_resolution=", "resolution=")
    io_utils_path.write_text(content, encoding="utf-8")
    print(f"[OK] io_utils.py patché")

def main():
    root = Path(__file__).parent.parent
    musegan_src = root / "third_party/musegan/src"
    
    if not musegan_src.exists():
        print(f"[ERREUR] MuseGAN src introuvable: {musegan_src}", file=sys.stderr)
        sys.exit(1)
    
    print("[INFO] Patch TensorFlow imports...")
    patch_tensorflow_imports(musegan_src)
    
    config = root / "third_party/musegan/exp/default/config.yaml"
    print("[INFO] Patch config.yaml...")
    patch_config_yaml(config)
    
    io_utils = musegan_src / "musegan/io_utils.py"
    print("[INFO] Patch io_utils.py...")
    patch_io_utils(io_utils)
    
    print("[OK] Tous les patches appliqués avec succès")

if __name__ == "__main__":
    main()
