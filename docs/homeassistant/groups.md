# Groups

This group will return "home" if any of the tracked devices are in the house

```yaml
### Occupancy #################
house_occupancy:
  name: occupancy
  entities:
    - device_tracker.erin_s_s22_ultra
    - device_tracker.ghost_mobile
  all: false
```

This group will return "home" if all tracked devices are in the house

```yaml
### Occupancy #################
house_occupancy:
  name: occupancy
  entities:
    - device_tracker.erin_s_s22_ultra
    - device_tracker.ghost_mobile
  all: true
```
