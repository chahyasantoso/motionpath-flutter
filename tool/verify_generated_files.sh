#!/usr/bin/env bash
set -euo pipefail

tracked_build_outputs="$(git ls-files | grep -E '(^|/)(build|\.dart_tool)/' || true)"
if [[ -n "${tracked_build_outputs}" ]]; then
  echo "Tracked Dart/Flutter build output found:"
  printf '%s\n' "${tracked_build_outputs}"
  exit 1
fi

tracked_generated_sources="$(git ls-files | grep -E '(^|/)([^/]+\.(g|freezed|mocks)\.dart)$' || true)"
if [[ -n "${tracked_generated_sources}" ]]; then
  echo "Tracked generated Dart sources found without a declared generator workflow:"
  printf '%s\n' "${tracked_generated_sources}"
  exit 1
fi

echo "Generated-file hygiene check passed."
