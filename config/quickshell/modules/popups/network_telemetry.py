#!/usr/bin/env python3
import json
import subprocess

def get_telemetry():
    info = {
        "iface": "wlan0",
        "ip": "N/D",
        "gateway": "N/D",
        "mac": "N/D",
        "freq": "N/D",
        "bitrate": "N/D",
        "signal_dbm": "N/D",
        "ssid": "Sin red",
        "connected": False,
        "driver": "rtw88_8822ce"
    }
    try:
        out = subprocess.check_output(
            ["nmcli", "-t", "-f", "GENERAL.DEVICE,GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY,GENERAL.STATE", "dev", "show", "wlan0"],
            text=True
        )
        for line in out.strip().splitlines():
            if line.startswith("IP4.ADDRESS"):
                info["ip"] = line.split(":", 1)[1]
            elif line.startswith("IP4.GATEWAY"):
                info["gateway"] = line.split(":", 1)[1]
            elif line.startswith("GENERAL.HWADDR"):
                info["mac"] = line.split(":", 1)[1]
            elif line.startswith("GENERAL.STATE"):
                info["connected"] = "connected" in line.lower()
    except Exception:
        pass

    try:
        out = subprocess.check_output(["iw", "dev", "wlan0", "link"], text=True)
        if "Not connected" in out:
            info["connected"] = False
        else:
            for line in out.strip().splitlines():
                line = line.strip()
                if line.startswith("SSID:"):
                    info["ssid"] = line.split(":", 1)[1].strip()
                    info["connected"] = True
                elif line.startswith("freq:"):
                    f = float(line.split()[1])
                    info["freq"] = f"5 GHz ({f:.0f} MHz)" if f > 4000 else f"2.4 GHz ({f:.0f} MHz)"
                elif line.startswith("signal:"):
                    info["signal_dbm"] = line.split(":", 1)[1].strip()
                elif line.startswith("tx bitrate:"):
                    info["bitrate"] = line.split(":", 1)[1].split()[0] + " Mbps"
    except Exception:
        pass

    print(json.dumps(info))

if __name__ == "__main__":
    get_telemetry()
