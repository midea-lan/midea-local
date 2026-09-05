"""Shared base classes for Midea devices, grouped by capability.

Each class here defines the public shape every device supporting that
capability (climate, fan, humidifier, ...) exposes, so a consumer (Home
Assistant or any other caller) can treat them uniformly regardless of
protocol differences.
"""
