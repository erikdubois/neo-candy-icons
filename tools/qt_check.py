#!/usr/bin/env python3
"""Flag SVGs that QtSvg (Plasma) draws visibly different from rsvg (GTK): qt_check.py <file>..."""
import os
import subprocess
import sys
import tempfile

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
N = 48


def main():
    """Print a score per file whose Qt render differs from rsvg's; exit 0 always (warnings only)."""
    try:
        from PyQt6.QtCore import Qt
        from PyQt6.QtGui import QImage, QPainter
        from PyQt6.QtSvg import QSvgRenderer
        from PyQt6.QtWidgets import QApplication
    except ImportError:
        print("  PyQt6 not installed: QtSvg check skipped")
        return 0
    app = QApplication([])  # noqa: F841 - QImage painting needs an application object
    flagged = 0
    with tempfile.TemporaryDirectory() as tmp:
        for i, path in enumerate(sys.argv[1:]):
            if not path.endswith(".svg") or os.path.islink(path):
                continue
            png = os.path.join(tmp, f"{i}.png")
            if subprocess.run(["rsvg-convert", "-w", str(N), "-h", str(N), path, "-o", png],
                              capture_output=True, check=False).returncode:
                print(f"  rsvg cannot render: {path}")
                flagged += 1
                continue
            ref = QImage(png).convertToFormat(QImage.Format.Format_ARGB32)
            img = QImage(N, N, QImage.Format.Format_ARGB32)
            img.fill(Qt.GlobalColor.transparent)
            painter = QPainter(img)
            QSvgRenderer(path).render(painter)
            painter.end()
            diff = 0
            for y in range(N):
                for x in range(N):
                    a, b = img.pixelColor(x, y), ref.pixelColor(x, y)
                    w = b.alpha() / 255
                    diff += abs(a.alpha() - b.alpha()) + w * (abs(a.red() - b.red()) + abs(a.green() - b.green())
                                                              + abs(a.blue() - b.blue()))
            score = diff / (N * N)
            if score > 8:
                print(f"  QtSvg differs ({score:.1f}): {path}")
                flagged += 1
    print(f"  QtSvg check: {flagged} flagged of {len(sys.argv) - 1}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
