# Hexu - Simple HTTP Server in x86-64 Assembly

This project implements a basic HTTP/1.1 server written entirely in x86-64 Linux assembly using system calls directly. It handles `GET` requests and serves static files from a `public/` directory.

## Features

- Listens on port **8080** (localhost)
- Handles `GET` requests
- Parses HTTP request to extract method and path
- Constructs full path with `public/` prefix
- Serves static files with appropriate `Content-Type` headers:
  - `text/html`
  - `text/css`
  - `application/javascript`
  - `image/svg+xml`
  - `text/plain` (default)
- Returns `404 Not Found` for missing files
- Returns `501 Not Implemented` for non-GET requests
- Minimal logging to stdout for debugging

## Requirements

- Linux (x86-64)
- `nasm` (Netwide Assembler)
- `ld` (GNU linker)

## Build & Run

```bash
nasm -f elf64 -o hexu.o hexu.asm
ld -o hexu hexu.o
./hexu
```

Make sure you have a public/ directory in the same folder as the server binary with some files to serve:
public/
├── index.html
├── style.css
├── script.js
└── image.svg
Then access it via browser at: http://localhost:8080/index.html
