---
uid: edge-cts3-guide
title: Edge CTS3 Dashboard Designs for 2014 RAM 3500 (6.7L Cummins)
description: Comprehensive guide for configuring Edge CTS3 dashboard monitor with detailed gauge layouts, diagnostics, and monitoring parameters for 2014 RAM 3500 with 6.7L Cummins engine
author: Joseph Streeter
ms.date: 2025-01-26
ms.topic: article
ms.custom: personal-vehicles
---

**Goal:** Monitor Fuel and DEF Consumption, Engine Health, and Emissions System Performance

The Edge CTS3 provides several diagnostic capabilities specifically relevant to the 2014 RAM 3500 Cummins:

**Trouble Code Management:**

- **Access:** Main Menu → Diagnostics → Trouble Codes
- **Functions:** View active/pending DTCs with descriptions, clear codes
- **Best Practice:** Write down codes before clearing for future reference[^31]

**DPF Regeneration Support:**

- **Manual Regeneration:** Available if vehicle supports it (check Diagnostics menu)
- **Operating Conditions:** Requires specific engine coolant temp, oil temp, and vehicle speed
- **Mobile Regeneration:** Can be initiated while driving under proper conditions[^32]

**Performance Testing:**

- **Available Tests:** 0-60, 0-100, 1/4 Mile, 1/8 Mile performance measurements
- **Safety Note:** Only use in closed circuit, legally sanctioned racing environments
- **Data Output:** Digital drag slip with reaction time and performance metrics[^33]

## Additional Considerations

### Safety and Legal Compliance

- Always ensure modifications comply with local emissions regulations
- Monitor parameters do not replace proper maintenance schedules
- Consult qualified technicians for diagnosis of persistent issues  
**Device:** Edge CTS3 Evolution Programmer & Monitor (3 Customizable Gauge Layouts Available)  
**Vehicle:** 2014 RAM 3500 with 6.7L Cummins ISB Engine  
**Manual Reference:** Edge Products CTS3 User Manual (D10023820 Rev00)

> [!WARNING]
> This document provides general guidelines for monitoring engine parameters. Always consult your vehicle's service manual and Edge CTS3 documentation for official specifications. Improper monitoring or alert settings may result in missed early warning signs of engine problems.

## General Notes on CTS3 PID Values and Setup

- Values are **general guidelines** for a healthy 2014 RAM 3500 (6.7L Cummins ISB)[^1].
- **CTS3 Layout Configuration:** Use the Layout Editor accessed by swiping down from the top of the gauge screen and selecting "Edit Layout" to customize your three available gauge screens[^2].
- **Custom PID Setup:** For advanced diesel monitoring, you may need to add custom PIDs using DashCommand or similar OBD-II apps, then configure them in the CTS3 gauge editor[^3].
- Actual values can vary based on ambient temperature, altitude, specific truck modifications, maintenance history, and precise load.
- **"N/A"** means the PID is not typically relevant or stable enough to provide a useful "ideal" value for that driving condition.
- **"Varies"** means the value is highly dependent on specific circumstances (e.g., regeneration status, engine temperature, load).
- **"Target Range"** indicates a general band for healthy operation.
- **"Relative"** means you're looking for stability or a difference between two points rather than an absolute number.
- **EAS Required:** Many DEF and advanced fuel PIDs will require Edge Accessory System (EAS) sensors[^4].
- **Alert Configuration:** Use the CTS3's individual gauge alert settings (accessible via double-tap on each gauge) to set Warning and Alert thresholds based on the values below[^5].

## Dashboard 1: Critical Engine & Fuel Health (Primary View)

**Focus:** Immediate awareness of vital engine, fuel supply, and DEF tank status. High priority for alerts.  
**CTS3 Setup:** Configure as your primary gauge screen using Layout Editor. Use large digital or sweep gauge styles for quick interpretation[^6].  
**Gauge Configuration:** Access individual gauge settings by double-tapping each gauge to assign PIDs and set alert thresholds.

