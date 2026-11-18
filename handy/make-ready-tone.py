#!/usr/bin/env python3
"""Generate a quiet, rounded completion tone using only the standard library."""
import math
from pathlib import Path
import struct
import sys
import wave

path = Path(sys.argv[1])
path.parent.mkdir(parents=True, exist_ok=True)
rate = 44100
duration = 0.4
frames = bytearray()
for index in range(round(rate * duration)):
    t = index / rate
    # Smooth attack/release prevent clicks; a gentle decay avoids a sharp bell.
    attack = math.sin(min(t / 0.045, 1) * math.pi / 2) ** 2
    release = math.sin(min((duration - t) / 0.12, 1) * math.pi / 2) ** 2
    envelope = attack * release * math.exp(-t / 0.18)
    tone = math.sin(2 * math.pi * 440 * t) + 0.15 * math.sin(2 * math.pi * 660 * t)
    frames.extend(struct.pack('<h', round(32767 * 0.085 * envelope * tone)))
with wave.open(str(path), 'wb') as output:
    output.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
    output.writeframes(frames)
