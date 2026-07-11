---
uid: dashcommand-guide
title: "DashCommand App Guide for Diesel Truck Diagnostics"
description: "Comprehensive guide for using DashCommand v4.0+ on Android, iOS, and Windows for advanced vehicle monitoring, diagnostics, and data logging for diesel trucks."
author: "Joseph Streeter"
ms.date: "2025-07-26"
ms.topic: "how-to"
ms.service: "vehicles"
keywords: ["Diesel Truck", "DashCommand", "OBD-II", "Diagnostics", "Android", "iOS", "Windows", "Cummins", "Data Logging"]
---

## DashCommand Advanced Vehicle Diagnostics

DashCommand is an advanced in-car computer application that acts as a comprehensive diagnostic logging tool. Available for Windows, iOS (iPhone/iPod Touch/iPad), and Android platforms, DashCommand v4.0+ provides extensive real-time monitoring capabilities far beyond your vehicle's factory dashboard.

> [!IMPORTANT]
> DashCommand is a read-only diagnostic logging tool. It cannot perform flashing, modifying, tuning, CASE relearns, injector tests, or any other bi-directional control functions.

### Compatible Hardware Setup

**Supported OBD-II Interface Types:**

- **ELM327-based adapters** (Bluetooth/Wi-Fi) - Most common, default recommendation
- **Innovate Motorsports interfaces**
- **GoPoint Technology** (iPhone only)
- **OBDLink WiFi, OBDKey WLAN, Kiwi WiFi** - Automatically detected

**Device Requirements:**

- **Android Device:** Smartphone or tablet with Bluetooth/Wi-Fi capability
- **iOS Device:** iPhone, iPod Touch, or iPad
- **Windows:** PC with compatible interface connection

### Initial Connection Setup

1. **Hardware Connection:**
   - Plug OBD-II adapter into vehicle's diagnostic port
   - Turn vehicle ignition to "ON" position (engine can be off or running)

2. **Device Pairing:**
   - **Bluetooth:** Pair adapter through device Bluetooth settings
   - **Wi-Fi:** Connect to adapter's Wi-Fi network
   - **Auto-detection:** DashCommand automatically searches for common interfaces

3. **DashCommand Configuration:**
   - Open DashCommand application
   - Navigate to **Settings → Connection → OBD-II Interface Type**
   - Select appropriate interface type (ELM as default if unsure)
   - For Wi-Fi adapters, set **OBD-II Data Port** to AUTO for automatic detection

4. **Vehicle Setup:**
   - Access **Vehicle Manager** from main menu
   - Create new vehicle profile with accurate year/make/model/engine information
   - Enter fuel tank capacity, engine displacement, and fuel type for accurate calculations

> [!TIP]
> Enable **Auto Connect** in Settings to automatically connect to your vehicle when opening DashCommand.

## Main Menu Features

DashCommand's main menu provides access to all diagnostic and monitoring functions:

### Primary Functions

| Feature | Description | Use Case |
|---------|-------------|----------|
| **Connection** | Establish/monitor OBD-II connection | Required for all data access |
| **Dashboards** | Customizable gauge displays with Skin Sets | Primary monitoring interface |
| **Data Grid** | Advanced PID control and monitoring | Power users, custom data logging |
| **Diagnostics** | Read/clear trouble codes, monitor emissions status | Troubleshooting and maintenance |
| **Performance** | Quarter-mile and 0-60 timing with GPS | Performance testing and analysis |
| **Vehicle Manager** | Create/manage vehicle profiles | Multi-vehicle users |

### Advanced Features

| Feature | Description | Professional Use |
|---------|-------------|------------------|
| **Race Track** | GPS-based track mapping with acceleration analysis | Track day analysis |
| **Skid Pad** | G-force measurement using device accelerometer | Handling analysis |
| **Inclinometer** | Slope measurement for off-road applications | Off-road monitoring |
| **Console** | Debug information and connection diagnostics | Troubleshooting |

## Dashboard System and Skin Sets

### Understanding Skin Sets

