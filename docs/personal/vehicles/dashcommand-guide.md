---
title: "DashCommand App Guide for Diesel Truck Diagnostics"
description: "How to use DashCommand on Android for real-time monitoring, diagnostics, and custom PID analysis for diesel trucks."
author: "Joseph Streeter"
ms.date: "2025-07-14"
ms.topic: "how-to"
ms.service: "vehicles"
keywords: ["Diesel Truck", "DashCommand", "OBD-II", "Diagnostics", "Android", "Cummins"]
---

## DashCommand for Diesel Truck Diagnostics

DashCommand provides an intuitive interface for real-time monitoring and diagnostics on Android devices.

### Hardware Setup

- **ELM327-based OBD-II Adapter:** Bluetooth or Wi-Fi (e.g., OBDLink MX+).
- **Android Device:** Smartphone or tablet.

### Connecting DashCommand

1. Plug in OBD-II adapter, turn ignition to "ON."
2. Pair/connect via Android Bluetooth or Wi-Fi settings.
3. Open DashCommand, go to **Settings > OBD-II Interface** to select your adapter and connect.

### Key Features for Analysis

#### Diagnostic Trouble Codes (DTCs)

- Navigate to **Diagnostics** to read and clear active, pending, and historical DTCs. Always diagnose before clearing.

#### Live Data / Gauges

- **Virtual Dashboards/Gauges:** Customize dashboards to display PIDs.

| PID Name                | Description                                 | Expected Values / Notes                                      |
|------------------------|---------------------------------------------|--------------------------------------------------------------|
| DPF Differential Pressure | Pressure drop across DPF                   | 0-1.5 kPa at idle; 3-8 kPa under load; >2.5 kPa at idle = clog|
| DPF Soot Load (%)      | Soot accumulation in DPF                    | <20-30% normal; >80% = clogging; regen at ~70-75%            |
| DPF Regeneration Status| Indicates active/inhibited/requested regen  | Should complete in 20-45 min; frequent regens = issue        |
| EGT (Exhaust Gas Temp) | Exhaust temp at various points              | 350-550°F normal; 1000-1200°F during regen                   |
| NOx Sensor (Pre-SCR)   | NOx before SCR catalyst                     | 100-600 ppm depending on load                                |
| NOx Sensor (Post-SCR)  | NOx after SCR catalyst                      | 70-90% reduction vs. pre-SCR; e.g., <120 ppm if pre-SCR is 400|
| DEF Level              | Diesel Exhaust Fluid tank level              | Should match actual tank; low triggers warnings              |
| DEF Pressure           | Pressure in DEF system                      | 450-650 kPa normal; <400 kPa = possible fault                |
| DEF Injector Command   | Commanded DEF injection rate                | Should correlate with NOx reduction                          |
| RPM                    | Engine speed                                | Idle: ~700 RPM; varies with load                             |
| Engine Load            | Calculated engine load                      | 0-100%; high load increases DPF/DEF activity                 |
| Boost Pressure         | Turbo boost pressure                        | 10-30 psi under load; low = possible boost leak              |
| MAF (Mass Air Flow)    | Air intake measurement                      | Low = restricted airflow; compare to MAP/Baro                |
| Fuel Rail Pressure     | Pressure in fuel rail                       | Should match desired; discrepancies = pump/injector issue    |

- **Key PIDs:**
  - **DPF System:** DPF Differential Pressure, DPF Soot Load, EGTs.
  - **DEF/SCR System:** NOx Sensor Readings, DEF Level, DEF Injector Command, DEF Pressure.
  - **General Performance:** RPM, Speed, Engine Load, Boost Pressure, MAF, Fuel Rail Pressure.
- **Data Grid View:** List of all available PIDs and current values.

#### Data Logging and Playback

- **Record Logs:** Capture live data during driving.
- **Playback Logs:** Review recorded data to identify trends.
- **Export Logs:** Export as CSV for deeper analysis.

#### Custom PIDs (2014 Ram 2500 Cummins)

