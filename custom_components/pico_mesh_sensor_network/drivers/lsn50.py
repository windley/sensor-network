"""LSN50 sensor-network router driver."""

from __future__ import annotations

from typing import Any

from .common import parse_heartbeat_timestamp, parse_numeric_reading

LSN50_ROUTER_RULESET = "io.picolabs.lsn50.router"

LSN50_SENSOR_QUERIES: dict[str, dict[str, str | None]] = {
    "lastTemperature_01": {
        "key": "white_probe_temperature",
        "name": "White probe temperature",
        "device_class": "temperature",
        "state_class": "measurement",
        "unit": "°F",
    },
    "lastTemperature_02": {
        "key": "red_probe_temperature",
        "name": "Red probe temperature",
        "device_class": "temperature",
        "state_class": "measurement",
        "unit": "°F",
    },
    "lastTemperature_03": {
        "key": "black_probe_temperature",
        "name": "Black probe temperature",
        "device_class": "temperature",
        "state_class": "measurement",
        "unit": "°F",
    },
    "lastHeartbeat": {
        "key": "last_reading",
        "name": "Last reading",
        "device_class": "timestamp",
        "state_class": None,
        "unit": None,
    },
}


def parse_lsn50_reading(query_name: str, raw: Any) -> Any:
    """Normalize one LSN50 query result for Home Assistant state."""
    if query_name == "lastHeartbeat":
        return parse_heartbeat_timestamp(raw)
    return parse_numeric_reading(raw)
