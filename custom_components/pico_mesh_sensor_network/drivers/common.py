"""Shared parsing helpers for sensor router drivers."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any


def parse_numeric_reading(raw: Any) -> float | None:
    """Normalize a scalar sensor reading for Home Assistant state."""
    if raw is None or isinstance(raw, bool):
        return None
    if isinstance(raw, (int, float)):
        return float(raw)
    return None


def parse_heartbeat_timestamp(raw: Any) -> datetime | None:
    """Extract reported_at from a router's lastHeartbeat entity."""
    if not isinstance(raw, dict):
        return None
    reported_at = raw.get("reported_at")
    if isinstance(reported_at, (int, float)):
        return datetime.fromtimestamp(reported_at / 1000, tz=UTC)
    return None
