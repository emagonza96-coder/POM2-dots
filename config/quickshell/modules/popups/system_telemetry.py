#!/usr/bin/env python3
import json
import glob
import os
import time

def get_cpu_stat():
    try:
        with open("/proc/stat", "r") as f:
            fields = [float(x) for x in f.readline().strip().split()[1:]]
        idle = fields[3] + fields[4]
        total = sum(fields)
        return idle, total
    except Exception:
        return 0.0, 1.0

def get_telemetry():
    telemetry = {
        "cpu_usage": 0.0,
        "cpu_display": "0%",
        "ram_usage": 0.0,
        "ram_display": "0%",
        "cpu_temp": 0.0,
        "cpu_temp_display": "0°C",
        "gpu_temp": 0.0,
        "gpu_temp_display": "0°C",
        "cpu_warn": False,
        "cpu_temp_warn": False
    }

    # 1. CPU Usage (muestreo rápido de 100ms)
    try:
        i1, t1 = get_cpu_stat()
        time.sleep(0.1)
        i2, t2 = get_cpu_stat()
        d_idle = i2 - i1
        d_tot = t2 - t1
        if d_tot > 0:
            cpu_pct = max(0.0, min(100.0, (1.0 - (d_idle / d_tot)) * 100.0))
            telemetry["cpu_usage"] = round(cpu_pct / 100.0, 2)
            telemetry["cpu_display"] = f"{int(round(cpu_pct))}%"
            telemetry["cpu_warn"] = cpu_pct >= 85.0
    except Exception:
        pass

    # 2. RAM Usage (/proc/meminfo)
    try:
        mem = {}
        with open("/proc/meminfo", "r") as f:
            for line in f:
                parts = line.split(":")
                if len(parts) == 2:
                    mem[parts[0].strip()] = int(parts[1].split()[0])
        total = mem.get("MemTotal", 1)
        avail = mem.get("MemAvailable", 0)
        used_pct = max(0.0, min(100.0, ((total - avail) / total) * 100.0))
        telemetry["ram_usage"] = round(used_pct / 100.0, 2)
        telemetry["ram_display"] = f"{int(round(used_pct))}%"
    except Exception:
        pass

    # 3. Temperaturas (/sys/class/hwmon)
    cpu_t = None
    gpu_t = None
    try:
        for hwmon in glob.glob("/sys/class/hwmon/hwmon*"):
            name_path = os.path.join(hwmon, "name")
            if not os.path.exists(name_path):
                continue
            with open(name_path, "r") as f:
                hw_name = f.read().strip()
            
            # CPU (k10temp en AMD Ryzen)
            if "k10temp" in hw_name:
                for t_input in glob.glob(os.path.join(hwmon, "temp*_input")):
                    try:
                        with open(t_input, "r") as tf:
                            val = float(tf.read().strip()) / 1000.0
                            if cpu_t is None or val > cpu_t:
                                cpu_t = val
                    except Exception:
                        pass
            
            # GPU (amdgpu)
            elif "amdgpu" in hw_name:
                for t_input in glob.glob(os.path.join(hwmon, "temp*_input")):
                    try:
                        with open(t_input, "r") as tf:
                            val = float(tf.read().strip()) / 1000.0
                            if gpu_t is None or val > gpu_t:
                                gpu_t = val
                    except Exception:
                        pass

        if cpu_t is not None:
            telemetry["cpu_temp"] = round(min(1.0, cpu_t / 100.0), 2)
            telemetry["cpu_temp_display"] = f"{int(round(cpu_t))}°C"
            telemetry["cpu_temp_warn"] = cpu_t >= 80.0
        
        if gpu_t is not None:
            telemetry["gpu_temp"] = round(min(1.0, gpu_t / 100.0), 2)
            telemetry["gpu_temp_display"] = f"{int(round(gpu_t))}°C"
    except Exception:
        pass

    print(json.dumps(telemetry))

if __name__ == "__main__":
    get_telemetry()
