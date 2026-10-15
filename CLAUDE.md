# sensor-network — guide for coding agents

KRL rulesets for a **LoRaWAN sensor network built on Manifold**. Sensor communities and devices are Manifold picos; this repo adds sensor behavior on top of Manifold's thing/community platform and does **not** manage its own pico hierarchy. It is the reference example of a **mesh app** — the top layer of the stack — so follow its patterns when building other apps on Manifold.

Read these first if checked out alongside: `../pico-engine/CLAUDE.md` (KRL conventions, layering, terminology) and `../manifold-api/CLAUDE.md` (delegation, callbacks, notifications). This file covers only what is specific to this repo.

**Requires:** a bootstrapped Manifold (`../manifold-api`) on pico-engine 1.4+. Node 22 LTS. Docker for tests.

## Where this repo sits

```
engine ← wrangler ← manifold ← SENSOR-NETWORK (this repo)
```

Rules that follow: never reach past Manifold to wrangler/engine for lifecycle work Manifold already provides (community and thing creation, subscriptions, notifications). If Manifold lacks something, add a **generic** capability there, not a sensor-specific one.

## How the pieces connect

| Ruleset | Installed on | Role |
|---------|--------------|------|
| `io.picolabs.sensor.network_bootstrap` | Manifold pico | Handles `sensor create_community`; delegates to `manifold new_community` with `rcn` + `sensor_bootstrap: true`; on `wrangler child_initialized` installs `io.picolabs.sensor.community` on the child; records `ent:sensor_communities`; enables notification channels. Query `getSensorCommunities()` |
| `io.picolabs.sensor.community` | Community picos | Exposes a **`sensor` channel** (for `sensor initiation`) and a **`manifold_callback` channel** (allows `community:thing_created`). On `sensor initiation`: stashes type/RID list under `ent:pending{rcn}`, sends `manifold create_thing {name, callback_eci, rcn}` to parent; on callback: `community add_thing`, installs sensor RSs on the thing. Re-raises `community thing_event_occurred` into the `sensor` domain; threshold violations → `manifold add_notification` |
| `io.picolabs.sensor.thresholds` | Thing picos | Threshold monitoring |
| `io.picolabs.dragino`, `io.picolabs.iotplotter` | Thing picos | Shared Dragino decode helpers; plotting hooks |
| `io.picolabs.<type>.router` (lht65, lse01, lsn50, wl03a_lb) | Thing picos | Per-type payload decode → `sensor` events. `rids_to_install` is chosen by `type` at initiation |
| `custom_components/pico_mesh_sensor_network/` | Home Assistant | HACS custom component that reads the mesh; `hacs.json` at root |

Full event flow with diagram: `README.md`. Both bootstrap steps go through the Manifold **app channel**; the UI channel's event policy blocks the `sensor` domain.

## Commands (run from repo root)

```sh
npm install
npm run test:parse     # krl-compiler --verify on this repo's *.krl AND ../manifold-api (dependsOn)
npm test               # parse → Docker engine → Manifold bootstrap → sensor scenarios → teardown (~10s)
npm run test:keep      # leave the container up
npm run test:cleanup   # after a hung run
```

The harness **reuses manifold-api's stack**: `t/config.json` → `manifoldApiPath: "../manifold-api"`, `dependsOn` mounts it at `/var/manifold-api`, and a `.manifold-api` symlink gives TypeScript imports. `../manifold-api` must be checked out at a compatible commit. Scenarios in `t/scenarios/` (community creation, initiation per sensor type, health); readings/threshold and notification delivery are **not yet automated** — verify those manually or add a scenario.

## Gotchas specific to this repo (details in `MEMORY.md` and `../manifold-api/MEMORY.md`)

| Symptom | Cause / fix |
|---------|-------------|
| Thing created with Manifold RSs but community never finishes setup | `callback_eci` pointed at a channel whose policy rejects `community:thing_created`. Use the `manifold_callback` channel: `wrangler:channels("manifold_callback").head(){"id"}` |
| "This is a family channel and only the owner can use it" | You used `picoID` as the thing ECI. Use the subscription **Tx** (`event:attr("Tx")`) |
| `sensor` events rejected | Sent on the UI channel. Use the Manifold app channel or the community's `sensor` channel |
| Community created but `sensor.community` not installed | `meta:rulesetURI` is this repo's URL, so bootstrap can only install this repo's RSs. Manifold installs `io.picolabs.community`; gate the finish step on the `sensor_bootstrap` attr, not on `ent:pending{rcn}` alone |
| Parse gate fails on alexa / google_assistant | Those are pending-review RSs in manifold-api; they're in `parseExclude` in `t/config.json` |
| Nested entity write parse error | Composite path: `ent:sensor_things{[thingPicoID, "thing_eci"]} := …`, not chained `{a}{"b"}` |

## Adding a sensor type

1. Add `io.picolabs.<type>.router.krl` decoding the payload into `sensor` domain events (mirror `io.picolabs.lht65.router.krl`).
2. Add the type → RID list mapping in `io.picolabs.sensor.community` (`rids_to_install`).
3. Add an initiation scenario in `t/scenarios/sensor-initiation.scenario.ts` for the new type.
4. If Home Assistant should see it, add a driver under `custom_components/pico_mesh_sensor_network/drivers/`.
5. `npm run test:parse && npm test`.

## Working in this repo

- Keep sensor vocabulary **here**; keep Manifold generic. A PR that adds `sensor` anything to `../manifold-api` is a layering violation.
- Record new gotchas in `MEMORY.md`; engine-level ones also go to `../pico-engine/CLAUDE.md`.
- Don't commit or push; leave that to the maintainer. `OLD/` and `dotfile_for_temp_network/` are scratch and excluded from the parse gate.