| Parameter | Units | Highway/Cruise | City/Stop-and-Go | Heavy Load/Towing | Notes |
|-----------|-------|----------------|------------------|-------------------|-------|
| Fuel Rail Pressure (Actual) | PSI / MPa | Consistent: 20,000 - 26,000+ PSI (under light to moderate load) | Fluctuates: 5,000 - 20,000+ PSI (based on throttle demand) | High & Consistent: 26,000 - 30,000+ PSI (should closely match Desired) | **Crucial.** Look for stability. Major drops under load, or inability to match "Desired" pressure, indicate fuel supply/pump/injector issues[^7]. **CTS3 Alert:** Set Warning at 5,000 PSI below desired, Alert at 10,000 PSI below desired, or for erratic fluctuations. |
| Fuel Rail Pressure (Desired) | PSI / MPa | Matches Actual closely | Matches Actual closely | Matches Actual closely | This is what the ECM commands. Should track Actual pressure very closely. A large, sustained gap (Actual < Desired) is problematic[^8]. |
| Fuel Filter Restriction | PSI / kPa | < 3 PSI (< 20 kPa) | < 3 PSI (< 20 kPa) | < 5 PSI (< 35 kPa) (may rise slightly with heavy flow) | **If available via EAS.** Indicates filter health. Values steadily increasing over time or above these suggest a dirty filter needing replacement[^9]. **CTS3 Alert:** Set Warning at 5 PSI, Alert at 8-10 PSI (or equivalent kPa). |
| Engine Load | % | 30 - 70% (consistent cruising) | 0 - 80% (highly variable with stop-and-go) | 70 - 100% (sustained high load) | Provides context for other PIDs. Higher load generally means higher fuel pressure, DEF dosing, and EGTs[^10]. |
| Exhaust Gas Temp (EGT) (Pre-DPF) | °F / °C | 500 - 800°F (260 - 425°C) | 300 - 900°F (150 - 480°C) (variable, may spike during regen) | 800 - 1200°F+ (425 - 650°C+) (can hit higher during hard pull/regen) | Monitors exhaust health. High sustained temps without regen or load can indicate issues. Will spike much higher (1000-1400°F+) during active DPF regeneration[^11]. **CTS3 Alert:** Set Warning at 1200°F, Alert at 1300°F+ for sustained temps outside of active regeneration. |
| DEF Tank Level | % | Varies (depends on initial fill) | Varies (depends on initial fill) | Varies (depends on initial fill) | **Crucial to avoid derates.** Simply tracks fluid level. **CTS3 Alert:** Set Warning at 25%, Alert at 10% to prevent vehicle derate conditions[^12]. |

## Dashboard 2: Detailed Fuel & Injector Diagnostics

**Focus:** In-depth analysis of fuel delivery and individual cylinder performance.  
**CTS3 Setup:** Configure as your secondary gauge screen. Mix of digital gauges and potentially bar-style displays for multiple parameters. Use the CTS3's Advanced PID list for detailed fuel system monitoring[^13].  
**Data Logging:** Consider using the CTS3's recording feature for this dashboard to capture fuel system trends over time[^14].

