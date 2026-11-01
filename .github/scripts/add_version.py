# テスト用のWeb版（GitHubのページ）で、古い版が出ないようにする。
#
# GitHubのページは、どのファイルも10分間ブラウザに残す（Cache-Control: max-age=600）。
# そのため、直したあとに開いても、前の main.dart.js が出てしまうことがある。
# ここでは、組み立てたあとの build/web を書き換えて、
#   1. main.dart.js と flutter_bootstrap.js に「?v=版の番号」をつける（新しい版は新しい名前になる）
#   2. 開いたときに build.json（いまの版の番号）を毎回取りに行き、
#      古いページが出ていたら、新しい版のリンク（?v=番号）へ自動で移る
#   3. 使っていない service worker の登録をやめる
# 手元（Android Studio）での実行には関係しない。CIの中だけで使う。
#
# 使い方: python3 .github/scripts/add_version.py build/web <版の番号>

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

web = Path(sys.argv[1])
v = sys.argv[2]
if not re.fullmatch(r"[0-9a-f]{7,40}", v):
    sys.exit(f"版の番号がおかしい: {v}")


def must_replace(text, old, new, where, count=1):
    n = text.count(old)
    if n < count:
        sys.exit(f"{where} に「{old}」が見つからない（Flutterの形が変わったかもしれない）")
    return text.replace(old, new)


# 1. flutter_bootstrap.js：main.dart.js に番号をつけ、service worker の登録をやめる
bp = web / "flutter_bootstrap.js"
b = bp.read_text(encoding="utf-8")
b = must_replace(b, '"mainJsPath":"main.dart.js"', f'"mainJsPath":"main.dart.js?v={v}"', bp.name)
b, n = re.subn(r"_flutter\.loader\.load\(\{[\s\S]*?\}\);\s*$", "_flutter.loader.load();\n", b)
if n != 1:
    sys.exit("flutter_bootstrap.js の最後の _flutter.loader.load(...) が見つからない")
bp.write_text(b, encoding="utf-8")

# 2. いまの版の番号を置く（開いたページが、これと比べる）
(web / "build.json").write_text(
    json.dumps({"v": v, "at": datetime.now(timezone.utc).isoformat(timespec="seconds")}),
    encoding="utf-8",
)

# 3. index.html：flutter_bootstrap.js に番号をつけ、古いページなら新しい版へ移る小さな仕組みを入れる
ip = web / "index.html"
h = ip.read_text(encoding="utf-8")
h = must_replace(h, 'src="flutter_bootstrap.js"', f'src="flutter_bootstrap.js?v={v}"', ip.name)
checker = f"""<script>
  // 古い版が出ていたら、新しい版のリンクへ移る（テスト用のページだけ）
  (function () {{
    var mine = "{v}";
    try {{
      fetch("build.json?t=" + Date.now(), {{ cache: "no-store" }})
        .then(function (r) {{ return r.ok ? r.json() : null; }})
        .then(function (d) {{
          if (!d || !d.v || d.v === mine) return;
          var u = new URL(location.href);
          if (u.searchParams.get("v") === d.v) return;
          u.searchParams.set("v", d.v);
          location.replace(u.toString());
        }})
        .catch(function () {{}});
    }} catch (e) {{}}
  }})();
</script>
"""
h = must_replace(h, "<body>", "<body>\n" + checker, ip.name)
ip.write_text(h, encoding="utf-8")

print(f"版の番号 {v} をつけました")
