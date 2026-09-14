"""Refresh sensor router readings when the Manifold hub coordinator updates."""

from __future__ import annotations

import asyncio
import logging
from collections.abc import Callable
from dataclasses import dataclass, field
from typing import Any

from homeassistant.core import HomeAssistant, callback

from custom_components.pico_mesh.hub import (
    ManifoldThing,
    PicoEngineApi,
    PicoEngineApiError,
    PicoMeshCoordinator,
    WRANGLER_RULESET,
)

from .drivers.registry import ROUTER_DRIVERS, RouterDriver

_LOGGER = logging.getLogger(__name__)

Listener = Callable[[], None]


@dataclass
class ThingSensorState:
    """Cached router readings for one Manifold thing."""

    installed: dict[str, bool] = field(default_factory=dict)
    readings: dict[str, dict[str, Any]] = field(default_factory=dict)

    def is_installed(self, driver: RouterDriver) -> bool:
        return self.installed.get(driver.ruleset, False)

    def reading(self, driver: RouterDriver, query_name: str) -> Any:
        return self.readings.get(driver.ruleset, {}).get(query_name)


class SensorNetworkCoordinator:
    """Poll sensor router queries for things on a linked Manifold mesh."""

    def __init__(
        self,
        hass: HomeAssistant,
        hub_coordinator: PicoMeshCoordinator,
    ) -> None:
        self.hass = hass
        self.hub = hub_coordinator
        self.states: dict[str, ThingSensorState] = {}
        self._listeners: list[Listener] = []
        self._refresh_task: asyncio.Task[None] | None = None
        self._unsub_hub = hub_coordinator.async_add_listener(self._schedule_refresh)

    @callback
    def async_add_listener(self, update_callback: Listener) -> Callable[[], None]:
        """Register a listener for refreshed sensor readings."""

        self._listeners.append(update_callback)

        @callback
        def remove_listener() -> None:
            self._listeners.remove(update_callback)

        return remove_listener

    @callback
    def _notify_listeners(self) -> None:
        for listener in self._listeners:
            listener()

    @callback
    def _schedule_refresh(self) -> None:
        if self._refresh_task and not self._refresh_task.done():
            return
        self._refresh_task = self.hass.async_create_task(self.async_refresh())

    async def async_refresh(self) -> None:
        """Probe router rulesets and refresh shared queries for all things."""
        for thing in self.hub.data.things.values():
            await self._refresh_thing(self.hub.api, thing)
        self._notify_listeners()

    async def _refresh_thing(self, api: PicoEngineApi, thing: ManifoldThing) -> None:
        state = self.states.setdefault(thing.pico_id, ThingSensorState())
        try:
            rids = await api.sky_query(
                thing.tx_eci, WRANGLER_RULESET, "installedRIDs", {}
            )
        except PicoEngineApiError as err:
            _LOGGER.debug(
                "Sensor router probe failed for thing %s: %s", thing.pico_id, err
            )
            state.installed.clear()
            state.readings.clear()
            return

        installed_rids = rids if isinstance(rids, list) else []

        for driver in ROUTER_DRIVERS:
            if driver.ruleset not in installed_rids:
                state.installed[driver.ruleset] = False
                state.readings.pop(driver.ruleset, None)
                continue

            readings: dict[str, Any] = {}
            for query_name in driver.queries:
                try:
                    readings[query_name] = await api.sky_query(
                        thing.tx_eci, driver.ruleset, query_name, {}
                    )
                except PicoEngineApiError as err:
                    _LOGGER.debug(
                        "%s query %s failed for thing %s: %s",
                        driver.prefix,
                        query_name,
                        thing.pico_id,
                        err,
                    )
            state.installed[driver.ruleset] = True
            state.readings[driver.ruleset] = readings

    @callback
    def async_shutdown(self) -> None:
        """Remove listeners."""
        self._unsub_hub()
