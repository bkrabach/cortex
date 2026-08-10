#!/usr/bin/env python3
"""Cortex hub -- the distribution page on :7080.

Serves exactly four things:
  GET  /                 pairing instructions, gateway URL, pairing-code button
  GET  /cortex.apk       the Android build, straight out of the dist dir
  GET  /healthz          liveness for `cortex doctor`
  POST /pair/new         mint a single-use pairing code via the gateway's own CLI

Honest by construction:
  - If the APK is not built yet, /cortex.apk is a 404 that SAYS the build is
    missing. It never serves a placeholder file that would install as a broken
    app on the stakeholder's phone.
  - If QR rendering is unavailable, the page says so and shows the URL as text.
    It never renders a broken image tag.
  - The QR encodes THIS page, never the gateway address: the Android app has no
    QR scanner, so a gateway QR could only ever be a dead end.
  - /pair/new does not implement pairing. It shells `cortex-gateway pair` and
    returns what that prints. If the gateway CLI is missing or fails, it answers
    503 naming the remedy and mints nothing -- a hub-invented code would not be
    redeemable by the gateway that has to honour it.

Stdlib only, except optional `segno` for the QR.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import html
import http.server
import json
import os
import re
import shutil
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


# ------------------------------------------------------------------ minting
# The hub does NOT implement pairing. The gateway owns the pairing rail; the
# only mint surface is its own `cortex-gateway pair`, which writes the code
# hash to the gateway's pairings rail and logs the mint as a gateway event.
# We shell that CLI and parse what it prints. If it is missing or fails, we
# say so and mint nothing -- a hub-invented code would not be redeemable, and
# handing the stakeholder a code that cannot work is the exact failure this
# page exists to end.

GATEWAY_BIN_CANDIDATES = ("cortex-gateway", "gateway", "cortexgateway")
CODE_RE = re.compile(r"([0-9a-f]{4}-[0-9a-f]{4})", re.IGNORECASE)
EXPIRES_RE = re.compile(r"^expires:\s*(\S+)\s*$", re.IGNORECASE | re.MULTILINE)


class MintError(RuntimeError):
    """Minting failed. `.remedy` names what the operator must do about it."""

    def __init__(self, message: str, remedy: str):
        super().__init__(message)
        self.detail = message
        self.remedy = remedy


def find_gateway_bin(explicit: str | None = None) -> str | None:
    """Locate the co-located gateway CLI. Same search order as `cortex`."""
    if explicit:
        return explicit if os.access(explicit, os.X_OK) else None
    home = Path.home() / ".local/share/cortex/gateway/venv/bin"
    for name in GATEWAY_BIN_CANDIDATES:
        cand = home / name
        if cand.is_file() and os.access(cand, os.X_OK):
            return str(cand)
    for name in GATEWAY_BIN_CANDIDATES:
        found = shutil.which(name)
        if found:
            return found
    return None


def mint_pairing_code(gateway_bin: str | None, env_overrides: dict, label: str) -> dict:
    """Run `cortex-gateway pair` and return {code, expires_at}.

    Raises MintError -- never returns a fabricated or partial result.
    """
    binpath = find_gateway_bin(gateway_bin)
    if not binpath:
        raise MintError(
            "the cortex-gateway CLI was not found on this host",
            "install the gateway (install.sh), or start the hub with "
            "--gateway-bin /path/to/cortex-gateway",
        )
    env = {**os.environ, **env_overrides}
    try:
        proc = subprocess.run(
            [binpath, "pair", "--label", label[:64]],
            capture_output=True, timeout=20, env=env, check=False,
        )
    except (subprocess.SubprocessError, OSError) as e:
        raise MintError(
            f"could not run {binpath} pair -- {e}",
            "check that the gateway venv is intact, then re-run `cortex doctor`",
        ) from e

    out = proc.stdout.decode("utf-8", "replace")
    err = proc.stderr.decode("utf-8", "replace")
    if proc.returncode != 0:
        raise MintError(
            f"`cortex-gateway pair` exited {proc.returncode}: "
            f"{(err or out).strip().splitlines()[-1] if (err or out).strip() else 'no output'}",
            "run `cortex-gateway setup` if the gateway is not configured, then `cortex doctor`",
        )

    code_m = CODE_RE.search(out)
    exp_m = EXPIRES_RE.search(out)
    if not code_m or not exp_m:
        raise MintError(
            "`cortex-gateway pair` succeeded but its output could not be parsed "
            f"(got: {out.strip()[:200]!r})",
            "the gateway CLI's output format changed; the hub must be updated to match",
        )
    return {"code": code_m.group(1), "expires_at": exp_m.group(1)}


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
 .btn {{ display:block; width:100%; text-align:center; background:#2b6cff; color:#fff;
         text-decoration:none; font-weight:600; padding:.85rem 1rem; font-size:1rem;
         border:0; border-radius:10px; font-family:inherit; cursor:pointer; }}
 .btn:hover:not(:disabled) {{ background:#1f5ae0; }}
 .btn:disabled {{ background:#2a2a30; color:#8a8a92; cursor:progress; }}
 .btn.off {{ background:#2a2a30; color:#8a8a92; cursor:not-allowed; }}
 .code {{ font-family:ui-monospace,SFMono-Regular,Menlo,monospace; font-size:2rem;
          letter-spacing:.06em; text-align:center; color:#7ef0a8; background:#0f1a12;
          border:1px solid #1f3a27; border-radius:10px; padding:.9rem;
          margin:1rem 0 .25rem; user-select:all; }}
 .step {{ margin:0; }}
 ol {{ margin:0; padding-left:1.3rem; }} ol li {{ margin:.55rem 0; }}
 .meta {{ color:#9a9aa2; font-size:.85rem; text-align:center; margin:.6rem 0 0; }}
 .note {{ border-left:3px solid #b8860b; background:#1b1710; padding:.75rem 1rem;
          border-radius:0 8px 8px 0; color:#d9cdae; font-size:.9rem; }}
 footer {{ color:#6a6a72; font-size:.8rem; margin-top:2.5rem; text-align:center; }}
</style>
<div class="wrap">
  <h1>Cortex</h1>
  <p class="sub">Install on the phone, then pair. Five steps, about two minutes.</p>

  <div class="card">
    <h2>Step 1 &middot; Install the app</h2>
    {apk_block}
  </div>

  <div class="card">
    <h2>Step 2 &middot; Open Cortex, tap Settings</h2>
    <p class="step">The app opens on a screen that says
      <em>&ldquo;Not paired &mdash; open Settings to pair with your gateway.&rdquo;</em>
      Tap <b>Settings</b> at the top right. That opens
      <b>Pair with gateway</b>, which has two fields.</p>
  </div>

  <div class="card">
    <h2>Step 3 &middot; Type this into &ldquo;Gateway URL&rdquo;</h2>
    <span class="url">{gateway_url}</span>
    <p class="meta">The field is pre-filled with an emulator address. Replace it
      with the address above, exactly as shown &mdash; including
      <code>https://</code> and the port.</p>
  </div>

  <div class="card">
    <h2>Step 4 &middot; Get a pairing code</h2>
    <button id="mintbtn" class="btn" type="button">Get pairing code</button>
    <div id="mintout" aria-live="polite"></div>
    <p class="meta">Minted by this gateway on demand. Single use, and it expires
      &mdash; get it when you are ready to type it, not before.</p>
  </div>

  <div class="card">
    <h2>Step 5 &middot; Enter the code, tap Pair</h2>
    <p class="step">Type the code into the second field, <b>Pairing code</b>, and
      tap <b>Pair</b>. The log underneath will show
      <code>&rarr; POST /v1/pair</code> then <code>&#10003; paired</code>.
      That is the whole handshake &mdash; the app now has its own key and the
      code is spent.</p>
  </div>

  <div class="card">
    <h2>Open this page on the phone</h2>
    {qr_block}
    <span class="url">{hub_url}</span>
    <p class="meta">Scan this to open <em>this page</em> on the phone &mdash; that
      is all this QR does. Cortex has no QR scanner of its own; pairing is done
      by typing the code from step 4.</p>
  </div>

  <div class="card">
    <h2>What to expect</h2>
    <ol>
      <li>Android will warn about installing outside the Play Store. Allow it for
          your browser &mdash; this is a direct build, not a store release.</li>
      <li>On first launch Cortex asks for notification and microphone access.
          Both are needed: notifications for <em>Texting</em>, the mic for
          <em>Calling</em>.</li>
      <li>The gateway uses its own certificate authority. The app pins it during
          pairing and prints the fingerprint in its log &mdash; that is expected.</li>
      <li>Say &ldquo;what needs me?&rdquo; to check the connection end to end.</li>
    </ol>
  </div>

  <footer>cortex hub &middot; {host} &middot; generated {now}</footer>
</div>
{script}
"""

