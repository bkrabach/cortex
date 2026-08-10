#!/usr/bin/env python3
"""Cortex hub -- the distribution page on :7080.

Serves exactly three things:
  GET  /                 pairing instructions, gateway URL, QR code
  GET  /cortex.apk       the Android build, straight out of the dist dir
  GET  /healthz          liveness for `cortex doctor`

Honest by construction:
  - If the APK is not built yet, /cortex.apk is a 404 that SAYS the build is
    missing. It never serves a placeholder file that would install as a broken
    app on the stakeholder's phone.
  - If QR rendering is unavailable, the page says so and shows the URL as text.
    It never renders a broken image tag.

Stdlib only, except optional `segno` for the QR.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import html
import http.server
import os
import socket
import socketserver
import subprocess
import sys
from pathlib import Path

DEFAULT_PORT = 7080
DEFAULT_GATEWAY_PORT = 7443
APK_NAME = "cortex.apk"


# --------------------------------------------------------------------- helpers
def lan_ip() -> str:
    """Best-effort LAN address. Falls back to loopback, never guesses wildly."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(("192.0.2.1", 9))  # TEST-NET-1: routed nowhere, no packet sent
            return s.getsockname()[0]
        finally:
            s.close()
    except OSError:
        return "127.0.0.1"


def qr_svg(data: str) -> str | None:
    """Inline SVG QR, or None if we cannot render one. Never returns a stub."""
    try:
        import segno  # type: ignore
    except ImportError:
        pass
    else:
        import io

        # segno's svg writer emits bytes; xmldecl off so the SVG can be inlined
        # into the HTML document rather than sitting behind an <img>.
        buf = io.BytesIO()
        segno.make(data, error="m").save(
            buf, kind="svg", scale=6, border=2, dark="#0b0b0c", xmldecl=False
        )
        return buf.getvalue().decode("utf-8")

    qrencode = None
    for candidate in ("/usr/bin/qrencode", "/usr/local/bin/qrencode"):
        if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            qrencode = candidate
            break
    if qrencode:
        try:
            out = subprocess.run(
                [qrencode, "-t", "SVG", "-o", "-", data],
                capture_output=True, timeout=10, check=True,
            )
            return out.stdout.decode("utf-8", "replace")
        except (subprocess.SubprocessError, OSError):
            return None
    return None


def human_size(num_bytes: int) -> str:
    size = float(num_bytes)
    for unit in ("B", "KB", "MB", "GB"):
        if size < 1024 or unit == "GB":
            return f"{size:.0f} {unit}" if unit == "B" else f"{size:.1f} {unit}"
        size /= 1024.0
    return f"{size:.1f} GB"


# ------------------------------------------------------------------------ page
PAGE = """<!doctype html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Cortex &mdash; install</title>
<style>
 :root {{ color-scheme: dark; }}
 * {{ box-sizing: border-box; }}
 body {{ margin:0; background:#0b0b0c; color:#e8e8ea;
        font:16px/1.55 ui-sans-serif,-apple-system,"Segoe UI",Roboto,sans-serif; }}
 .wrap {{ max-width:44rem; margin:0 auto; padding:2.5rem 1.25rem 4rem; }}
 h1 {{ font-size:2rem; margin:0 0 .25rem; letter-spacing:-.02em; }}
 .sub {{ color:#9a9aa2; margin:0 0 2.5rem; }}
 .card {{ background:#141417; border:1px solid #26262b; border-radius:14px;
          padding:1.5rem; margin:0 0 1.25rem; }}
 .card h2 {{ font-size:.8rem; text-transform:uppercase; letter-spacing:.09em;
             color:#9a9aa2; margin:0 0 1rem; font-weight:600; }}
 .qr {{ background:#fff; border-radius:10px; padding:.75rem; width:max-content;
        margin:0 auto 1rem; }}
 .qr svg {{ display:block; width:190px; height:190px; }}
 code, .url {{ font-family:ui-monospace,SFMono-Regular,Menlo,monospace; }}
 .url {{ display:block; text-align:center; font-size:1.05rem; color:#8ab4ff;
         word-break:break-all; }}
 a.btn {{ display:block; text-align:center; background:#2b6cff; color:#fff;
          text-decoration:none; font-weight:600; padding:.85rem 1rem;
          border-radius:10px; }}
 a.btn:hover {{ background:#1f5ae0; }}
 .btn.off {{ background:#2a2a30; color:#8a8a92; cursor:not-allowed; }}
 ol {{ margin:0; padding-left:1.3rem; }} ol li {{ margin:.55rem 0; }}
 .meta {{ color:#9a9aa2; font-size:.85rem; text-align:center; margin:.6rem 0 0; }}
 .note {{ border-left:3px solid #b8860b; background:#1b1710; padding:.75rem 1rem;
          border-radius:0 8px 8px 0; color:#d9cdae; font-size:.9rem; }}
 footer {{ color:#6a6a72; font-size:.8rem; margin-top:2.5rem; text-align:center; }}
</style>
<div class="wrap">
  <h1>Cortex</h1>
  <p class="sub">Your chief of staff. Install on the phone, then pair.</p>

  <div class="card">
    <h2>1 &middot; Install the app</h2>
    {apk_block}
  </div>

  <div class="card">
    <h2>2 &middot; Pair with this gateway</h2>
    {qr_block}
    <span class="url">{gateway_url}</span>
    <p class="meta">Open Cortex &rarr; Pair &rarr; scan, or type the address above.</p>
  </div>

  <div class="card">
    <h2>3 &middot; What to expect</h2>
    <ol>
      <li>Android will warn about installing outside the Play Store. Allow it for
          your browser &mdash; this is a direct build, not a store release.</li>
      <li>On first launch Cortex asks for notification and microphone access.
          Both are needed: notifications for <em>Texting</em>, the mic for
          <em>Calling</em>.</li>
      <li>The gateway uses a self-signed certificate. The app is built to trust
          this one &mdash; accept it when prompted.</li>
      <li>Say &ldquo;what needs me?&rdquo; to check the connection end to end.</li>
    </ol>
  </div>

  <footer>cortex hub &middot; {host} &middot; generated {now}</footer>
</div>
"""