- For advanced diagnostics, add these custom PIDs in DashCommand using the hex codes and formulas below. These are validated for 2013–2018 Ram 2500/3500 6.7L Cummins (SAE J1979 Mode 22, Chrysler/Cummins ECM).

| PID (Hex) | Description | Formula / Units | Expected Values / Notes |
|-----------|-------------|-----------------|------------------------|
| 22C101    | DPF Soot Mass | ((A*256)+B)/10 g | 5–25g normal; >40g = regen needed |
| 22C102    | DPF Differential Pressure | ((A*256)+B)/100 kPa | 0–1.5 kPa idle; 3–8 kPa under load |
| 22C10C    | DPF Regeneration Status | A | 0=Inactive, 1=Active |
| 22C120    | SCR Catalyst Temp | ((A*256)+B)/10 °C | 200–350°C normal; >500°C during regen |
| 22C123    | DEF Level | ((A*256)+B)/10 % | 20–100% (should match tank) |
| 22C124    | DEF Pressure | ((A*256)+B)/10 kPa | 400–650 kPa normal |
| 22C125    | DEF Quality | ((A*256)+B)/100 % | ~32.5% urea (API standard) |
| 22C130    | EGR Valve Position | A % | 0–100%; erratic = fault |
| 22C131    | Turbo Actuator Position | A % | 0–100%; low at high load = issue |
| 22C132    | Fuel Temperature | ((A*256)+B)/10 °C | -20°C to 60°C |
| 22C133    | Oil Temperature | ((A*256)+B)/10 °C | 80–110°C normal |

> **Note:** These PIDs are confirmed for 2014 Ram 2500 Cummins but may require DashCommand custom PID setup. Refer to Cummins/Chrysler service documentation and community forums for latest definitions and formulas.

### Creating a Custom Dashboard in DashCommand

To monitor the most relevant PIDs for your 2014 Ram 2500 Cummins, follow these steps to create a custom dashboard:

1. **Open DashCommand and Connect to Your Vehicle:**
   - Ensure your OBD-II adapter is paired and DashCommand is connected.

2. **Navigate to Dashboards:**
   - Tap the **Dashboards** tab at the bottom of the app.
   - Select **Custom Dashboards** or tap the gear/settings icon to create a new dashboard.

3. **Add Gauges for Key PIDs:**
   - Tap **Add Gauge** or the "+" icon.
   - For each gauge, select the relevant PID from the list or enter a custom PID (see table above for hex codes and formulas).
   - Recommended PIDs:
     - DPF Soot Mass (22C101)
     - DPF Differential Pressure (22C102)
     - DPF Regeneration Status (22C10C)
     - SCR Catalyst Temp (22C120)
     - DEF Level (22C123)
     - DEF Pressure (22C124)
     - DEF Quality (22C125)
     - EGR Valve Position (22C130)
     - Turbo Actuator Position (22C131)
     - Fuel Temperature (22C132)
     - Oil Temperature (22C133)

4. **Configure Gauge Display:**
   - Set units, min/max values, and warning thresholds based on the expected values in the table above.
   - Arrange gauges for easy viewing while driving.

5. **Save and Use Your Dashboard:**
   - Save your custom dashboard.
   - Use it for real-time monitoring and troubleshooting.

> **Tip:** You can export/import dashboard layouts for backup or sharing. Refer to DashCommand documentation for advanced customization.

### Analyzing Data in DashCommand

- **Look for Abnormal Values:** Compare readings to known normal values.
- **Correlate Data Points:** Identify relationships between PIDs.
- **Observe Trends:** Use graphing features to visualize changes over time.
- **Post-Recording Analysis:** Use exported CSV files for detailed graphing and calculations.

---

## References and Additional Resources

- **[DashCommand App](https://www.palmerperformance.com/products/dashcommand/)**
- **[OBD-II PID Reference](https://en.wikipedia.org/wiki/OBD-II_PIDs)**
- **[Cummins Service Manuals](https://www.cummins.com/support/manuals)**
- **[Diesel Truck Forums](https://www.cumminsforum.com/)**
