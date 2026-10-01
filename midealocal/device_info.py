"""Serializable device identity and confirmed discovery metadata.

Profiles are hints for a new connection. They deliberately exclude live state,
authentication session material, request identities, and timeout-based exclusions.
"""

import math
import time
from dataclasses import asdict, dataclass, field, fields
from typing import Any, cast

from midealocal.const import (
    MAX_BYTE_VALUE,
    MAX_DOUBLE_BYTE_VALUE,
    DeviceType,
    ProtocolVersion,
)

PROFILE_SCHEMA_VERSION = 1
PROFILE_MAX_AGE = 7 * 24 * 60 * 60
TEMPERATURE_RANGE_LENGTH = 2
COOL_MODE = 2
CAPABILITY_PAGES = frozenset({0, 1})


def _is_integer(value: object, minimum: int = 0, maximum: int | None = None) -> bool:
    return (
        isinstance(value, int)
        and not isinstance(value, bool)
        and value >= minimum
        and (maximum is None or value <= maximum)
    )


def _is_finite_number(value: object) -> bool:
    if not isinstance(value, int | float) or isinstance(value, bool):
        return False
    try:
        return math.isfinite(value)
    except OverflowError:
        return False


@dataclass(frozen=True, slots=True, kw_only=True)
class DeviceDescriptor:
    """Known appliance identity and network endpoint, without credentials."""

    name: str
    device_id: int
    device_type: DeviceType
    ip_address: str
    port: int
    device_protocol: ProtocolVersion
    model: str
    subtype: int
    mac: str | None = None
    serial_number: str | None = None

    def __post_init__(self) -> None:
        """Validate descriptors loaded from a persistent store."""
        integers = (
            _is_integer(self.device_id, 1),
            _is_integer(self.device_type, 0, MAX_BYTE_VALUE),
            _is_integer(self.port, 1, MAX_DOUBLE_BYTE_VALUE),
            _is_integer(self.device_protocol, 1),
            _is_integer(self.subtype),
        )
        if (
            not all(integers)
            or not all(
                isinstance(value, str)
                for value in (self.name, self.ip_address, self.model)
            )
            or not self.ip_address
        ):
            msg = "Invalid device descriptor"
            raise ValueError(msg)
        if any(
            value is not None and not isinstance(value, str)
            for value in (self.mac, self.serial_number)
        ):
            msg = "Invalid device hardware identity"
            raise ValueError(msg)
        object.__setattr__(self, "device_type", DeviceType(self.device_type))
        object.__setattr__(
            self,
            "device_protocol",
            ProtocolVersion(self.device_protocol),
        )

    def to_dict(self) -> dict[str, Any]:
        """Return a JSON-serializable descriptor."""
        return asdict(self)

    @classmethod
    def from_dict(cls, data: object) -> "DeviceDescriptor":
        """Read an untrusted stored descriptor or raise ValueError."""
        if not isinstance(data, dict):
            msg = "Invalid device descriptor"
            raise ValueError(msg)  # noqa: TRY004 - Cache decoders uniformly raise ValueError.
        try:
            return cls(**cast("dict[str, Any]", data))
        except (TypeError, ValueError) as exc:
            msg = "Invalid device descriptor"
            raise ValueError(msg) from exc


@dataclass(frozen=True, slots=True, kw_only=True)
class DeviceCredentials:
    """Device token and key, omitted from diagnostic representations."""

    token: str = field(repr=False)
    key: str = field(repr=False)

    def __post_init__(self) -> None:
        """Require hexadecimal credentials accepted by the existing transport."""
        try:
            bytes.fromhex(self.token)
            bytes.fromhex(self.key)
        except (TypeError, ValueError) as exc:
            msg = "Device credentials must be hexadecimal strings"
            raise ValueError(msg) from exc