APK_READY = """<a class="btn" href="/{name}" download>Download Cortex for Android</a>
    <p class="meta">{size} &middot; built {mtime}</p>"""

APK_MISSING = """<span class="btn off">Android build not available</span>
    <p class="note">No APK has been published to this hub yet. The download link
    goes live the moment a build lands in <code>{dist}</code> &mdash; no reinstall,
    no restart. Nothing is served in its place, so you cannot install a stub by
    mistake.</p>"""

QR_MISSING = """<p class="note">QR rendering is unavailable on this host, so the
    address is shown as text below. Remedy: install <code>segno</code> into the
    hub environment, then restart the hub.</p>"""


class Handler(http.server.BaseHTTPRequestHandler):
    server_version = "cortex-hub/0.1"
    dist_dir: Path
    gateway_port: int

    # Keep the tmux log readable: one line per request, no client noise.
    def log_message(self, format: str, *args) -> None:  # noqa: A002 - base class name
        sys.stderr.write(f"{self.log_date_time_string()}  {format % args}\n")

    def _send(self, code: int, body: bytes, ctype: str, extra: dict | None = None) -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def do_HEAD(self) -> None:
        self.do_GET()

    def do_GET(self) -> None:
        path = self.path.split("?", 1)[0].rstrip("/") or "/"
        if path == "/":
            self._send(200, self._page().encode(), "text/html; charset=utf-8")
        elif path == f"/{APK_NAME}":
            self._apk()
        elif path == "/healthz":
            self._send(200, b'{"ok":true,"service":"cortex-hub"}\n', "application/json")
        else:
            self._send(404, b"not found\n", "text/plain; charset=utf-8")

    def _apk(self) -> None:
        apk = self.dist_dir / APK_NAME
        if not apk.is_file():
            msg = (
                f"404 no Android build published\n\n"
                f"Expected: {apk}\n\n"
                f"The APK has not been built yet. This hub deliberately serves a 404\n"
                f"rather than a placeholder file -- a placeholder would install as a\n"
                f"broken app. Drop a real build at the path above and reload; the\n"
                f"download goes live with no restart.\n"
            )
            self._send(404, msg.encode(), "text/plain; charset=utf-8")
            return
        data = apk.read_bytes()
        self._send(
            200, data, "application/vnd.android.package-archive",
            {"Content-Disposition": f'attachment; filename="{APK_NAME}"'},
        )

    def _page(self) -> str:
        host = self.headers.get("Host", "").split(":")[0] or lan_ip()
        gateway_url = f"https://{host}:{self.gateway_port}/"
        apk = self.dist_dir / APK_NAME
        if apk.is_file():
            st = apk.stat()
            apk_block = APK_READY.format(
                name=APK_NAME,
                size=human_size(st.st_size),
                mtime=_dt.datetime.fromtimestamp(st.st_mtime, tz=_dt.timezone.utc).astimezone().strftime("%Y-%m-%d %H:%M"),
            )
        else:
            apk_block = APK_MISSING.format(dist=html.escape(str(self.dist_dir)))

        svg = qr_svg(gateway_url)
        qr_block = f'<div class="qr">{svg}</div>' if svg else QR_MISSING

        return PAGE.format(
            apk_block=apk_block,
            qr_block=qr_block,
            gateway_url=html.escape(gateway_url),
            host=html.escape(host),
            now=_dt.datetime.now().astimezone().strftime("%Y-%m-%d %H:%M"),
        )


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Cortex hub -- distribution and pairing page")
    p.add_argument("--port", type=int, default=int(os.environ.get("CORTEX_HUB_PORT", DEFAULT_PORT)))
    p.add_argument("--host", default="0.0.0.0",
                   help="bind address; the phone must reach this, so it is not loopback-only")
    p.add_argument("--dist-dir", default=os.environ.get(
        "CORTEX_DIST_DIR", str(Path.home() / ".local/share/cortex/dist")))
    p.add_argument("--gateway-port", type=int, default=int(
        os.environ.get("CORTEX_GATEWAY_PORT", DEFAULT_GATEWAY_PORT)))
    args = p.parse_args(argv)

    Handler.dist_dir = Path(args.dist_dir)
    Handler.gateway_port = args.gateway_port

    try:
        srv = Server((args.host, args.port), Handler)
    except OSError as e:
        print(
            f"error: cannot bind {args.host}:{args.port} -- {e}\n"
            f"  remedy: something already holds that port. Find it with\n"
            f"          ss -ltnp | grep :{args.port}\n"
            f"          and stop it, or run the hub on another port.",
            file=sys.stderr,
        )
        return 1

    ip = lan_ip()
    print(f"cortex hub listening on http://{ip}:{args.port}/", flush=True)
    print(f"  dist dir:     {Handler.dist_dir}", flush=True)
    print(f"  apk:          {'present' if (Handler.dist_dir / APK_NAME).is_file() else 'NOT BUILT YET (serving 404)'}", flush=True)
    print(f"  qr rendering: {'enabled' if qr_svg('probe') else 'UNAVAILABLE (page shows URL as text)'}", flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("cortex hub stopping", flush=True)
    finally:
        srv.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