DashCommand uses **Skin Sets** - collections of customizable dashboards where each dashboard displays exactly one screen worth of gauges. The default **Tuxedo skin** provides comprehensive vehicle monitoring across multiple specialized dashboards.

### Default Tuxedo Skin Dashboards

| Dashboard | Primary Function | Key Gauges |
|-----------|------------------|------------|
| **Performance** | Engine performance monitoring | RPM, Speed, Power, Torque, Boost Pressure |
| **Fuel Economy** | Real-time and historical fuel efficiency | Instant MPG, Average MPG, 3-hour MPG graph, Fuel Level, Distance to Empty |
| **Trip Stats** | Comprehensive trip data analysis | Min/Max engine speed, driving time, CO2 emissions, fuel costs |
| **Engine** | Engine health diagnostics | MAP, MAF, Intake Temperature, Timing Advance, Fuel Trims |
| **Fill-up** | Fuel cost tracking and economy calibration | Fuel cost entry, gallons added (for complete tank monitoring only) |

> [!WARNING]
> **Fill-up Dashboard:** Only use this feature if monitoring with DashCommand for the ENTIRE tank. Partial monitoring will drastically skew fuel economy calculations.

### Interactive Gauge Features

- **Touch to Toggle:** Many gauges can be touched to switch to alternate displays
- **Min/Max Cycling:** Touch gauge numbers to cycle between current, minimum, and maximum values
- **Real-time Updates:** All supported PIDs update continuously during vehicle operation

### Custom Dashboard Creation

1. **Access Gauge Editor:**
   - Navigate to **Gauges** from main menu
   - Touch screen to reveal edit button
   - Select **Edit** to enter customization mode

2. **Add/Configure Gauges:**
   - Touch existing gauge to edit or move
   - Use bottom buttons to add pages or additional gauges
   - Configure Style, Type, and PID assignments for each gauge

3. **Set Display Parameters:**
   - **Low/High Limits:** Define gauge range (can include negative values)
   - **Multiplier:** Adjust displayed numbers (e.g., 1000 for RPM to show 1,2,3 instead of 1000,2000,3000)
   - **Alert Thresholds:** Set warning and critical values

## Diagnostic Trouble Codes (DTCs)

### Accessing Diagnostic Functions

Navigate to **Diagnostics** from the main menu to access comprehensive trouble code management:

**Available Functions:**

- **Read Active Codes:** Current fault codes affecting vehicle operation
- **Read Pending Codes:** Codes that haven't fully triggered but are being monitored
- **Read Historical Codes:** Previously triggered codes that may have cleared
- **Clear Codes:** Remove all trouble codes from ECM memory
- **Emissions Monitor Status:** View readiness status of all emission control systems

> [!CAUTION]
> Clearing trouble codes will also clear all emissions monitor data as legally required. Some vehicles require engine-off (key on, engine not running) for code clearing.

### Code Display Information

- **OBD-II Standardized Codes:** Include full descriptions
- **Manufacturer-Specific Codes:** Display code numbers (descriptions may not be available)
- **Monitor Status Indicators:**
  - **Green Checkmark:** Monitor passed/complete
  - **Red Exclamation:** Monitor failed/not complete  
  - **Yellow Circle:** Monitor not supported by vehicle

## Advanced Data Logging and Analysis

### Data Grid for Power Users

The **Data Grid** view provides precise control over PID monitoring and data logging:

**Key Features:**

- **Exact PID Control:** Select specific parameters for monitoring or recording
- **Supported PID Identification:** Green checkmarks indicate vehicle-supported SAE.XXX PIDs
- **Calculated PIDs:** CALC.XXX PIDs are always available and computed by DashCommand
- **Persistent PID Integration:** Includes persistent PIDs in log files automatically

**PID Categories:**

- **SAE.XXX PIDs:** Standard OBD-II parameters directly from vehicle ECM
- **CALC.XXX PIDs:** DashCommand-calculated values (power, torque, efficiency, etc.)
- **AUX.XXX PIDs:** Auxiliary sensor inputs (aftermarket sensors)

### Data Logging Best Practices

