#!/usr/bin/env python3
"""Inline src/ (HTML, CSS, JS, data.json, fonts, images) into one self-contained HTML file."""
import base64, json, re, sys, pathlib
src = pathlib.Path(sys.argv[1]); out = pathlib.Path(sys.argv[2])
MIME = {".webp": "image/webp", ".woff2": "font/woff2", ".png": "image/png", ".jpg": "image/jpeg", ".svg": "image/svg+xml"}
def uri(rel):
    p = src / rel
    return "data:%s;base64,%s" % (MIME[p.suffix], base64.b64encode(p.read_bytes()).decode())
css = (src / "styles.css").read_text()
css = re.sub(r"url\((?:\"|')?((?:img|fonts)/[^)\"']+)(?:\"|')?\)", lambda m: "url(%s)" % uri(m.group(1)), css)
js = (src / "app.js").read_text()
data = json.dumps(json.loads((src / "data.json").read_text()), ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
html = (src / "index.html").read_text()
for k, v in (("/*@@CSS@@*/", css), ("/*@@JS@@*/", js.replace("</script", "<\\/script")), ("/*@@DATA@@*/", data)):
    assert k in html, k
    html = html.replace(k, v)
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(html)
print("bundled %s (%d KB)" % (out, out.stat().st_size // 1024))
