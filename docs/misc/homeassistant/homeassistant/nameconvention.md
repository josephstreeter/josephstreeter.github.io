---
title: Home Assistant Naming Convention
description: Comprehensive guide for naming entities, devices, automations, and scenes in Home Assistant for multi-home setups and Alexa integration.
author: josephstreeter
ms.date: 2025-08-11
---

## Home Assistant Naming Convention

## Overview

Managing multiple smart homes with a single Amazon account (Alexa integration) requires a clear, consistent naming scheme to avoid confusion and ensure smooth voice command operation. This guide provides best practices for naming rooms, devices, entities, automations, scenes, and more in Home Assistant.

---

## Multi-Home Room and Device Naming

### Principle: Location Prefixing

- **Format:** `<location> <room/device>`
- **Example (House 1):** Main House Living Room, Main House Kitchen, Main House Thermostat
- **Example (House 2):** Lake House Living Room, Lake House Kitchen, Lake House Thermostat

**Voice Command Example:**  
`Alexa, turn on the Main House Living Room lamp.`

### Alternative: Distinct Location-Based Names

- Use unique names for each home (e.g., Farmhouse, Apartment).
- **Example:** Farmhouse Living Room Lamp, Apartment Kitchen Light

**Tips:**

- Be consistent across all rooms/devices.
- Avoid similar names (e.g., "Primary House" vs. "Main House").
- After renaming, rediscover devices in the Alexa app.

---

## Entity Naming Scheme

### Core Principles

- **Readability:** Easy to understand at a glance.
- **Consistency:** Use a single pattern for all entities.
- **Uniqueness:** Every entity ID must be unique.
- **Simplicity:** Avoid special characters, spaces, and overly long names.

### General Structure

`[domain]_[location]_[device]_[attribute]`

- **domain:** Entity type (e.g., light, switch, sensor, binary_sensor)
- **location:** Physical location (e.g., living_room, kitchen, mbr)
- **device:** Descriptive device name (e.g., lamp, thermostat)
- **attribute:** Optional (e.g., temperature, power_consumption)

#### Examples

- `light_living_room_main`
- `switch_garage_door_opener`
- `sensor_kitchen_dishwasher_power_consumption`
- `binary_sensor_front_door_contact`

---

## Automations & Scripts

- **Automation:** `automation_[trigger]_[action]`
  - Example: `automation_hallway_motion_lights_on`
- **Script:** `script_[action]_[target]`
  - Example: `script_living_room_movie_mode`

---

## Media Players

- **Format:** `media_player_[location]_[device]`
  - Example: `media_player_living_room_tv`

---

## Scene Naming

### Recommended Scheme

- **Format:** `scene_[location]_[scenario]`
  - Example: `scene_living_room_movie_night`
  - Example: `scene_kitchen_cooking`
  - Example: `scene_house_away`

### Alternative Scheme

- **Format:** `scene_[scenario]_[location]`
  - Example: `scene_movie_night_living_room`

### Specialized Scenes

- For global/multi-room scenes: `scene_house_good_morning`
- For complex scenes: Use descriptive scenario names.

### Friendly Names

- Use natural, easy-to-say names for voice commands.
  - Example: Entity ID: `scene.living_room_movie_night`, Friendly Name: "Movie Time"

---

## Best Practices Summary

- Use lowercase and underscores.
- Be short, descriptive, and consistent.
- Document abbreviations.
- Prefix with domain (e.g., `light_`, `scene_`).
- Avoid redundancy.
- Group and sort for easy UI navigation.
- Use scenario-based names for scenes.
- Always rediscover devices in Alexa after renaming.

---

## Example Table

| Entity Type      | Example Entity ID                      | Friendly Name             |
|------------------|----------------------------------------|---------------------------|
| Light            | light_living_room_main                 | Living Room Ceiling Light |
| Switch           | switch_garage_door_opener              | Garage Door Opener        |
| Sensor           | sensor_kitchen_temperature             | Kitchen Temperature       |
| Binary Sensor    | binary_sensor_front_door_contact       | Front Door Contact        |
| Automation       | automation_hallway_motion_lights_on    | Hallway Motion Lights     |
| Script           | script_living_room_movie_mode          | Living Room Movie Mode    |
| Scene            | scene_living_room_movie_night          | Movie Time                |
| Media Player     | media_player_living_room_tv            | Living Room TV            |

---

## References

- [Home Assistant Documentation](https://www.home-assistant.io/docs/configuration/entities/)
- [Alexa Smart Home Integration](https://www.home-assistant.io/integrations/alexa/)
- [Voice Assistant Best Practices](https://www.home-assistant.io/docs/voice_control/)