1. **Dashboard Logging:**
   - Records only PIDs visible on current dashboard
   - Switching dashboards changes recorded PID set mid-session
   - Suitable for basic monitoring needs

2. **Data Grid Logging:**
   - Maintains consistent PID set throughout entire session
   - Recommended for comprehensive analysis
   - Professional diagnostic approach

3. **Export and Analysis:**
   - Export logs as CSV files for external analysis
   - Playback feature for reviewing recorded sessions
   - Loop playback option for continuous review

## Diesel Truck Specific PID Monitoring

### Critical Emission System Parameters

| PID Category | Key Parameters | Expected Values | Diagnostic Notes |
|--------------|----------------|-----------------|------------------|
| **DPF System** | Differential Pressure | 0-1.5 kPa idle; 3-8 kPa load | >2.5 kPa at idle indicates clogging |
| | Soot Load | <20-30% normal operation | >80% triggers regeneration |
| | Regeneration Status | Active/Inactive/Requested | 20-45 min completion normal |
| **DEF/SCR System** | NOx Pre-SCR | 100-600 ppm (load dependent) | Engine-out NOx baseline |
| | NOx Post-SCR | 70-90% reduction vs pre-SCR | <120 ppm when pre-SCR is 400 ppm |
| | DEF Level | 20-100% tank capacity | Low levels trigger vehicle derates |
| | DEF Pressure | 450-650 kPa normal | <400 kPa indicates system fault |
| **Engine Performance** | Boost Pressure | 10-30 psi under load | Low values indicate boost leaks |
| | Fuel Rail Pressure | Match desired pressure | Discrepancies indicate pump/injector issues |
| | EGT (Exhaust Gas Temp) | 350-550°F normal; 1000-1200°F regen | Monitor for sustained high temps |

### Enhanced PID Packages

DashCommand includes enhanced PID packages for specific vehicle makes/models when accurate year/make/model/engine information is entered in Vehicle Manager:

**Requirements for Enhanced PIDs:**

- Exact vehicle year, make, model, and engine type
- Use predefined values when available in dropdown menus
- Enhanced packages provide manufacturer-specific parameters beyond standard OBD-II

### Standard OBD-II PIDs for Diesel Monitoring

| PID Name | Description | Expected Values / Notes |
|----------|-------------|-------------------------|
| **DPF Differential Pressure** | Pressure drop across DPF | 0-1.5 kPa at idle; 3-8 kPa under load; >2.5 kPa at idle = clog |
| **DPF Soot Load (%)** | Soot accumulation in DPF | <20-30% normal; >80% = clogging; regen at ~70-75% |
| **DPF Regeneration Status** | Indicates active/inhibited/requested regen | Should complete in 20-45 min; frequent regens = issue |
| **EGT (Exhaust Gas Temp)** | Exhaust temp at various points | 350-550°F normal; 1000-1200°F during regen |
| **NOx Sensor (Pre-SCR)** | NOx before SCR catalyst | 100-600 ppm depending on load |
| **NOx Sensor (Post-SCR)** | NOx after SCR catalyst | 70-90% reduction vs. pre-SCR; e.g., <120 ppm if pre-SCR is 400 |
| **DEF Level** | Diesel Exhaust Fluid tank level | Should match actual tank; low triggers warnings |
| **DEF Pressure** | Pressure in DEF system | 450-650 kPa normal; <400 kPa = possible fault |
| **DEF Injector Command** | Commanded DEF injection rate | Should correlate with NOx reduction |
| **RPM** | Engine speed | Idle: ~700 RPM; varies with load |
| **Engine Load** | Calculated engine load | 0-100%; high load increases DPF/DEF activity |
| **Boost Pressure** | Turbo boost pressure | 10-30 psi under load; low = possible boost leak |
| **MAF (Mass Air Flow)** | Air intake measurement | Low = restricted airflow; compare to MAP/Baro |
| **Fuel Rail Pressure** | Pressure in fuel rail | Should match desired; discrepancies = pump/injector issue |

### Advanced Custom PIDs (2014 Ram 2500/3500 Cummins)