PAGE_SCRIPT = """<script>
(function () {
  var btn = document.getElementById('mintbtn');
  var out = document.getElementById('mintout');
  if (!btn || !out) { return; }
  btn.addEventListener('click', function () {
    btn.disabled = true;
    var was = btn.textContent;
    btn.textContent = 'Minting...';
    out.innerHTML = '';
    fetch('/pair/new', { method: 'POST', headers: { 'Accept': 'application/json' } })
      .then(function (r) { return r.json().then(function (j) { return [r.ok, j]; }); })
      .then(function (pair) {
        var ok = pair[0], data = pair[1];
        if (ok && data.code) {
          out.innerHTML =
            '<div class="code">' + data.code + '</div>' +
            '<p class="meta">Single use &middot; expires ' + (data.expires_at || 'unknown') + '</p>';
        } else {
          out.innerHTML =
            '<p class="note"><b>No code was minted.</b><br>' +
            (data.detail || 'the gateway did not return a code') +
            (data.remedy ? '<br>Remedy: ' + data.remedy : '') + '</p>';
        }
      })
      .catch(function (e) {
        out.innerHTML =
          '<p class="note"><b>No code was minted.</b><br>could not reach this hub: ' +
          e + '<br>Remedy: reload this page; if it persists, run <code>cortex status</code>.</p>';
      })
      .then(function () { btn.disabled = false; btn.textContent = was; });
  });
})();
</script>"""

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
    hub_port: int
    gateway_bin: str | None = None
    gateway_env: dict | None = None

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
        elif path == "/pair/new":
            self._send(
                405,
                b'{"detail":"POST /pair/new to mint a pairing code -- GET does not mint, '
                b'so a code is never handed out by a link preview or a crawler."}\n',
                "application/json",
                {"Allow": "POST"},
            )
        else:
            self._send(404, b"not found\n", "text/plain; charset=utf-8")

    def do_POST(self) -> None:
        path = self.path.split("?", 1)[0].rstrip("/") or "/"
        if path == "/pair/new":
            self._mint()
        else:
            self._send(404, b'{"detail":"not found"}\n', "application/json")

    def _mint(self) -> None:
        """Mint a pairing code via the gateway's own CLI. Never invents one."""
        peer = self.client_address[0] if self.client_address else "?"
        label = f"hub-page {peer}"
        try:
            result = mint_pairing_code(self.gateway_bin, self.gateway_env or {}, label)
        except MintError as e:
            # Loud on the way out: a refused mint is a thing the operator must
            # be able to see in `cortex logs hub` without asking the phone.
            sys.stderr.write(
                f"{self.log_date_time_string()}  PAIR-MINT REFUSED  peer={peer}  "
                f"reason={e.detail}  remedy={e.remedy}\n"
            )
            body = json.dumps({"detail": e.detail, "remedy": e.remedy}, indent=1) + "\n"
            self._send(503, body.encode(), "application/json")
            return
        # The code itself is a credential with a live TTL, so it is deliberately
        # NOT written to the log -- everything needed to audit the mint is.
        sys.stderr.write(
            f"{self.log_date_time_string()}  PAIR-MINT OK  peer={peer}  "
            f"label={label!r}  expires_at={result['expires_at']}  "
            f"(code withheld from log by design; single use)\n"
        )
        body = json.dumps({**result, "single_use": True}, indent=1) + "\n"
        self._send(200, body.encode(), "application/json")

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
        # The phone must reach the gateway by an address it can actually route
        # to. If this page was opened on loopback, the Host header says so --
        # and a phone cannot use that, so fall back to the LAN address.
        if host in ("127.0.0.1", "localhost", "::1"):
            host = lan_ip()
        gateway_url = f"https://{host}:{self.gateway_port}"
        hub_url = f"http://{host}:{self.hub_port}/"
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

        # The QR encodes THIS page, not the gateway. The app has no scanner, so
        # a QR of the gateway address was only ever readable by a generic
        # camera app -- which then had nowhere to put it.
        svg = qr_svg(hub_url)
        qr_block = f'<div class="qr">{svg}</div>' if svg else QR_MISSING

        return PAGE.format(
            apk_block=apk_block,
            qr_block=qr_block,
            gateway_url=html.escape(gateway_url),
            hub_url=html.escape(hub_url),
            host=html.escape(host),
            now=_dt.datetime.now().astimezone().strftime("%Y-%m-%d %H:%M"),
            script=PAGE_SCRIPT,
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
    p.add_argument("--gateway-bin", default=os.environ.get("CORTEX_GATEWAY_BIN"),
                   help="path to the cortex-gateway CLI used to mint pairing codes; "
                        "default: the co-located install, then PATH")
    p.add_argument("--gateway-config-dir", default=os.environ.get("CORTEX_GATEWAY_CONFIG_DIR"),
                   help="config dir handed to `cortex-gateway pair` (default: its own)")
    p.add_argument("--gateway-state-dir", default=os.environ.get("CORTEX_GATEWAY_STATE_DIR"),
                   help="state dir handed to `cortex-gateway pair` (default: its own)")
    args = p.parse_args(argv)

    Handler.dist_dir = Path(args.dist_dir)
    Handler.gateway_port = args.gateway_port
    Handler.hub_port = args.port
    Handler.gateway_bin = args.gateway_bin
    Handler.gateway_env = {
        k: v
        for k, v in (
            ("CORTEX_GATEWAY_CONFIG_DIR", args.gateway_config_dir),
            ("CORTEX_GATEWAY_STATE_DIR", args.gateway_state_dir),
        )
        if v
    }

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
    gwbin = find_gateway_bin(Handler.gateway_bin)
    print(
        f"  pair minting: {gwbin}" if gwbin else
        "  pair minting: UNAVAILABLE -- cortex-gateway CLI not found; /pair/new will"
        " answer 503 naming the remedy rather than invent a code",
        flush=True,
    )
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("cortex hub stopping", flush=True)
    finally:
        srv.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
