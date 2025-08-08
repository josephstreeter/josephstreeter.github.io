# CuddeLink Network Setup

Configure your CuddeLink camera network with one HOME camera and multiple REMOTE cameras for comprehensive coverage.

## Network Overview

CuddeLink is Cuddeback's wireless camera network system that allows multiple cameras to communicate and share images through a mesh network. The system requires:

- **One HOME camera** - Central hub that receives all images
- **Multiple REMOTE cameras** - Capture and transmit images to the HOME camera
- **Proper signal coverage** - Cameras must maintain communication links

## [Home Camera Configuration](#tab/setuphome)

The HOME camera serves as the central hub for your CuddeLink network and must be configured first.

> [!IMPORTANT]
> Position the HOME camera in a central, easily accessible location for optimal network coverage.

### Home Camera Setup Steps

1. **Initial Preparation**
   - Insert SD card into the camera
   - Configure basic camera settings (date, time, delays, etc.)
   - **Required:** Set the date and time on the HOME camera

2. **Access CuddeLink Menu**
   - Press `MODE` until `COMMANDS` LED is illuminated
   - Press `MORE` until `CL MENU` is displayed
   - Press `UP` twice to confirm and enter the menu

3. **Configure Network Settings**

   | Setting | Action | Recommended Value |
   |---------|--------|-------------------|
   | **CL MODE** | Leave as default | `HOME` |
   | **CL LOC** | Press `MORE`, then `UP`/`DOWN` | `001` (unique location ID) |
   | **CL CHAN** | Press `MORE` twice, set channel | `1-16` (note this number) |

   > [!IMPORTANT]
   > **Record the channel number** - all REMOTE cameras must use the same channel.

4. **Activate Camera**
   - Press `MODE` until display shows `ARMING`
   - Camera is now ready to receive images from REMOTE cameras

## [Remote Camera Configuration](#tab/setupremote)

REMOTE cameras capture images and transmit them to the HOME camera through the CuddeLink network.

> [!IMPORTANT]
> **Setup Location:** Configure each REMOTE camera near the HOME camera or an already-configured REMOTE camera to ensure proper link establishment before final deployment.

### Remote Camera Setup Steps

1. **Initial Preparation**
   - Insert SD card into the camera
   - Configure basic camera settings (date, time, delays, etc.)

2. **Access Link Menu**
   - Press `MODE` until `COMMANDS` LED is illuminated
   - Press `MORE` until `LINK MENU` is displayed
   - Press `UP` to activate the `LINK MODE` menu

3. **Configure Camera Mode**
   - Press `UP` to change from `HOME` to `REMOTE`

   > [!WARNING]
   > **REPEATER Mode:** Cameras set to `REPEATER` will relay images from other cameras but will not capture their own images.

4. **Network Configuration**

   | Setting | Action | Notes |
   |---------|--------|-------|
   | **LINK ID** | Press `MORE`, set unique number | Each camera needs unique ID |
   | **LINK CHANNEL** | Press `MORE`, set to match HOME | Must match HOME camera channel |
   | **LINK COUNT** | Press `MORE`, leave default | Default: 250 |

5. **Signal Strength Testing**
   - Press `MORE` to display `LINK LEVEL`
   - Wait for signal reading (initially shows `----`)
   - **Target:** Achieve signal level of `99 GOOD` or at least `15`

   > [!WARNING]
   > **Poor Signal:** If no signal appears within 3-4 minutes or signal is less than 15, move closer to the HOME camera or another REMOTE camera.

6. **Deployment Testing**
   - Begin moving camera toward final location
   - Monitor signal strength during movement
   - **Minimum:** Maintain signal level above `20` throughout path
   - If signal drops below 20, select a closer location

7. **Final Activation**
   - Deploy camera in final position
   - Press `MODE` until display shows `ARMING`
   - Camera is now active and connected to the network

## Network Planning

### Coverage Strategy

- **Central Hub Placement** - Position HOME camera for maximum reach
- **Signal Mapping** - Test signal strength before final deployment
- **Repeater Cameras** - Use REPEATER mode to extend network range when needed
- **Redundant Paths** - Plan multiple communication routes for reliability

### Camera Identification System

| Camera Type | Recommended ID Range | Purpose |
|-------------|---------------------|---------|
| **HOME** | `001` | Central hub |
| **REMOTE** | `002-099` | Image capture cameras |
| **REPEATER** | `100-199` | Signal relay only |

### Channel Management

- **Single Channel per Network** - All cameras must use the same channel
- **Avoid Interference** - Test different channels if experiencing issues
- **Document Settings** - Keep record of channel assignments for troubleshooting

## Deployment Best Practices

### Site Survey

1. **Test Setup** - Configure all cameras near HOME camera first
2. **Signal Testing** - Move cameras gradually to final positions
3. **Coverage Verification** - Ensure all areas have adequate signal
4. **Backup Planning** - Identify alternative locations if signal fails

### Installation Tips

- **Height Considerations** - Mount cameras 8-10 feet high for optimal coverage
- **Obstacle Avoidance** - Minimize trees, buildings, and terrain between cameras
- **Weather Protection** - Ensure proper sealing and mounting
- **Access Planning** - Maintain easy access for maintenance and SD card retrieval

## Related Topics

- [Camera Interface](index.md#camera-interface) - Understanding camera controls and indicators
- [Firmware Updates](firmware.md) - Keep cameras updated before network setup
- [Troubleshooting](troubleshooting.md) - Solving network connectivity issues