For advanced diagnostics, add these custom PIDs in DashCommand using the hex codes and formulas below. These are validated for 2013–2018 Ram 2500/3500 6.7L Cummins (SAE J1979 Mode 22, Chrysler/Cummins ECM).

| PID (Hex) | Description | Formula / Units | Expected Values / Notes |
|-----------|-------------|-----------------|------------------------|
| **22C101** | DPF Soot Mass | ((A*256)+B)/10 g | 5–25g normal; >40g = regen needed |
| **22C102** | DPF Differential Pressure | ((A*256)+B)/100 kPa | 0–1.5 kPa idle; 3–8 kPa under load |
| **22C10C** | DPF Regeneration Status | A | 0=Inactive, 1=Active |
| **22C120** | SCR Catalyst Temp | ((A*256)+B)/10 °C | 200–350°C normal; >500°C during regen |
| **22C123** | DEF Level | ((A*256)+B)/10 % | 20–100% (should match tank) |
| **22C124** | DEF Pressure | ((A*256)+B)/10 kPa | 400–650 kPa normal |
| **22C125** | DEF Quality | ((A*256)+B)/100 % | ~32.5% urea (API standard) |
| **22C130** | EGR Valve Position | A % | 0–100%; erratic = fault |
| **22C131** | Turbo Actuator Position | A % | 0–100%; low at high load = issue |
| **22C132** | Fuel Temperature | ((A*256)+B)/10 °C | -20°C to 60°C |
| **22C133** | Oil Temperature | ((A*256)+B)/10 °C | 80–110°C normal |

> [!NOTE]
> These PIDs are confirmed for 2014 Ram 2500/3500 Cummins but may require DashCommand custom PID setup. Refer to Cummins/Chrysler service documentation and community forums for latest definitions and formulas.

### Creating a Custom Dashboard for Diesel Monitoring

To monitor the most relevant PIDs for your diesel truck, follow these steps to create a custom dashboard:

1. **Open DashCommand and Connect to Your Vehicle:**
   - Ensure your OBD-II adapter is paired and DashCommand is connected.

2. **Navigate to Dashboards:**
   - Access **Dashboards** from the main menu
   - Select **Custom Dashboards** or use the gauge editor

3. **Add Gauges for Key PIDs:**
   - Use **Add Gauge** function to create new monitoring displays
   - For each gauge, select the relevant PID from the list or enter a custom PID
   - **Recommended Primary PIDs:**
     - DPF Soot Mass (22C101)
     - DPF Differential Pressure (22C102)
     - DPF Regeneration Status (22C10C)
     - SCR Catalyst Temp (22C120)
     - DEF Level (22C123)
     - DEF Pressure (22C124)
   - **Recommended Secondary PIDs:**
     - DEF Quality (22C125)
     - EGR Valve Position (22C130)
     - Turbo Actuator Position (22C131)
     - Fuel Temperature (22C132)
     - Oil Temperature (22C133)

4. **Configure Gauge Display:**
   - Set units, min/max values, and warning thresholds based on the expected values in the tables above
   - Arrange gauges for easy viewing while driving
   - Use appropriate gauge styles (digital, analog, bar graphs) for different parameter types

5. **Save and Use Your Dashboard:**
   - Save your custom dashboard configuration
   - Use it for real-time monitoring and troubleshooting
   - Export/import dashboard layouts for backup or sharing

> [!TIP]
> You can export/import dashboard layouts for backup or sharing. Access this feature through the dashboard management settings.

### Data Analysis Best Practices

**Look for Abnormal Values:**

- Compare readings to known normal values in the tables above
- Monitor trends over time rather than single data points
- Correlate multiple parameters (e.g., high soot load with frequent regens)

**Correlate Data Points:**

- **DPF Health:** Monitor soot load vs. differential pressure vs. regeneration frequency
- **DEF System:** Compare NOx reduction efficiency (pre vs. post SCR) with DEF consumption
- **Engine Performance:** Correlate boost pressure, fuel rail pressure, and load calculations

**Observe Trends:**

- Use DashCommand's graphing features to visualize changes over time
- Monitor parameter changes during different driving conditions
- Track long-term trends for predictive maintenance