@dataclass(frozen=True, slots=True, kw_only=True)
class DiscoveryProfile:
    """Confirmed protocol and capability metadata scoped to one appliance."""

    descriptor: DeviceDescriptor
    message_protocol_version: int
    capability_pages: tuple[int, ...] = ()
    capabilities: dict[str, bool] = field(default_factory=dict)
    uses_subprotocol: bool = False
    temperature_limits: dict[int, tuple[float, float]] | None = None
    created_at: float = field(default_factory=time.time)
    schema_version: int = PROFILE_SCHEMA_VERSION

    def __post_init__(self) -> None:
        """Reject invalid schemas, values, and incomplete discovery metadata."""
        if (
            not isinstance(self.descriptor, DeviceDescriptor)
            or type(self.schema_version) is not int
            or self.schema_version != PROFILE_SCHEMA_VERSION
            or not _is_integer(self.message_protocol_version, 0, MAX_BYTE_VALUE)
            or not _is_finite_number(self.created_at)
            or self.created_at < 0
            or not isinstance(self.uses_subprotocol, bool)
        ):
            msg = "Invalid discovery profile metadata"
            raise ValueError(msg)
        if not isinstance(self.capability_pages, tuple) or any(
            type(page) is not int or page not in CAPABILITY_PAGES
            for page in self.capability_pages
        ):
            msg = "Invalid confirmed capability pages"
            raise ValueError(msg)
        if not isinstance(self.capabilities, dict) or any(
            not isinstance(name, str) or not isinstance(value, bool)
            for name, value in self.capabilities.items()
        ):
            msg = "Invalid capability metadata"
            raise ValueError(msg)
        object.__setattr__(self, "capabilities", dict(self.capabilities))
        if self.temperature_limits is not None:
            if (
                not isinstance(self.temperature_limits, dict)
                or COOL_MODE not in self.temperature_limits
                or any(
                    not _is_integer(mode)
                    or not isinstance(bounds, tuple)
                    or len(bounds) != TEMPERATURE_RANGE_LENGTH
                    or not all(_is_finite_number(bound) for bound in bounds)
                    or bounds[0] > bounds[1]
                    for mode, bounds in self.temperature_limits.items()
                )
            ):
                msg = "Invalid temperature limit metadata"
                raise ValueError(msg)
            object.__setattr__(
                self,
                "temperature_limits",
                dict(self.temperature_limits),
            )

    def is_valid_for(
        self,
        descriptor: DeviceDescriptor,
        *,
        now: float | None = None,
        max_age: float = PROFILE_MAX_AGE,
    ) -> bool:
        """Check identity and expiry; DHCP addresses and display names may change."""
        now = time.time() if now is None else now
        if not _is_finite_number(now) or not _is_finite_number(max_age):
            return False
        if not 0 <= now - self.created_at < max_age:
            return False
        original = self.descriptor
        identity_fields = (
            "device_id",
            "device_type",
            "device_protocol",
            "model",
            "subtype",
        )
        if any(
            getattr(original, name) != getattr(descriptor, name)
            for name in identity_fields
        ):
            return False
        return all(
            not getattr(original, name)
            or not getattr(descriptor, name)
            or getattr(original, name) == getattr(descriptor, name)
            for name in ("mac", "serial_number")
        )

    def to_dict(self) -> dict[str, Any]:
        """Return JSON data containing only the explicitly allowed metadata."""
        result = asdict(self)
        result["capability_pages"] = list(self.capability_pages)
        if self.temperature_limits is not None:
            result["temperature_limits"] = {
                str(mode): list(bounds)
                for mode, bounds in self.temperature_limits.items()
            }
        return result

    @classmethod
    def from_dict(cls, data: object) -> "DiscoveryProfile":
        """Validate a JSON-decoded profile; expiry is checked by is_valid_for()."""
        if not isinstance(data, dict) or set(data) != {
            item.name for item in fields(cls)
        }:
            msg = "Invalid discovery profile fields"
            raise ValueError(msg)
        values = dict(data)
        limits = values["temperature_limits"]
        if not isinstance(values["capability_pages"], list) or (
            limits is not None
            and (
                not isinstance(limits, dict)
                or any(
                    not isinstance(mode, str)
                    or not mode.isdecimal()
                    or not isinstance(bounds, list)
                    for mode, bounds in limits.items()
                )
            )
        ):
            msg = "Invalid discovery profile collections"
            raise ValueError(msg)
        try:
            values["descriptor"] = DeviceDescriptor.from_dict(values["descriptor"])
            values["capability_pages"] = tuple(values["capability_pages"])
            if limits is not None:
                values["temperature_limits"] = {
                    int(mode): tuple(bounds) for mode, bounds in limits.items()
                }
            return cls(**values)
        except (TypeError, ValueError, OverflowError) as exc:
            msg = "Invalid discovery profile"
            raise ValueError(msg) from exc
