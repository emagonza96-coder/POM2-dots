#!/usr/bin/env python3
import sys
import json
import subprocess
import re
import os
import signal

def run_cmd(cmd):
    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        return res.stdout.strip()
    except Exception:
        return ""

def get_sink_icon(name, desc, form_factor="", bus=""):
    text = f"{name} {desc} {form_factor} {bus}".lower()
    if "bluez" in text or "bluetooth" in text:
        if "head" in text or "auricular" in text or "ear" in text:
            return "󰋋"
        return "󰂯"
    if "headphone" in text or "headset" in text or "auricular" in text or "audifono" in text:
        return "󰋋"
    if "hdmi" in text or "displayport" in text or "monitor" in text or "tv" in text:
        return "󰍹"
    if "speaker" in text or "bocina" in text or "altavoz" in text or "internal" in text or "acp" in text:
        return "󰓃"
    return "󰕾"

def get_app_icon(app_name, binary_name=""):
    text = f"{app_name} {binary_name}".lower()
    if "firefox" in text:
        return "󰈹"
    if "spotify" in text:
        return "󰓇"
    if "chrome" in text or "chromium" in text or "brave" in text:
        return "󰊯"
    if "discord" in text or "webcord" in text or "vesktop" in text:
        return "󰙯"
    if "telegram" in text:
        return "󰒥"
    if "mpv" in text or "vlc" in text or "video" in text:
        return "󰕼"
    if "steam" in text or "game" in text:
        return "󰊴"
    return "󰎆"

def clean_device_name(name, desc):
    if desc and desc != "(null)" and desc != "Audio Coprocessor":
        return desc
    if "Speakers" in desc or "Speakers" in name:
        return "Altavoces de Laptop"
    if "Speaker" in desc or "Speaker" in name:
        return "Altavoces"
    if "bluez" in name:
        parts = desc.split()
        return desc if desc else "Bluetooth Audio"
    if desc and desc != "(null)":
        return desc
    return name.split(".")[-1]

def get_volume_icon(vol, muted):
    if muted or vol <= 0.001:
        return "󰖁"
    if vol < 0.33:
        return "󰕿"
    if vol < 0.67:
        return "󰖀"
    return "󰕾"

