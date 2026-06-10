# Vendored Lua sources — provenance

File: `VENDORED-LUA.md`
Location: `Sources/` (relative to the project root).
Context: provenance record for the Lua C sources bundled under
`Sources/CLua*`. It is the audit trail for where each vendored Lua release came
from, the SHA256 of the exact tarball it was extracted from, and when it was
last updated. It is read by humans reviewing supply-chain integrity; it is
written (the table rows) by the `.github/workflows/lua-version-check.yml`
workflow whenever it updates a series, and may also be edited by hand for an
out-of-band update.

## Why this file exists

The bundled C sources are extracted from the official Lua release tarballs
published at <https://www.lua.org/ftp/>. There is no way to recover, from the
checked-in `.c`/`.h` files alone, which tarball they came from or whether that
tarball was authentic. This manifest closes that gap: every vendored series
records its source URL, the official SHA256 of the tarball, and the date the
sources were last refreshed.

The update workflow verifies each freshly downloaded tarball against the SHA256
published by lua.org (in the `checksum (sha256)` column of the FTP listing it
already fetches) **before** the tarball is allowed to replace any vendored
source. A mismatch fails the job. The same verified checksum is then recorded
in the table below, so the record always reflects what was actually shipped.

## Provenance table

Each row is one bundled Lua series. `Source directory` is the `Sources/CLua*`
folder that holds that series' sources. `SHA256` is the checksum of the source
tarball as published by lua.org and verified at download time.

| Series | Version | Source directory   | Source tarball                                  | SHA256                                                             | Updated    |
| ------ | ------- | ------------------ | ----------------------------------------------- | ------------------------------------------------------------------ | ---------- |
| 5.1    | 5.1.5   | `Sources/CLua51`   | https://www.lua.org/ftp/lua-5.1.5.tar.gz        | `2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333` | 2024-06-13 |
| 5.2    | 5.2.4   | `Sources/CLua52`   | https://www.lua.org/ftp/lua-5.2.4.tar.gz        | `b9e2e4aad6789b3b63a056d442f7b39f0ecfca3ae0f1fc0ae4e9614401b69f4b` | 2024-06-13 |
| 5.3    | 5.3.6   | `Sources/CLua53`   | https://www.lua.org/ftp/lua-5.3.6.tar.gz        | `fc5fd69bb8736323f026672b1b7235da613d7177e72558893a0bdcd320466d60` | 2024-06-13 |
| 5.4    | 5.4.7   | `Sources/CLua`     | https://www.lua.org/ftp/lua-5.4.7.tar.gz        | `9fbf5e28ef86c69858f6d3d34eccc32e911c1a28b4120ff3e84aaa70cfbf1e30` | 2024-06-13 |
| 5.5    | 5.5.0   | `Sources/CLua55`   | https://www.lua.org/ftp/lua-5.5.0.tar.gz        | `57ccc32bbbd005cab75bcc52444052535af691789dba2b9016d5c50640d68b3d` | 2024-06-13 |

The SHA256 values above are the checksums published by lua.org for these
releases. The `Updated` column records the tarball's publication date for the
initial provenance backfill; the workflow overwrites it with the actual update
date (UTC) on its next automated refresh of a series.
