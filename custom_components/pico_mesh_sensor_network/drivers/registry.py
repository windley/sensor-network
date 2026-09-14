"""Registered Manifold sensor-network router drivers."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

from . import lht65, lsn50

ParseFn = Callable[[str, Any], Any]


@dataclass(frozen=True)
class RouterDriver:
    """One sensor router ruleset exposed to Home Assistant."""

    ruleset: str
    prefix: str
    queries: dict[str, dict[str, str | None]]
    parse: ParseFn


ROUTER_DRIVERS: tuple[RouterDriver, ...] = (
    RouterDriver(
        ruleset=lht65.LHT65_ROUTER_RULESET,
        prefix="lht65",
        queries=lht65.LHT65_SENSOR_QUERIES,
        parse=lht65.parse_lht65_reading,
    ),
    RouterDriver(
        ruleset=lsn50.LSN50_ROUTER_RULESET,
        prefix="lsn50",
        queries=lsn50.LSN50_SENSOR_QUERIES,
        parse=lsn50.parse_lsn50_reading,
    ),
)