| Parameter | Units | Highway/Cruise | City/Stop-and-Go | Heavy Load/Towing | Notes |
|-----------|-------|----------------|------------------|-------------------|-------|
| Injector Balance Rate (Cyl 1-6) | mm³ / mg/st | Close to 0 (e.g., +/- 0.5 mm³) | Close to 0 (e.g., +/- 1.0 mm³) | Close to 0 (e.g., +/- 0.5 mm³) | **Diagnostic for injector health.** ECM adjusts fuel to individual cylinders for smooth idle/operation. Look for consistent large deviations (+/- 3-5 mm³ or more, depending on OEM spec) on any cylinder, which indicates a weak or failing injector[^15]. **Note:** CTS3 may access this via Diagnostics menu for Duramax; for Cummins, may require custom PID setup. |
| Low Pressure Fuel Pump (LPFP) Pressure | PSI | 8 - 15 PSI (consistent) | 8 - 15 PSI (consistent) | 8 - 15 PSI (consistent, even under flow) | **If available.** Monitors the lift pump. Low pressure can starve the CP3 pump, leading to rail pressure issues[^16]. **CTS3 Alert:** Set Warning below 8 PSI, Alert below 6 PSI. |
| Fuel Temperature | °F / °C | 80 - 150°F (27 - 65°C) | 80 - 180°F (27 - 82°C) (can climb in stop-and-go) | 100 - 200°F+ (38 - 93°C+) (can climb higher due to return fuel heat) | High fuel temps reduce lubricity and density, impacting performance and potentially stressing components. Consistent temps above 200°F (93°C) could be a concern[^17]. |
| Boost Pressure | PSI | 0 - 15 PSI (cruising, depending on terrain) | 0 - 25 PSI (spikes during acceleration) | 25 - 40+ PSI (sustained, dependent on load) | Indicates turbocharger performance and engine demand. Higher boost means more air, requiring more fuel[^18]. |
| Average MPG (Current Trip) | MPG | 15 - 22 MPG (highly variable based on speed, terrain, mods) | 10 - 16 MPG (highly variable based on traffic, idling) | 7 - 12 MPG (highly variable based on weight, terrain, speed) | Your real-time efficiency meter. Sudden drops without explanation (e.g., heavy headwind, major load change) can indicate an issue. Track via CTS3's built-in MPG calculation. |
| Distance to Empty (Fuel) | Miles | Relative to tank size & current MPG | Relative to tank size & current MPG | Relative to tank size & current MPG | Practical for trip planning. Available as standard PID on CTS3. |

## Dashboard 3: DEF, SCR & DPF System Health

**Focus:** Emissions system performance, especially DEF consumption efficiency and DPF regeneration status. Requires most EAS sensors.  
**CTS3 Setup:** Configure as your third gauge screen with focus on comparative readings and temperatures. May require EAS Universal Sensor Input modules for custom PIDs[^19].  
**Advanced Features:** Consider using the CTS3's DPF regeneration monitoring capabilities if available for your vehicle year[^20].

| Parameter | Units | Highway/Cruise | City/Stop-and-Go | Heavy Load/Towing | Notes |
|-----------|-------|----------------|------------------|-------------------|-------|
| NOx Sensor 1 (Pre-SCR) | ppm | 100 - 600 ppm (variable with load, lower at cruise) | 50 - 800 ppm (highly variable with acceleration/deceleration) | 300 - 1000+ ppm (higher with heavier load) | **If available via EAS.** Engine-out NOx. Provides a baseline for the SCR's work. Higher load = higher NOx[^21]. |
| NOx Sensor 2 (Post-SCR) | ppm | < 50 ppm (often < 10-20 ppm) | < 100 ppm (often < 20-50 ppm, variable) | < 100 ppm (should be significantly lower than Pre-SCR) | **If available via EAS. CRITICAL.** Indicates SCR catalyst efficiency. This value *must* be significantly lower than Pre-SCR NOx. If it's similar, your SCR system is not working (bad catalyst, bad DEF dosing, low DEF quality)[^22]. **CTS3 Alert:** Set Warning if Post-SCR NOx > 100 ppm, Alert if approaching Pre-SCR values. |
| Exhaust Gas Temp (EGT) (Pre-SCR) | °F / °C | 500 - 800°F (260 - 425°C) | 300 - 900°F (150 - 480°C) | 800 - 1200°F+ (425 - 650°C+) | **If available via EAS.** Important for SCR and DPF operation. SCR requires minimum temps to function[^23]. Will spike during regeneration. |
| Exhaust Gas Temp (EGT) (Post-SCR) | °F / °C | 500 - 800°F (260 - 425°C) | 300 - 900°F (150 - 480°C) | 800 - 1200°F+ (425 - 650°C+) | **If available via EAS.** Should be similar to Pre-SCR EGT, with some drop across the catalyst. High temps indicate active regeneration. |
| DPF Soot Load | % / grams | Low (e.g., < 20%) | Gradually increasing (starts low, builds with idling/city driving) | Low (active/passive regeneration likely) | **If available.** Indicates how full your DPF is. Will decrease rapidly during active regeneration. High soot load triggers more frequent regenerations[^24]. Can be a useful indicator of driving style impacting regen frequency. |
| DEF Dosing Rate | g/hr / ml/min | Varies significantly with load, RPM, and EGT. Look for consistency and "reasonableness." | Varies significantly. Will be low at idle, higher under load. | High (higher load demands more DEF) | **If available via EAS.** Indicates how much DEF the system is injecting. Too high = excessive consumption. Too low (when it should be dosing) = potential clogging or pump issue[^25]. Compare to engine load/NOx levels. |