def get_status():
    default_sink_name = run_cmd(["pactl", "get-default-sink"])
    
    # Obtener Sinks
    sinks_raw = run_cmd(["pactl", "-f", "json", "list", "sinks"])
    sinks_data = []
    try:
        if sinks_raw:
            sinks_data = json.loads(sinks_raw)
    except Exception:
        sinks_data = []

    sinks_map = {}
    parsed_sinks = []
    
    master_level = 0.5
    master_muted = False
    master_state = "SUSPENDED"
    
    for s in sinks_data:
        s_id = s.get("index")
        s_name = s.get("name", "")
        props = s.get("properties", {})
        desc = props.get("device.description", s.get("description", ""))
        nick = props.get("node.nick", "")
        display_name = nick if nick and nick != "Loopback PCM" else (desc if desc else s_name)
        display_name = clean_device_name(s_name, display_name)
        
        form_factor = props.get("device.form_factor", "")
        bus = props.get("device.bus", "")
        icon = get_sink_icon(s_name, desc, form_factor, bus)
        
        is_default = (s_name == default_sink_name)
        state = s.get("state", "SUSPENDED")
        
        # Calcular volumen del sink
        vol_dict = s.get("volume", {})
        vols = []
        for ch, vdata in vol_dict.items():
            if isinstance(vdata, dict) and "value" in vdata:
                vols.append(vdata["value"] / 65536.0)
        sink_vol = sum(vols) / len(vols) if vols else 1.0
        sink_muted = bool(s.get("mute", False))
        
        sink_battery = None
        if "bluez" in s_name:
            try:
                mac_part = s_name.replace("bluez_output.", "").split(".")[0].replace("_", ":")
                sink_battery = get_device_battery(mac_part)
            except Exception:
                pass

        sink_obj = {
            "id": s_id,
            "name": s_name,
            "description": display_name,
            "icon": icon,
            "isDefault": is_default,
            "state": state,
            "volume": round(sink_vol, 3),
            "muted": sink_muted,
            "battery": sink_battery
        }
        
        if is_default:
            master_level = sink_vol
            master_muted = sink_muted
            master_state = state
            
        sinks_map[s_id] = sink_obj
        sinks_map[s_name] = sink_obj
        parsed_sinks.append(sink_obj)

    # Obtener Sink Inputs (Aplicaciones)
    inputs_raw = run_cmd(["pactl", "-f", "json", "list", "sink-inputs"])
    inputs_data = []
    try:
        if inputs_raw:
            inputs_data = json.loads(inputs_raw)
    except Exception:
        inputs_data = []

    parsed_apps = []
    apps_on_default = []
    playing_on_default = False

    for app in inputs_data:
        app_id = app.get("index")
        props = app.get("properties", {})
        app_name = props.get("application.name", "")
        if not app_name:
            app_name = props.get("node.name", props.get("media.name", f"App #{app_id}"))
        
        # Limpieza de nombres comunes como PipeWire ALSA [speaker-test]
        clean_name = re.sub(r"^PipeWire ALSA \[(.*)\]$", r"\1", app_name)
        
        binary_name = props.get("application.process.binary", "")
        icon = get_app_icon(clean_name, binary_name)
        
        # Volumen de la app
        vol_dict = app.get("volume", {})
        vols = []
        for ch, vdata in vol_dict.items():
            if isinstance(vdata, dict) and "value" in vdata:
                vols.append(vdata["value"] / 65536.0)
        app_vol = sum(vols) / len(vols) if vols else 1.0
        app_muted = bool(app.get("mute", False))
        corked = bool(app.get("corked", False))
        
        assigned_sink_id = app.get("sink")
        assigned_sink = sinks_map.get(assigned_sink_id, {})
        assigned_sink_name = assigned_sink.get("name", "")
        
        is_on_default = (assigned_sink_name == default_sink_name or assigned_sink.get("isDefault", False))
        if is_on_default:
            apps_on_default.append(clean_name)
            if not corked:
                playing_on_default = True
        
        parsed_apps.append({
            "id": app_id,
            "name": clean_name,
            "icon": icon,
            "volume": round(app_vol, 3),
            "muted": app_muted,
            "corked": corked,
            "sinkId": assigned_sink_id,
            "sinkName": assigned_sink_name,
            "sinkDesc": assigned_sink.get("description", "Salida"),
            "sinkIcon": assigned_sink.get("icon", "󰓃")
        })

    is_occupied = len(apps_on_default) > 0
    is_playing = playing_on_default or master_state == "RUNNING"
    primary_app = apps_on_default[0] if apps_on_default else ""

    result = {
        "master": {
            "volume": round(master_level, 3),
            "muted": master_muted,
            "volumeIcon": get_volume_icon(master_level, master_muted),
            "sinkName": default_sink_name,
            "sinkDesc": sinks_map.get(default_sink_name, {}).get("description", "Speakers"),
            "sinkIcon": sinks_map.get(default_sink_name, {}).get("icon", "󰓃"),
            "deviceIcon": sinks_map.get(default_sink_name, {}).get("icon", "󰓃"),
            "isOccupied": is_occupied,
            "isPlaying": is_playing,
            "activeApp": primary_app,
            "activeAppsCount": len(apps_on_default)
        },
        "sinks": parsed_sinks,
        "apps": parsed_apps
    }
    print(json.dumps(result))

