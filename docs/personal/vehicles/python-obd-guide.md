---
title: "Python OBD-II Data Analysis for Diesel Trucks"
description: "Guide to using Python and OBD-II adapters for advanced diagnostics and data analysis on diesel trucks, including code examples and best practices."
author: "Joseph Streeter"
ms.date: "2025-07-14"
ms.topic: "how-to"
ms.service: "vehicles"
keywords: ["Diesel Truck", "OBD-II", "Python", "Diagnostics", "Data Analysis", "Cummins"]
---

## Python-Based OBD-II Data Logging and Analysis

This guide covers how to use Python and ELM327-based OBD-II adapters for custom data logging, analysis, and visualization on diesel trucks.

### Hardware Requirements

- **ELM327-based OBD-II Adapter:** Bluetooth, Wi-Fi, or USB.
- **Computer/Microcontroller:** Laptop/Desktop or Raspberry Pi.

### Essential Python Libraries

- **python-OBD:** ELM327 communication and OBD-II data translation (installation: `pip install obd`).
- **pandas:** Data manipulation/storage (installation: `pip install pandas`).
- **matplotlib / seaborn:** Visualizations (installation: `pip install matplotlib seaborn`).
- **numpy:** Numerical operations (installation: `pip install numpy`).
- **pyserial:** Required for serial communication with OBD adapters (installation: `pip install pyserial`).

### Basic Python-OBD Code Structure

```python
import obd
import time
import pandas as pd
import matplotlib.pyplot as plt

# 1. Establish Connection
connection = obd.OBD()  # Auto-connect
# For specific ports: obd.OBD(portstr="...", adapter_type=obd.Bluetooth/obd.Wifi)
if not connection.is_connected():
    print("Failed to connect.")
    exit()

# 2. Define PIDs to Monitor
# Use obd.commands.PID_NAME (e.g., obd.commands.RPM)
# For diesel-specific PIDs (DPF, SCR, NOx), you may need to define custom commands
# Example custom command:
# from obd import OBDCommand, Unit
# custom_dpf_soot_load = OBDCommand("DPF_SOOT_LOAD", "221234", 2, lambda msb, lsb: ((msb * 256) + lsb) / 100, unit="%")

# Filter for supported PIDs:
# actual_pids_to_monitor = [pid for pid in pids_to_monitor if connection.supports(pid)]

# 3. Collect Data (Loop)
data_log = []
# for desired duration/samples
# row = {"timestamp": time.time()}
# for pid in actual_pids_to_monitor:
#     response = connection.query(pid)
#     row[pid.name] = response.value if not response.is_null() else None
# data_log.append(row)
# time.sleep(sample_interval)
connection.close()

# 4. Convert to Pandas DataFrame
df = pd.DataFrame(data_log)
df['timestamp_readable'] = pd.to_datetime(df['timestamp'], unit='s')
df = df.set_index('timestamp_readable')

# 5. Basic Analysis and Visualization
# df.plot(), df.describe(), etc.
# Example: plt.plot(df.index, df['RPM'], label='RPM')
```

### Advanced Analysis with Python

- **Time-Series Analysis:** Implement rolling averages to smooth noisy sensor data, calculate rates of change, and detect regeneration events based on EGT spikes and DPF soot load drops.

```python
# Example: Rolling average to smooth noisy data
df['smooth_egt'] = df['EGT'].rolling(window=10).mean()

# Example: Detecting regeneration events
df['is_regen'] = ((df['EGT'] > 550) & (df['DPF_SOOT_LOAD'].diff() < -5))
```

- **Correlation Analysis:** Analyze relationships between PIDs using pandas correlation methods to identify causality patterns.

```python
# Example: Correlation matrix
correlation_matrix = df[['ENGINE_LOAD', 'EGT', 'NOX_SENSOR_1', 'DEF_DOSING_RATE']].corr()
```

- **Thresholding and Alerting:** Set thresholds for critical parameters and create alert functions.
- **Machine Learning (Advanced):** Implement anomaly detection using libraries like scikit-learn to predict maintenance needs.
- **Custom PIDs for Diesel Data:** The 2014 Ram Cummins uses both standard OBD-II PIDs and Cummins-specific Mode 22 PIDs. For example, DPF soot load often uses custom PID 222F, and SCR catalyst efficiency uses 2293.

---

## References and Additional Resources

- **[python-OBD Documentation](https://python-obd.readthedocs.io/en/latest/index.md)**
- **[PyPI python-OBD package](https://pypi.org/project/obd/index.md)**
- **[OBD-II PID Reference](https://en.wikipedia.org/wiki/OBD-II_PIDs)**
- **[Cummins Service Manuals](https://www.cummins.com/support/manuals)**
- **[Diesel Truck Forums](https://www.cumminsforum.com/index.md)**