### Important Reminders for Optimal CTS3 Monitoring

1. **EAS Sensors are Key:** For most of the specific DEF parameters (NOx, detailed EGTs, DEF pressure/flow), you will need to purchase and install Edge Accessory System (EAS) sensors that connect to your CTS3[^26]. The CTS3 will automatically detect new EAS devices when connected before boot-up.

2. **CTS3 Layout Configuration:**
   - **Access Layout Editor:** Swipe down from the top of the gauge screen and select "Edit Layout"
   - **Three Layouts Available:** Configure each for different monitoring purposes
   - **Gauge Customization:** Double-tap individual gauges to assign PIDs, set units, and configure alerts
   - **Theme Settings:** Customize colors and transparency via the pull-down menu[^27]

3. **Alert Setup:** Use the CTS3's individual gauge alert settings to set Warning and Alert thresholds. Access via double-tap on each gauge, then use the alert icon to configure:
   - **Alerts On/Off** toggle
   - **Alert Sounds On/Off** toggle  
   - **Warning threshold values**
   - **Alert threshold values**[^28]

4. **Data Logging:** Utilize the CTS3's recording feature to log vehicle data:
   - **Start Recording:** Pull down menu → Press Record button
   - **Stop Recording:** Press Stop button when sufficient data is gathered
   - **LED Indicator:** Red LED above recording icon shows active recording
   - **Data Analysis:** Use Edge's DataViewer software on PC to analyze recorded logs[^29]

5. **Learn Your Truck:** Pay attention to your truck's "normal" operating ranges for a few weeks without issues. These provided values are guidelines; your specific vehicle might have slightly different baseline numbers due to manufacturing tolerances, age, or modifications.

6. **Update Management:** Keep your CTS3 updated:
   - **Wi-Fi Updates:** Connect to Wi-Fi and use "Check for Updates" in Settings
   - **USB Updates:** Use Update Agent 1.0 software downloadable from Edge Products website[^30]

### Maintenance Intervals

Regular monitoring should complement, not replace, scheduled maintenance:

- **Fuel Filter:** Replace every 15,000-20,000 miles or as indicated by restriction readings
- **DEF System:** Use only ISO 22241-compliant DEF fluid[^34]
- **DPF Cleaning:** Professional cleaning may be required every 100,000-150,000 miles

## References and Footnotes

[^1]: Cummins Inc. (2014). ISB 6.7 Engine Owner's Manual. Cummins Inc.

[^2]: Edge Products. (2024). CTS3 Evolution Programmer & Monitor User Manual. Document ID: D10023820 Rev00. Edge Products LLC.

[^3]: Palmer Performance Engineering. (2024). DashCommand OBD-II Software and Custom PID Configuration Guide. Palmer Performance Engineering.

[^4]: Edge Products. (2024). Edge Accessory System (EAS) Installation and Setup Guide. Page 44-47. EAS sensors automatically detected when connected before device boot-up. Edge Products LLC.

[^5]: Edge Products. (2024). CTS3 User Manual - Individual Gauge Setup. Page 29-30. Alert settings accessible via double-tap on gauges, includes warning/alert thresholds and sound configuration. Edge Products LLC.

[^6]: Edge Products. (2024). CTS3 User Manual - Gauge Layouts. Page 23-24. Layout Editor accessed via pull-down menu from gauge screen, supports three customizable layouts. Edge Products LLC.

[^7]: Bosch. (2016). Common Rail Fuel Injection Systems. Robert Bosch GmbH. High-pressure fuel systems operate at pressures up to 30,000+ PSI and require precise pressure control for optimal performance.

[^8]: SAE International. (2018). "Diesel Fuel Injection Systems - Performance and Diagnostics." SAE Technical Paper 2018-01-0123.

[^9]: Fleetguard. (2020). Heavy Duty Filtration Guide. Cummins Filtration Inc. Fuel filter restriction above 10 PSI can significantly impact engine performance.

