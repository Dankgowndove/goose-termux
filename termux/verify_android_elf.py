#!/usr/bin/env python3
"""Validate that a goose binary is loadable by Android's bionic linker.

Checks the ELF header (AArch64 PIE), the PT_INTERP path, the PT_TLS alignment
bionic requires and the page alignment needed by 16 KiB page-size devices.
"""
import struct
import sys

EXPECTED_INTERPRETER = "/system/bin/linker64"
EM_AARCH64 = 0xB7
ET_DYN = 3
PT_LOAD = 1
PT_INTERP = 3
PT_TLS = 7
BIONIC_TLS_ALIGN = 64
PAGE_ALIGN = 0x1000


def fail(message):
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def main(path):
    data = open(path, "rb").read()
    if data[:4] != b"\x7fELF" or data[4] != 2:
        fail("not a 64-bit ELF file")

    e_type, e_machine = struct.unpack_from("<HH", data, 0x10)
    if e_machine != EM_AARCH64:
        fail(f"unexpected machine {e_machine:#x}, want AArch64")
    if e_type != ET_DYN:
        fail(f"unexpected ELF type {e_type}, want PIE ({ET_DYN})")

    e_phoff = struct.unpack_from("<Q", data, 0x20)[0]
    e_phentsize = struct.unpack_from("<H", data, 0x36)[0]
    e_phnum = struct.unpack_from("<H", data, 0x38)[0]

    interpreter = None
    tls_align = None
    load_aligns = []
    for index in range(e_phnum):
        (p_type, _flags, p_offset, _vaddr, _paddr, p_filesz, _memsz, p_align) = struct.unpack_from(
            "<IIQQQQQQ", data, e_phoff + index * e_phentsize
        )
        if p_type == PT_INTERP:
            interpreter = data[p_offset : p_offset + p_filesz].rstrip(b"\0").decode()
        elif p_type == PT_TLS:
            tls_align = p_align
        elif p_type == PT_LOAD:
            load_aligns.append(p_align)

    print(f"interpreter: {interpreter}")
    print(f"TLS alignment: {hex(tls_align) if tls_align else 'absent'}")
    print(f"LOAD alignments: {[hex(align) for align in load_aligns]}")

    if interpreter != EXPECTED_INTERPRETER:
        fail(f"unexpected interpreter {interpreter!r}, want {EXPECTED_INTERPRETER!r}")
    if tls_align is not None and tls_align < BIONIC_TLS_ALIGN:
        fail(f"TLS alignment {tls_align:#x} is below bionic's required 0x40")
    if load_aligns and min(load_aligns) < PAGE_ALIGN:
        fail("loadable segments are not page aligned")
    print("ok: binary matches bionic requirements")


if __name__ == "__main__":
    main(sys.argv[1])