**Post-Recording Analysis:**

- Export data as CSV files for detailed analysis in spreadsheet applications
- Create custom graphs and calculations for comprehensive diagnostics
- Maintain historical records for pattern recognition

## Vehicle Manager Configuration

### Creating Vehicle Profiles

Access **Vehicle Manager** from the main menu to create and manage vehicle-specific configurations:

**Essential Information Required:**

- **Year/Make/Model/Engine:** Must be accurate for enhanced PID packages
- **Engine Displacement:** Required for calculated parameters (power, torque)
- **Fuel Type:** Gasoline, Diesel, E85, etc.
- **Fuel Tank Capacity:** Needed for fuel level, distance to empty calculations

**Advanced Vehicle Settings:**

| Parameter | Purpose | Typical Values |
|-----------|---------|----------------|
| **Brake Specific Fuel Consumption (BSFC)** | Horsepower/torque calculations | 0.30-0.40 (turbo diesel), 0.40-0.50 (naturally aspirated), 0.50-0.60 (forced induction) |
| **Volumetric Efficiency** | Calculated parameter accuracy when SAE.MAP/MAF unavailable | 60-85% (default: 75%) |
| **Tire Size Specification** | Gear calculation accuracy | From tire sidewall (e.g., 255/60R17) |
| **Final Drive Ratios** | Transmission gear calculations | Axle ratio + transmission ratios for each gear |
| **Additional Weight** | Driver, passengers, cargo weight | Exclude fuel weight (calculated automatically) |

> [!IMPORTANT]
> Leave PID Settings blank unless instructed by Palmer Performance Support. Incorrect values will skew data calculations.

### Multi-Vehicle Management

- **Create separate profiles** for each physical vehicle
- **Different PID sets** even for identical models
- **Data separation** for fuel economy, trip stats, and logs
- **PID revalidation** option available if connection issues occur

## Performance Testing Features

### Quarter-Mile Timer

Professional drag strip simulation with comprehensive data collection:

**Available Tests:**

- **1/4 Mile:** Full quarter-mile timing with intermediate splits
- **1/8 Mile:** Eighth-mile timing (can stop early for results)
- **Custom Distance:** User-defined distance measurements

**Data Captured:**

- **Reaction Time:** When using optional start button with staging lights
- **60-foot, 330-foot, 1/8 mile splits**
- **Final elapsed time and trap speed**
- **Detailed results breakdown** via green results button

### 0-60 Timer (Customizable)

Automated speed-based timing system:

**Default Configuration:** 0-60 MPH timing
**Custom Settings:** Any start speed to any stop speed
**Operation:** Fully automatic - timer starts at start speed, stops at target speed
**Reset Function:** Slow below minimum speed to reset for new run

> [!CAUTION]
> Performance testing features are intended for closed circuit, legally sanctioned racing environments only.

## GPS-Based Analysis Tools

### Race Track Mapping

Real-time GPS track mapping with acceleration analysis:

**Features:**

- **Unlimited tracking** - no time or distance limits
- **Color-coded path:** Green (acceleration), Yellow (coasting), Red (braking)
- **Google Maps integration** (requires cell data)
- **Automatic zoom adjustment** for track layout
- **Persistent mapping** - tracks accumulate until manually reset

**Data Display:**

- GPS-calculated speed
- GPS accuracy indicator  
- Total distance traveled
- Built-in skid pad display

### Skid Pad G-Force Analysis

Accelerometer-based lateral force measurement:

**Capabilities:**

- **Continuous monitoring** even when viewing other screens
- **Automatic calibration** based on device orientation at startup
- **Manual recalibration** via Zero function if device moved
- **Unlimited data collection** with manual reset option
- **Orientation lock** while viewing to maintain accuracy

## Advanced Settings and Configuration

### General Settings

**Essential Configurations:**

- **Start in Dashboards:** Launch directly to gauge displays
- **Show Status Bar:** Display connection status, time, and data logging indicator
- **Fullscreen Mode:** Hide device status bar for maximum screen area
- **Auto Connect:** Automatically connect to vehicle on app launch
- **Demo Mode:** Display simulated data when not connected (testing only)

