# Guidlines

The purpose of this page is to lay out general guidlines for configuring Home Assistant in such a way as to maximize functionality and flexibility while limiting complexity as much as possible.

## Components

- Entities
- Template Sensors
- Groups
- Scripts
- Automations
- Areas

## Layers

### Layer 1

The first layer consists of the device entities themselves. Lights, sensors, devices, etc.

Examples:

- Door/Window contact sensor
- Motion sensor
- Temperature sensor
- Smart thermostat
- Rest API
- Device states/attributes

### Layer 2

The second layer consolidates entity states using Template Sensors and Groups. Groups create a single representation of multiple entities of the same time to display a single status. Template sensors can be used to compare the values of multiple entities and present a value.

Examples - Groups:

- Determin the status of any or all of the windows in the house
- Determin if anyone is home based tracked devices like mobile devices

Example - Template Sensors:

- Compare the inside temperature with the outisde temperature to determine if the temperature outside is higher or lower than inside.
- Determin if the inside humidity is below 55% as the upper end of a comfortable range.
- Select data from a RestAPI sensor
Additional Template Sensors are used to enable or disable functionality through conditions in automations

Example - Binary Sensor

- Manually disable automations
- Trigger automations based on entity state(s)

### Layer 3

The third layer consists of Automations. Automations consist of triggers, conditions, and actions. Template Sensors and groups are used as triggers and conditions.

Example 1:

- Trigger: A template sensor deterines that the outside temperature above 75 degrees, its warmer inside than than the outside, the inside humifity is greater than 55%
- Conditions: Some or all of the windows are open and the AC is off
- Action: Send a notification to a group of users to close the windows and turn on the AC

Example 2:

- Trigger: A group of motion sensors detect motion
- Conditions: A group of tracked user devices shows that no one is home
- Action: Trigger an alert to a group of users that motion was detected in the house and turn on a scene for all inside lights

Example

## Layer 4

THe fourth layer consists of Areas, Scripts, and Scenes that are executed by Automations.

## Layer 5

The fifth layer consists of Groups that are used to consolidate recipients for notifications
