# Changelog

All notable changes to sensor-network rulesets and the Home Assistant companion.

## [Unreleased]

### Added

- **`io.picolabs.sensor.temperatures_view`** — XMLUI page for a pico created to display one community. `config new_relationship` with the community's did:webvh sends a Layer 2 invite. The page reads `lastTemperatures` over the established relationship and shows each reading time as MST. Settings stores the app channel's access token and a standard-time zone (PST, MST, CST, or EST; default MST) in the browser tab. The view shell sends the token on the temperature query, and reading times use the chosen zone.
- **Schema annotations** on the shared queries and operator events of the router, threshold, Dragino, IoTPlotter, and community rulesets. `sensorThings` is now a shared query so its annotation is part of the ruleset schema.

## [1.1.0] - 2026-10-26

Release aligned with **Manifold 1.8** and **pico-engine 1.8** (discovery annotations, `picoQuery` args map, Manifold app-channel policy).

### Added

- **`docs/DISCOVERY.md`** — operator notes for annotated rulesets and `krl check`.
- **`io.picolabs.sensor.community`** — `readings:clear` event clears stored readings for one sensor (`name`, `sensor_name`, or `entity` attr).
- **Discovery annotations** on `io.picolabs.sensor.network_bootstrap` and `io.picolabs.sensor.community` (`getSensorCommunities`, `sensor create_community`, `sensor initiation`, `readings`, `lastTemperatures`).
- **`io.picolabs.sensor.network_bootstrap`** — `widen_manifold_app_channel` extends the Manifold app channel so `sensor` events and bootstrap queries work on the same ECI as Manifold APIs (required after Manifold 1.8 app-channel narrowing).

### Fixed

- **`io.picolabs.sensor.community`** — `wrangler:picoQuery` calls pass explicit `{}` args (pico-engine 1.8).
- **`io.picolabs.sensor.community`** — `lastTemperatures` no longer assumes every thing has `io.picolabs.lht65.router`. It reads the latest stored community reading (any Dragino temperature field) and falls back to `lastTemperature` on the installed temperature router.
- **`io.picolabs.lht65.router`**, **`io.picolabs.lsn50.router`** — added shared `lastTemperature` query (LSE01 already had it). LHT65 returns internal temp; LSN50 returns the white probe.
- **All Dragino router rulesets** — `sensor new_readings` includes top-level `sensor_name` (Helium device `name`, falling back to the thing pico's wrangler name) so community `catch_new_readings` keys history correctly.
- **Integration harness** — flush via root UI `engine_ui/flush`; wait for Manifold community membership and `Community:Thing` link names.

## [1.0.0] - 2026-07-22

First release of the **Manifold Sensor Network** HA companion alongside existing KRL rulesets.

### Added

- **`custom_components/pico_mesh_sensor_network/`** — Home Assistant companion integration (depends on [Manifold hub](https://github.com/Picolab/manifold-home-assistant) `pico_mesh`).
- **LHT65 driver** — temperature, humidity, probe temperature, and last-reading timestamp entities on Manifold thing devices.
- **`hacs.json`** — HACS metadata for the companion.
- **README** — Home Assistant companion install and Docker mount instructions.

### Notes

- Sensor entities require both **Manifold** and **Manifold Sensor Network** integrations in HA.
- Community devices (e.g. Temperature Network) remain on the Manifold hub; the companion adds sensor entities on things only.

[1.1.0]: https://github.com/picolab/sensor-network/releases/tag/v1.1.0
[1.0.0]: https://github.com/picolab/sensor-network/releases/tag/v1.0.0
