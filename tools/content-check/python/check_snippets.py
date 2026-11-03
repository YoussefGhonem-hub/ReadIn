"""Byte-compiles and runs every snippet in a folder; prints one JSON line per file.

Used by ContentStudio validate (SPEC 19.3). Each snippet runs in its own process with a 60-second limit.
"""
import json
import pathlib
import py_compile
import subprocess
import sys

folder = pathlib.Path(sys.argv[1])
for path in sorted(folder.glob("*.py")):
    result = {"file": path.name, "ok": True, "error": None}
    try:
        py_compile.compile(str(path), doraise=True)
        run = subprocess.run([sys.executable, "-I", path.name], cwd=folder, capture_output=True, text=True, timeout=60)
        if run.returncode != 0:
            lines = [line for line in run.stderr.strip().splitlines() if line.strip()]
            result = {"file": path.name, "ok": False, "error": "runtime: " + " | ".join(lines[-3:])}
    except py_compile.PyCompileError as error:
        result = {"file": path.name, "ok": False, "error": "syntax: " + str(error.msg).strip()}
    except subprocess.TimeoutExpired:
        result = {"file": path.name, "ok": False, "error": "runtime: did not finish within 60 seconds"}
    print(json.dumps(result), flush=True)
