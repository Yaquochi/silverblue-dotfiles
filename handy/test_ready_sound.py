"""Exercise the real watcher with synthetic logs, without touching the clipboard."""
import json
from pathlib import Path
import select
import subprocess
import sys
import tempfile
import time
import unittest

EVENT = b"[handy_app_lib::actions][DEBUG] Text pasted successfully in 1ms\n"


class WatcherTest(unittest.TestCase):
    def test_completion_filter_partial_line_and_rotation(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            log, settings, sound = (root / n for n in ["handy.log", "settings.json", "sound"])
            log.write_bytes(EVENT)  # Existing completions must not play.
            settings.write_text(json.dumps({"settings": {"clipboard_handling": "dont_modify"}}))
            sound.touch()
            player = root / "player"
            played = root / "played"
            player.write_text("#!/bin/sh\nprintf x >> '" + str(played) + "'\n")
            player.chmod(0o755)
            script = Path(__file__).with_name("handy-ready-sound")
            proc = subprocess.Popen([sys.executable, str(script), "--once", "--log", str(log),
                                     "--settings", str(settings), "--sound", str(sound),
                                     "--player", str(player)], stdout=subprocess.PIPE,
                                    stderr=subprocess.PIPE)
            try:
                self.assertTrue(select.select([proc.stdout], [], [], 5)[0])
                self.assertIn(b"Watching Handy", proc.stdout.readline())
                with log.open("ab") as stream:
                    stream.write(EVENT + b"Transcription completed\nFailed to paste transcription\n")
                time.sleep(.5)
                self.assertFalse(played.exists())  # Clipboard disabled, or only early/error events.
                settings.write_text(json.dumps({"settings": {"clipboard_handling": "copy_to_clipboard"}}))
                log.rename(root / "old.log")
                log.write_bytes(EVENT[:30])
                time.sleep(.5)
                self.assertFalse(played.exists())  # Incomplete log line is not an event.
                with log.open("ab") as stream:
                    stream.write(EVENT[30:])
                proc.communicate(timeout=5)
                self.assertEqual(proc.returncode, 0)
                self.assertEqual(played.read_text(), "x")
            finally:
                if proc.poll() is None:
                    proc.terminate()
                proc.communicate(timeout=5)


if __name__ == "__main__":
    unittest.main()
