# Discovery annotations (pico engine 1.8)

Shared events and queries in this repo use KRL `/** … */` doc comments so the engine can derive **ruleset schema** (Testing tab, `ruleset_schema` MCP, `krl check`).

## Annotated rulesets

| Ruleset | Shared surface |
|---------|----------------|
| `io.picolabs.sensor.network_bootstrap` | Query `getSensorCommunities`; event `sensor create_community` |
| `io.picolabs.sensor.community` | Queries `children`, `sensorThings`, `readings`, `lastTemperatures`, `test_push`; events `sensor initiation`, `readings clear` |
| `io.picolabs.sensor.temperatures_view` | Query `latestTemperatures`; view `temperatures` |
| `io.picolabs.sensor.thresholds` | Query `thresholds`; events `sensor new_threshold`, `sensor threshold_not_needed` |
| `io.picolabs.dragino` | Queries `get_payload`, `cToF`, `fix_temperatures`, `get_battery_status`, `get_battery_value` |
| `io.picolabs.iotplotter` | Queries `show_configuration`, `README`; event `sensor configuration` |
| `io.picolabs.lht65.router` | Queries `lastHeartbeat`, `lastHumidity`, `lastTemperature`, `lastInternalTemp`, `lastProbeTemp`; event `lht65 heartbeat` |
| `io.picolabs.lse01.router` | Queries `lastHeartbeat`, `lastMoisture`, `lastTemperature`, `lastConductivity`; event `lse01 heartbeat` |
| `io.picolabs.lsn50.router` | Queries `lastHeartbeat`, `lastTemperature`, `lastTemperature_01`, `lastTemperature_02`, `lastTemperature_03`; event `lsn50 heartbeat` |
| `io.picolabs.wl03a_lb.router` | Query `lastHeartbeat`; event `wl03a_lb heartbeat` |
| `io.picolabs.ldds20.router` | Queries `lastHeartbeat`, `lastLiquidLevel`; event `ldds20 heartbeat` |

## Local check

From a pico-engine checkout with 1.8 `krl-compiler`:

```sh
npx krl-check io.picolabs.sensor.network_bootstrap.krl io.picolabs.sensor.community.krl
```

## Manifold context

Install bootstrap on the **Manifold pico**, send `sensor create_community` on the Manifold **app** channel, and `sensor initiation` on each community **sensor** channel. See [README](../README.md) and [manifold-api `docs/Manifold.md`](../../manifold-api/docs/Manifold.md#extending-manifold).
