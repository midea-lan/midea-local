"""``python -m tests.lua_conformance`` entry point."""

from __future__ import annotations

import sys

from .run import main

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
