#!/usr/bin/env python3
"""Parse Unity migration C# without importing Unity or claiming a build result.

The optional parser dependency is intentionally isolated in
``unity/tools-requirements.txt``. CI installs it before this script runs. Local
source validation may run without it, where this tool reports the limitation
rather than pretending an editor compile occurred.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "unity" / "Assets" / "OperationRedline" / "Scripts"


def main() -> int:
    try:
        from tree_sitter import Language, Parser
        import tree_sitter_c_sharp
    except ImportError:
        print("UNITY_CSHARP_SYNTAX_SKIPPED parser_dependency_not_installed")
        return 0

    parser = Parser(Language(tree_sitter_c_sharp.language()))
    failures: list[str] = []
    files = sorted(SCRIPTS.glob("*.cs"))
    if not files:
        print("UNITY_CSHARP_SYNTAX_ERROR no Unity C# scripts found", file=sys.stderr)
        return 1

    for source_path in files:
        root = parser.parse(source_path.read_bytes()).root_node
        errors: list[str] = []

        def visit(node: object) -> None:
            # tree-sitter nodes are intentionally duck-typed to keep this file
            # importable on workstations without the optional package.
            if getattr(node, "type") == "ERROR" or getattr(node, "is_missing"):
                errors.append(f"{getattr(node, 'type')}@{getattr(node, 'start_point')}")
            for child in getattr(node, "children"):
                visit(child)

        visit(root)
        if errors:
            failures.append(f"{source_path.relative_to(ROOT)}: {', '.join(errors)}")

    if failures:
        print("UNITY_CSHARP_SYNTAX_ERROR " + " | ".join(failures), file=sys.stderr)
        return 1
    print(f"UNITY_CSHARP_SYNTAX_PASS files={len(files)} parser=tree-sitter")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
