# Command Formating

## Format ```docker ps``` Output

The ```docker ps -format``` command allows for the formating of the command's output by specifying a Go template string.

- Names: ```{{.Names}}```
- ID: ```{{.ID}}```
- Image: ```{{.Image}}```
- Command: ```{{.Command}}```
- Created: ```{{.RunningFor}}```
- Status: ```{{.Status}}```
- Ports: ```{{.Ports}}```

```bash
docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}"
```

Output:

```text
CONTAINER ID   IMAGE                          NAMES              STATUS
0ebc7a0771fe   immauss/openvas:latest         openvas            Exited (143) 6 weeks ago
676c1497334b   weatherapp:0.0.1               heuristic_panini   Created
81320d86dd52   python_wx:1.0.1                python_wx          Exited (137) 4 months ago
b84ed4fe4739   rabbitmq:3-management-alpine   rabbitmq           Exited (0) 4 months ago
```

## Customize ```docker ps --format``` Output

The output of the command can be configured in the ```.docker/config.json``` file.

```bash
vi ~/.docker/config.json 
```

Add the following line. Edit to so the columns desired.

```text
{ "psFormat": "table {{.ID}}\\t{{.Image}}\\t{{.Names}}\\t{{.RunningFor}}\\t{{.Ports}}" }
```
