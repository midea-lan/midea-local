"""Midea local DB message."""

from midealocal.const import DeviceType
from midealocal.message import (
    MessageQueryToshibaIolife,
)

from .lua_converter import LuaConverter


class MessageQuery(MessageQueryToshibaIolife):
    """DB message query."""

    def __init__(self) -> None:
        """Initialize DB message query."""
        super().__init__(
            device_type=DeviceType.DB,
            converter=LuaConverter(),
        )
