# Discovery annotations (pico engine 1.8)

Shared events and queries in this repo use KRL `/** … */` doc comments so the engine can derive **ruleset schema** (Testing tab, `ruleset_schema` MCP, `krl check`).

## Annotated rulesets

| Ruleset | Shared surface |
|---------|----------------|
| `io.picolabs.sensor.network_bootstrap` | Query `getSensorCommunities`; event `sensor create_community` |
| `io.picolabs.sensor.community` | Queries `readings`, `lastTemperatures`; event `sensor initiation` |

Router rulesets (`io.picolabs.lht65.router`, etc.) expose device-specific queries via `shares` in `meta`; add `/** */` blocks when you promote new operator-facing events.

## Local check

From a pico-engine checkout with 1.8 `krl-compiler`:

```sh
npx krl-check io.picolabs.sensor.network_bootstrap.krl io.picolabs.sensor.community.krl
```

## Manifold context

Install bootstrap on the **Manifold pico**, send `sensor create_community` on the Manifold **app** channel, and `sensor initiation` on each community **sensor** channel. See [README](../README.md) and [manifold-api `docs/Manifold.md`](../../manifold-api/docs/Manifold.md#extending-manifold).