### Dashboard and Skin Management

**Skin Set Selection:**

- Access via **Settings → Dashboards → Selected Dashboard**
- **Download from DashXL.net:** Community-created dashboard layouts
- **Custom Creation:** Use free SkinXL Tool for advanced customization
- **Delete Skins:** Long-press unwanted skin sets for removal

### Data Management Settings

**Persistent PIDs Configuration:**

Persistent PIDs monitor continuously regardless of current screen:

- **Fuel Economy Tracking:** Requires persistent PIDs for accuracy
- **Trip Statistics:** Needs continuous monitoring for complete data
- **Performance Impact:** Disable on older devices if experiencing issues
- **Selective Monitoring:** Remove unused PIDs to optimize performance

**Data Logging Options:**

- **Loop Playback:** Continuously replay recorded data logs
- **Export Format:** CSV files for external analysis
- **Storage Management:** Regular cleanup of old log files

### Auxiliary Input Configuration

**Aftermarket Sensor Integration:**

- **Aux Input Type:** Configure for specific sensor brands (Innovate, etc.)
- **Custom PID Setup:** Use vehicle settings for aftermarket sensors
- **Example Configuration:** AUX.PLX.LAMBDA_0 for wideband O2 sensors
- **Aux Input Only:** Connect exclusively to auxiliary sensors (bypasses OBD-II)

**Supported Sensor Types:**

- Wideband oxygen sensors
- Boost pressure sensors
- Exhaust gas temperature sensors
- Custom voltage-based inputs

## Troubleshooting and Support

### Connection Issues

**Common Problems and Solutions:**

| Issue | Symptom | Solution |
|-------|---------|----------|
| **No Connection** | Orange connection indicator | Verify OBD-II adapter power, check interface type settings |
| **Intermittent Connection** | Connection drops during use | Check adapter placement, verify stable power supply |
| **Slow Response** | Delayed data updates | Reduce number of monitored PIDs, check interface compatibility |
| **Limited PIDs** | Few available parameters | Verify vehicle year/make/model, try PID revalidation |

### Console Debug Information

Access **Console** from main menu for detailed diagnostic information:

- **Connection attempt details**
- **Protocol negotiation status**
- **Error messages and codes**
- **Interface communication logs**

> [!NOTE]
> Console information is primarily for technical support. Contact <support@palmerperformance.com> with console details when reporting issues.

### Performance Optimization

**For Older Devices:**

1. **Disable Persistent PIDs** if experiencing lag
2. **Reduce Active Gauges** on current dashboard
3. **Close Background Apps** to free system resources
4. **Use Simpler Skin Sets** with fewer calculated parameters

**For Enhanced Performance:**

- Monitor only essential PIDs during data logging
- Use Data Grid view for precise PID control
- Export and clear old log files regularly
- Keep DashCommand updated to latest version

---

## References and Resources

### Official Documentation

- **[Palmer Performance DashCommand](https://www.palmerperformance.com/products/dashcommand/)** - Official product page and support
- **[DashXL.net](https://dashxl.net/)** - Community dashboard repository and skin sharing
- **SkinXL Tool** - Free dashboard creation software for advanced customization

### Technical Resources

- **[OBD-II PID Reference](https://en.wikipedia.org/wiki/OBD-II_PIDs)** - Standard parameter identification
- **[SAE J1979 Standard](https://www.sae.org/standards/content/j1979_201702/)** - OBD-II diagnostic communication protocol
- **Vehicle Service Manuals** - Manufacturer-specific PID documentation

### Community Support

- **[Cummins Forum](https://www.cumminsforum.com/)** - Diesel truck community discussions
- **[Diesel Place](https://www.dieselplace.com/)** - Multi-brand diesel truck forum
- **[TDIClub](https://forums.tdiclub.com/)** - Diesel passenger car community

### Support Contact

For technical support and manual improvements:
**Email:** <support@palmerperformance.com>

---

*This guide is based on DashCommand v4.0+ official documentation. Features and interfaces may vary between versions and platforms.*
