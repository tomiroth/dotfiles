#!/usr/bin/env bash
# Restore the Samsung U32H85x on DP-2 to its DisplayPort input, then make
# KDE Plasma re-probe its outputs.
#
# Usage:
#   ./tools/fix-monitor-input.sh
#   DDC_DISPLAY=2 INPUT_SOURCE=0x11 ./tools/fix-monitor-input.sh
set -euo pipefail

DDC_DISPLAY="${DDC_DISPLAY:-1}"
INPUT_SOURCE="${INPUT_SOURCE:-0x0f}" # 0x0f = DisplayPort-1 on this panel

command -v ddcutil >/dev/null || { echo "ddcutil is not installed" >&2; exit 1; }

echo "DDC displays:"
ddcutil detect | grep '^Display' || true

printf '\nInput before (display %s):\n' "$DDC_DISPLAY"
ddcutil --display "$DDC_DISPLAY" getvcp 60 || true

echo
echo "Setting display ${DDC_DISPLAY} input to ${INPUT_SOURCE} ..."
ddcutil --display "$DDC_DISPLAY" setvcp 60 "$INPUT_SOURCE"

if command -v kscreen-doctor >/dev/null; then
  echo
  echo "Bouncing KDE display detection..."
  kscreen-doctor --dpms off
  sleep 2
  kscreen-doctor --dpms on

  printf '\nInput after (display %s):\n' "$DDC_DISPLAY"
  ddcutil --display "$DDC_DISPLAY" getvcp 60 || true

  echo
  echo "KDE outputs:"
  kscreen-doctor -o 2>/dev/null | grep -E 'Output:|connected|disconnected' || true
fi
