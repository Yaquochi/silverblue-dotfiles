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
    # A single low tone avoids beating between pitches. The 100 ms attack
    # eases in with zero slope; a raised-cosine release fades to silence.
    attack = math.sin(min(t / 0.10, 1) * math.pi / 2) ** 2
    release = math.sin(min((duration - t) / 0.24, 1) * math.pi / 2) ** 2
    envelope = attack * release
    tone = math.sin(2 * math.pi * 300 * t)
    frames.extend(struct.pack('<h', round(32767 * 0.055 * envelope * tone)))
with wave.open(str(path), 'wb') as output:
    output.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
    output.writeframes(frames)
