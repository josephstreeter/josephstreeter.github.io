---
title: Dynamic Groups
description: Complete guide to creating and managing dynamic groups that automatically update based on entity attributes
author: josephstreeter
ms.date: 2025-08-25
---

## Dynamic Groups

## Table of Contents

- [Overview](#overview)
- [Before You Begin](#before-you-begin)
- [How It Works](#how-it-works-the-three-step-process)
- [Step-by-Step Instructions](#example-and-step-by-step-instructions)
- [Alternative Examples](#alternative-dynamic-group-examples)
- [Validation and Testing](#validation-and-testing)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

In Home Assistant, a dynamic group is a group of entities whose members are not manually specified but are automatically updated based on rules. This is different from a static group, where you manually list every entity that belongs to it. Dynamic groups are essential for managing a growing number of devices without having to manually update your configuration every time you add a new one.

## Before You Begin

### Prerequisites

- Home Assistant Core 2023.4 or later
- Basic understanding of YAML configuration
- Access to configuration files (`configuration.yaml`, `groups.yaml`, `automations.yaml`)
- Template integration enabled (default in Home Assistant)
- Group integration enabled (default in Home Assistant)

### Configuration File Locations

- **Main configuration**: `config/configuration.yaml`
- **Groups**: `config/groups.yaml` (or in `configuration.yaml` if not using separate files)
- **Automations**: `config/automations.yaml` (or in `configuration.yaml`)

If these files don't exist, create them in your Home Assistant configuration directory.

## How It Works: The Three-Step Process

Since the group integration itself doesn't support templates, creating a dynamic group is a three-step process that uses different parts of Home Assistant together.

### 1. The Template Sensor 📝

The first step is to create a Template Sensor that identifies and lists all the entities you want in your group. This sensor doesn't do anything on its own; it just generates a list of entity IDs. We use a Jinja2 template with filters to find the entities based on a common attribute, such as device_class.

**Breaking down the template:**

```jinja2
{{ states.binary_sensor | selectattr('attributes.device_class', 'in', ['door', 'window']) | map(attribute='entity_id') | list }}
```

- `states.binary_sensor` - Gets all binary sensor entities
- `selectattr('attributes.device_class', 'in', ['door', 'window'])` - Filters for door/window sensors
- `map(attribute='entity_id')` - Extracts just the entity IDs
- `list` - Converts the result to a list format

To avoid the 255-character limit for a sensor's state, this list is stored as an attribute of the template sensor.

### 2. The Group Service ⚙️

The core of a dynamic group is the `group.set` service. This service can be called by an automation to create or redefine a group's members in real-time. It accepts the name of a group and a list of entities to include. Unlike the YAML configuration, this service can use templates to get its list of entities.

**Important**: The `group.set` service will create the group if it doesn't exist, or update the members if it does.

### 3. The Automation 🤖

The final step is to create an Automation that runs at a specific time (such as when Home Assistant starts) and calls the `group.set` service. The automation gets the list of entities from the attribute of your template sensor and passes it to the service.

When Home Assistant restarts, the automation runs again, the template sensor re-evaluates which entities are available, and the group is re-populated.

## Summary of Benefits

**Scalability**: You can add new devices to your system, and as long as they have the correct device_class, they will be automatically added to the group.

**Flexibility**: The template can be modified to create a group based on any attribute, such as area, name, or device_class.

**Centralized Control**: The dynamic group acts as a single entity, allowing you to use it in automations, scripts, and dashboards just like a regular group.

## Example and Step-by-Step Instructions

Here is a complete, working example of how to create a dynamic group of all your doors and windows.

### Step 1: Create the Template Sensor

First, you need to create the template sensor that will generate the list of entities. Add this code to your `configuration.yaml` file:

```yaml
template:
  - sensor:
      - name: "All Doors and Windows"
        unique_id: dynamic_doors_and_windows_list
        state: "Available"
        attributes:
          entities: >
            {{ states.binary_sensor | selectattr('attributes.device_class', 'in', ['door', 'window']) | map(attribute='entity_id') | list }}
          # Optional: Count of entities for easy monitoring
          count: >
            {{ states.binary_sensor | selectattr('attributes.device_class', 'in', ['door', 'window']) | list | length }}
```

### Step 2: Create a Placeholder Group

Next, create the group that the automation will manage. Add this to your `groups.yaml` file:

```yaml
all_openings:
  name: All Openings
  entities: []
```

**Note**: We leave the entities list empty because the automation will populate it.

### Step 3: Create the Automation

Finally, create the automation that will populate the group. Add this to your `automations.yaml` file:

```yaml
- alias: "Update dynamic openings group"
  description: "Updates the all_openings group with current door and window sensors"
  trigger:
    - platform: homeassistant
      event: start
    # Optional: Also update when template sensor changes
    - platform: state
      entity_id: sensor.all_doors_and_windows
      attribute: entities
  action:
    - service: group.set
      data:
        object_id: all_openings
        entities: >
          {{ state_attr('sensor.all_doors_and_windows', 'entities') }}
```

### Step 4: Restart and Validate

1. **Save all configuration files**
2. **Check configuration**: Go to Settings → System → Check Configuration
3. **Restart Home Assistant**: Settings → System → Restart
4. **Verify the group**: Check that `group.all_openings` exists in Developer Tools → States

## Alternative Dynamic Group Examples

### All Lights by Area

```yaml
# Template sensor for lights in living room
template:
  - sensor:
      - name: "Living Room Lights"
        unique_id: living_room_lights_list
        state: "Available"
        attributes:
          entities: >
            {{ states.light | selectattr('attributes.area_id', 'eq', 'living_room') | map(attribute='entity_id') | list }}
```

### All Motion Sensors

```yaml
# Template sensor for motion sensors
template:
  - sensor:
      - name: "All Motion Sensors"
        unique_id: all_motion_sensors_list
        state: "Available"
        attributes:
          entities: >
            {{ states.binary_sensor | selectattr('attributes.device_class', 'eq', 'motion') | map(attribute='entity_id') | list }}
```

### Battery-Powered Devices

```yaml
# Template sensor for low battery devices
template:
  - sensor:
      - name: "Battery Devices"
        unique_id: battery_devices_list
        state: "Available"
        attributes:
          entities: >
            {{ states | selectattr('attributes.battery_level', 'defined') | map(attribute='entity_id') | list }}
```

## Validation and Testing

### Verify Template Sensor

1. Go to **Developer Tools** → **States**
2. Find your template sensor (e.g., `sensor.all_doors_and_windows`)
3. Check the **entities** attribute contains the expected entity IDs
4. Verify the **count** matches the number of entities

### Test the Automation

```yaml
# Manual trigger for testing
- service: automation.trigger
  target:
    entity_id: automation.update_dynamic_openings_group
```

### Verify Group Population

1. Check **Developer Tools** → **States** for your group entity
2. Confirm the group contains the expected entities
3. Test group functionality in automations or dashboards

## Troubleshooting

### Template Sensor Not Updating

**Issue**: The template sensor shows old or incorrect entities.

**Solutions**:

- Restart Home Assistant to refresh templates
- Check template syntax in Developer Tools → Template
- Verify entity device_class attributes are set correctly

### Group Not Populating

**Issue**: The group exists but has no entities.

**Solutions**:

- Check automation logs: Settings → System → Logs
- Verify the template sensor attribute exists and contains data
- Manually trigger the automation for testing

### Entity ID Formatting Problems

**Issue**: Entities not being added due to formatting.

**Solutions**:

- Ensure template returns a list, not a string
- Remove the `| join(', ')` filter if using newer Home Assistant versions
- Check for extra spaces or characters in entity IDs

### Common Template Errors

**Invalid attribute access**:

```yaml
# ❌ Wrong
{{ states.binary_sensor | selectattr('device_class', 'eq', 'door') }}

# ✅ Correct  
{{ states.binary_sensor | selectattr('attributes.device_class', 'eq', 'door') }}
```

**Missing list conversion**:

```yaml
# ❌ Wrong - returns generator object
{{ states.light | selectattr('attributes.area_id', 'eq', 'kitchen') | map(attribute='entity_id') }}

# ✅ Correct - returns list
{{ states.light | selectattr('attributes.area_id', 'eq', 'kitchen') | map(attribute='entity_id') | list }}
```

## Best Practices

### Performance Optimization

- **Filter early**: Apply filters as early as possible in templates
- **Use specific domains**: Start with `states.light` instead of `states` when possible
- **Avoid complex calculations**: Keep templates simple for better performance

### Maintenance

- **Document your templates**: Add comments explaining complex logic
- **Use descriptive names**: Make template sensors and groups easily identifiable
- **Regular validation**: Periodically check that groups contain expected entities
- **Version control**: Track changes to dynamic group configurations

### Monitoring

- **Add count attributes**: Include entity counts in template sensors for monitoring
- **Set up alerts**: Create automations to notify if groups become empty unexpectedly
- **Log important events**: Use automation descriptions and trace logs for debugging

### Security

- **Validate inputs**: Ensure templates handle missing attributes gracefully
- **Test thoroughly**: Verify templates work with various device configurations
- **Backup configurations**: Keep backups before making template changes

---

Dynamic groups provide powerful automation capabilities in Home Assistant. With proper setup and monitoring, they can significantly reduce maintenance overhead while keeping your smart home configurations current and organized.
