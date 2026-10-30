#!/usr/bin/env python3
import json
import subprocess

def get_media():
    data = {
        "active": False,
        "title": "SIN REPRODUCCIÓN",
        "artist": "SPOTIFY // STANDBY",
        "album": "",
        "status": "Stopped",
        "progress": 0.0,
        "length_str": "0:00",
        "pos_str": "0:00",
        "length_sec": 0,
        "pos_sec": 0,
        "art_url": ""
    }
    try:
        # Exclusivo para Spotify (ignorar navegadores y otros reproductores)
        out = subprocess.check_output(
            ["playerctl", "--player=spotify", "metadata", "--format", "{{status}};;;{{title}};;;{{artist}};;;{{album}};;;{{position}};;;{{mpris:length}};;;{{mpris:artUrl}}"],
            text=True, stderr=subprocess.DEVNULL
        ).strip()
        parts = out.split(";;;")
        if len(parts) >= 3 and parts[0]:
            data["active"] = True
            data["status"] = parts[0]
            data["title"] = parts[1] if parts[1] else "Pista desconocida"
            data["artist"] = parts[2] if parts[2] else "Artista desconocido"
            data["album"] = parts[3] if len(parts) > 3 and parts[3] else ""
            
            pos_us = float(parts[4]) if len(parts) > 4 and parts[4] else 0.0
            len_us = float(parts[5]) if len(parts) > 5 and parts[5] else 0.0
            
            if len_us > 0:
                data["progress"] = min(1.0, max(0.0, pos_us / len_us))
                pos_s = int(pos_us / 1000000)
                len_s = int(len_us / 1000000)
                data["pos_sec"] = pos_s
                data["length_sec"] = len_s
                data["pos_str"] = f"{pos_s // 60}:{pos_s % 60:02d}"
                data["length_str"] = f"{len_s // 60}:{len_s % 60:02d}"
            
            if len(parts) > 6 and parts[6]:
                data["art_url"] = parts[6]
    except Exception:
        pass

    print(json.dumps(data))

if __name__ == "__main__":
    get_media()