[^10]: EPA. (2010). "Diesel Engine Load Factors and Emission Rates." Environmental Protection Agency Technical Report EPA-420-F-10-027.

[^11]: Johnson Matthey. (2019). Diesel Particulate Filter Technology and Applications. Johnson Matthey PLC.

[^12]: ISO. (2018). ISO 22241-1:2019 Diesel engines — NOx reduction agent AUS 32. International Organization for Standardization.

[^13]: Edge Products. (2024). CTS3 User Manual - Advanced PID Lists. Page 29. Advanced PID selection available for detailed fuel system monitoring. Edge Products LLC.

[^14]: Edge Products. (2024). CTS3 User Manual - Recording Function. Page 33. Data logging feature accessed via pull-down menu on gauge screen. Edge Products LLC.

[^15]: Cummins Inc. (2015). "Fuel System Diagnostics and Troubleshooting Guide." Service Manual 4021477. Injector balance rates indicate individual cylinder performance and injector health.

[^16]: Delphi Technologies. (2017). Diesel Fuel System Components and Operation. Delphi Technologies PLC.

[^17]: ASTM International. (2020). ASTM D975 Standard Specification for Diesel Fuel Oils. ASTM International.

[^18]: Honeywell Garrett. (2018). Turbocharger Technology for Heavy-Duty Applications. Honeywell International Inc.

[^19]: Edge Products. (2024). CTS3 User Manual - EAS Universal Sensor Input. Page 45-46. Custom PID setup for non-EAS sensors using voltage scaling and custom calibrations. Edge Products LLC.

[^20]: Edge Products. (2024). CTS3 User Manual - Manual Regeneration. Page 49-50. DPF regeneration support available for compatible vehicles through Diagnostics menu. Edge Products LLC.

[^21]: EPA. (2007). "Diesel Exhaust Aftertreatment Systems." Environmental Protection Agency Technical Bulletin EPA-420-F-07-044.

[^22]: BASF. (2019). SCR Catalyst Technology for Diesel Emissions Control. BASF Corporation.

[^23]: Corning. (2020). Diesel Particulate Filter Substrates and Technology. Corning Incorporated.

[^24]: AVL. (2018). "DPF Soot Loading and Regeneration Strategies." AVL Technical Paper 2018-28-0023.

[^25]: Tenneco. (2019). DEF Dosing Systems and SCR Performance Optimization. Tenneco Inc.

[^26]: Edge Products. (2024). CTS3 User Manual - EAS Device Instructions. Page 44-47. EAS accessories automatically detected and configured when connected before device startup. Edge Products LLC.

[^27]: Edge Products. (2024). CTS3 User Manual - Theme Settings. Page 25. Gauge element color and transparency customization available via pull-down menu. Edge Products LLC.

[^28]: Edge Products. (2024). CTS3 User Manual - Alert Settings. Page 30. Individual gauge alert configuration includes warning/alert thresholds, sounds, and visual indicators. Edge Products LLC.

[^29]: Edge Products. (2024). CTS3 User Manual - Recording and DataViewer. Page 33-34. Data logging with PC analysis using DataViewer software for trend analysis and diagnostics. Edge Products LLC.

[^30]: Edge Products. (2024). CTS3 User Manual - Update Software. Page 12-13. Update Agent 1.0 available for download from Edge Products website for device updates via USB or Wi-Fi. Edge Products LLC.

[^31]: Edge Products. (2024). CTS3 User Manual - Trouble Codes. Page 48. Diagnostic trouble code viewing and clearing functionality with code descriptions. Edge Products LLC.

[^32]: Edge Products. (2024). CTS3 User Manual - Manual Regeneration. Page 49-50. DPF regeneration support including mobile regeneration for compatible diesel vehicles. Edge Products LLC.

[^33]: Edge Products. (2024). CTS3 User Manual - Performance Tests. Page 14-15. 0-60, 0-100, quarter-mile, and eighth-mile testing with digital drag slip output. For closed-course use only. Edge Products LLC.

[^34]: API. (2019). "Diesel Exhaust Fluid Quality Standards and Specifications." American Petroleum Institute Bulletin API-1509.
