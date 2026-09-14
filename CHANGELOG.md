# Changelog

All notable changes to sensor-network rulesets and the Home Assistant companion.

## [Unreleased]

### Added

- **`io.picolabs.sensor.community`** — `readings:clear` event clears stored readings for one sensor (`name`, `sensor_name`, or `entity` attr).

### Fixed

- **`io.picolabs.sensor.community`** — `lastTemperatures` no longer assumes every thing has `io.picolabs.lht65.router`. It reads the latest stored community reading (any Dragino temperature field) and falls back to `lastTemperature` on the installed temperature router.
- **`io.picolabs.lht65.router`**, **`io.picolabs.lsn50.router`** — added shared `lastTemperature` query (LSE01 already had it). LHT65 returns internal temp; LSN50 returns the white probe.
- **All Dragino router rulesets** — `sensor new_readings` includes top-level `sensor_name` (Helium device `name`, falling back to the thing pico's wrangler name) so community `catch_new_readings` keys history correctly.

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

[1.0.0]: https://github.com/picolab/sensor-network/releases/tag/v1.0.0