def set_master_sink(sink_target):
    # 1. Establecer como default en pactl
    subprocess.run(["pactl", "set-default-sink", str(sink_target)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    # 2. Mover todas las aplicaciones activas a este sink
    try:
        inputs_raw = run_cmd(["pactl", "-f", "json", "list", "sink-inputs"])
        if inputs_raw:
            inputs_data = json.loads(inputs_raw)
            for app in inputs_data:
                app_id = app.get("index")
                if app_id is not None:
                    subprocess.run(["pactl", "move-sink-input", str(app_id), str(sink_target)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def move_app_sink(app_id, sink_target):
    subprocess.run(["pactl", "move-sink-input", str(app_id), str(sink_target)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def set_app_volume(app_id, volume_float):
    try:
        vol = float(volume_float)
        vol_pct = f"{int(vol * 100)}%"
        subprocess.run(["pactl", "set-sink-input-volume", str(app_id), vol_pct], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def toggle_app_mute(app_id):
    subprocess.run(["pactl", "set-sink-input-mute", str(app_id), "toggle"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def set_master_volume(vol_float):
    try:
        vol = float(vol_float)
        subprocess.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", f"{vol:.2f}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def set_sink_volume(sink_target, volume_float):
    try:
        vol = float(volume_float)
        vol_pct = f"{int(vol * 100)}%"
        subprocess.run(["pactl", "set-sink-volume", str(sink_target), vol_pct], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def toggle_sink_mute(sink_target):
    subprocess.run(["pactl", "set-sink-mute", str(sink_target), "toggle"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def toggle_master_mute():
    subprocess.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

import os

def get_device_battery(mac, info=""):
    # 1. bluetoothctl info
    if info:
        m = re.search(r"Battery Percentage:\s*(?:0x([0-9a-fA-F]+)|(\d+))", info)
        if m:
            val_hex, val_dec = m.groups()
            return int(val_hex, 16) if val_hex else int(val_dec)
        m2 = re.search(r"Battery:\s*(\d+)%", info, re.IGNORECASE)
        if m2:
            return int(m2.group(1))

    # 2. DBus org.bluez.Battery1
    dbus_mac = "dev_" + mac.replace(":", "_")
    dbus_path = f"/org/bluez/hci0/{dbus_mac}"
    try:
        res = subprocess.run([
            "gdbus", "call", "--system", "--dest", "org.bluez",
            "--object-path", dbus_path,
            "--method", "org.freedesktop.DBus.Properties.Get",
            "org.bluez.Battery1", "Percentage"
        ], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, timeout=1)
        if res.returncode == 0 and res.stdout:
            m = re.search(r"<\s*(?:byte\s+)?(\d+)\s*>", res.stdout)
            if m:
                return int(m.group(1))
    except Exception:
        pass

    # 3. UPower
    clean_mac_upower = mac.replace(":", "_").lower()
    try:
        up_out = run_cmd(["upower", "-d"])
        if up_out and clean_mac_upower in up_out.lower():
            blocks = up_out.split("Device:")
            for b in blocks:
                if clean_mac_upower in b.lower():
                    m = re.search(r"percentage:\s*(\d+)%", b)
                    if m:
                        return int(m.group(1))
    except Exception:
        pass

    # 4. sysfs power_supply
    try:
        clean_mac_sys = mac.lower().replace(":", "_")
        if os.path.exists("/sys/class/power_supply"):
            for entry in os.listdir("/sys/class/power_supply"):
                if clean_mac_sys in entry.lower():
                    cap_file = os.path.join("/sys/class/power_supply", entry, "capacity")
                    if os.path.exists(cap_file):
                        with open(cap_file, "r") as f:
                            return int(f.read().strip())
    except Exception:
        pass

    return None

def get_bt_status():
    show = run_cmd(["bluetoothctl", "show"])
    powered = "Powered: yes" in show
    discovering = "Discovering: yes" in show

    # Obtener lista de emparejados (en memoria)
    paired_raw = run_cmd(["bluetoothctl", "devices", "Paired"])
    paired_macs = set()
    if paired_raw:
        for line in paired_raw.strip().split("\n"):
            parts = line.strip().split(" ", 2)
            if len(parts) >= 2 and parts[0] == "Device":
                paired_macs.add(parts[1])

    devs_out = run_cmd(["bluetoothctl", "devices"])
    paired_devices = []
    available_devices = []

    if devs_out:
        for line in devs_out.strip().split("\n"):
            if not line.startswith("Device "):
                continue
            parts = line.split(" ", 2)
            if len(parts) < 3:
                continue
            mac = parts[1]
            raw_name = parts[2].strip()
            
            is_paired = mac in paired_macs
            
            if is_paired:
                # Obtener detalles solo para dispositivos vinculados
                info = run_cmd(["bluetoothctl", "info", mac])
                connected = "Connected: yes" in info
                battery = get_device_battery(mac, info) if connected else None
            else:
                info = ""
                connected = False
                battery = None

            # Si no está emparejado, solo mostrarlo si tiene un nombre útil (no una MAC invertida fea)
            clean_mac_pattern = mac.replace(":", "-").lower()
            is_generic_mac = raw_name.lower().replace(":", "-") == clean_mac_pattern

            # Determinar ícono
            icon = "󰋋"
            info_lower = (info + " " + raw_name).lower()
            if "speaker" in info_lower or "soundbar" in info_lower or "bocina" in info_lower:
                icon = "󰓃"
            elif "keyboard" in info_lower or "teclado" in info_lower:
                icon = "󰌌"
            elif "mouse" in info_lower:
                icon = "󰍽"
            elif "phone" in info_lower or "galaxy" in info_lower or "iphone" in info_lower:
                icon = "󰏲"
            elif "head" in info_lower or "ear" in info_lower or "audio" in info_lower or "soul" in info_lower or "b-13" in info_lower:
                icon = "󰋋"
            else:
                icon = "󰂯"

            dev_obj = {
                "mac": mac,
                "name": raw_name,
                "connected": connected,
                "paired": is_paired,
                "icon": icon,
                "battery": battery,
                "isGeneric": is_generic_mac
            }

            if is_paired:
                paired_devices.append(dev_obj)
            else:
                available_devices.append(dev_obj)

    # Ordenar emparejados: primero los conectados
    paired_devices.sort(key=lambda d: (not d["connected"], d["name"].lower()))
    
    # Ordenar disponibles: primero los que tienen nombre real visible, luego por nombre
    available_devices.sort(key=lambda d: (d["isGeneric"], d["name"].lower()))

    # Límite de disponibles para mantener la interfaz ligera
    available_devices = available_devices[:15]

    return {
        "powered": powered,
        "discovering": discovering,
        "pairedDevices": paired_devices,
        "availableDevices": available_devices,
        "devices": paired_devices + available_devices
    }

def bt_connect(mac):
    try:
        subprocess.run(["bluetoothctl", "connect", str(mac)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=12)
    except Exception:
        pass

def bt_pair_and_connect(mac):
    try:
        subprocess.run(["bluetoothctl", "pair", str(mac)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=10)
        subprocess.run(["bluetoothctl", "trust", str(mac)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["bluetoothctl", "connect", str(mac)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=12)
    except Exception:
        pass

def bt_disconnect(mac):
    try:
        subprocess.run(["bluetoothctl", "disconnect", str(mac)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=10)
    except Exception:
        pass

def stop_scan_processes():
    my_pid = os.getpid()
    try:
        for pid_dir in os.listdir("/proc"):
            if not pid_dir.isdigit() or int(pid_dir) == my_pid:
                continue
            try:
                cmdline_path = os.path.join("/proc", pid_dir, "cmdline")
                with open(cmdline_path, "rb") as f:
                    cmdline = f.read().decode("utf-8", errors="ignore").replace("\x00", " ")
                    if "bluetoothctl" in cmdline and "scan" in cmdline:
                        os.kill(int(pid_dir), signal.SIGKILL)
            except Exception:
                continue
    except Exception:
        pass
    subprocess.run(["bluetoothctl", "scan", "off"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def bt_power(state):
    turn_on = state in ("on", "true", "1")
    if turn_on:
        subprocess.run(["rfkill", "unblock", "bluetooth"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["bluetoothctl", "power", "on"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        stop_scan_processes()
        subprocess.run(["bluetoothctl", "power", "off"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def bt_scan(action):
    show = run_cmd(["bluetoothctl", "show"])
    is_powered = "Powered: yes" in show
    is_discovering = "Discovering: yes" in show

    if action in ("off", "stop", "cancel"):
        stop_scan_processes()
    elif action == "toggle":
        if is_discovering:
            stop_scan_processes()
        else:
            if not is_powered:
                subprocess.run(["rfkill", "unblock", "bluetooth"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                subprocess.run(["bluetoothctl", "power", "on"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            stop_scan_processes()
            subprocess.Popen(["bluetoothctl", "--timeout", "25", "scan", "on"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    elif action in ("on", "start"):
        if not is_powered:
            subprocess.run(["rfkill", "unblock", "bluetooth"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["bluetoothctl", "power", "on"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        stop_scan_processes()
        subprocess.Popen(["bluetoothctl", "--timeout", "25", "scan", "on"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        stop_scan_processes()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        get_status()
        sys.exit(0)

    action = sys.argv[1]
    if action == "status":
        get_status()
    elif action == "bt-status":
        print(json.dumps(get_bt_status()))
    elif action == "bt-connect" and len(sys.argv) >= 3:
        bt_connect(sys.argv[2])
    elif action == "bt-pair-connect" and len(sys.argv) >= 3:
        bt_pair_and_connect(sys.argv[2])
    elif action == "bt-disconnect" and len(sys.argv) >= 3:
        bt_disconnect(sys.argv[2])
    elif action == "bt-power" and len(sys.argv) >= 3:
        bt_power(sys.argv[2])
    elif action == "bt-scan":
        scan_arg = sys.argv[2] if len(sys.argv) >= 3 else "toggle"
        bt_scan(scan_arg)
    elif action == "set-master-volume" and len(sys.argv) >= 3:
        set_master_volume(sys.argv[2])
    elif action == "toggle-master-mute":
        toggle_master_mute()
    elif action == "set-sink-volume" and len(sys.argv) >= 4:
        set_sink_volume(sys.argv[2], sys.argv[3])
    elif action == "toggle-sink-mute" and len(sys.argv) >= 3:
        toggle_sink_mute(sys.argv[2])
    elif action == "set-master-sink" and len(sys.argv) >= 3:
        set_master_sink(sys.argv[2])
    elif action == "set-app-volume" and len(sys.argv) >= 4:
        set_app_volume(sys.argv[2], sys.argv[3])
    elif action == "toggle-app-mute" and len(sys.argv) >= 3:
        toggle_app_mute(sys.argv[2])
    elif action == "move-app-sink" and len(sys.argv) >= 4:
        move_app_sink(sys.argv[2], sys.argv[3])
    else:
        get_status()
