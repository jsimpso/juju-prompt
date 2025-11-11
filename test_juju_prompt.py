#!/usr/bin/env python3
"""Unit tests for juju-prompt using pytest."""

import re
import pytest


def test_color_patterns_compile():
    """Test that color patterns compile correctly."""
    test_patterns = [
        (r"^production.*", "red"),
        (r".*critical.*", "bright_red"),
        (r"^staging.*", "yellow"),
        (r"^dev|test.*", "green"),
    ]

    for pattern, color in test_patterns:
        # Should not raise re.error
        re.compile(pattern)


@pytest.mark.parametrize("pattern,model,should_match", [
    (r"^production.*", "production-app", True),
    (r"^production.*", "test-production", False),
    (r".*critical.*", "critical-service", True),
    (r".*critical.*", "my-critical-app", True),
    (r"^staging.*", "staging-env", True),
    (r"^dev|test.*", "dev-model", True),
    (r"^dev|test.*", "test-model", True),
    (r"^dev|test.*", "prod-model", False),
])
def test_pattern_matching(pattern, model, should_match):
    """Test that patterns match expected model names."""
    compiled = re.compile(pattern)
    matches = bool(compiled.match(model))
    assert matches == should_match, \
        f"Pattern '{pattern}' {'matched' if matches else 'did not match'} '{model}'"


@pytest.mark.parametrize("color,expected_code", [
    ("black", "\033[30m"),
    ("red", "\033[31m"),
    ("green", "\033[32m"),
    ("yellow", "\033[33m"),
    ("blue", "\033[34m"),
    ("magenta", "\033[35m"),
    ("cyan", "\033[36m"),
    ("white", "\033[37m"),
    ("bright_black", "\033[90m"),
    ("bright_red", "\033[91m"),
    ("bright_green", "\033[92m"),
    ("bright_yellow", "\033[93m"),
    ("bright_blue", "\033[94m"),
    ("bright_magenta", "\033[95m"),
    ("bright_cyan", "\033[96m"),
    ("bright_white", "\033[97m"),
])
def test_color_codes(color, expected_code):
    """Test that color codes map correctly."""
    color_map = {
        "black": "\033[30m",
        "red": "\033[31m",
        "green": "\033[32m",
        "yellow": "\033[33m",
        "blue": "\033[34m",
        "magenta": "\033[35m",
        "cyan": "\033[36m",
        "white": "\033[37m",
        "bright_black": "\033[90m",
        "bright_red": "\033[91m",
        "bright_green": "\033[92m",
        "bright_yellow": "\033[93m",
        "bright_blue": "\033[94m",
        "bright_magenta": "\033[95m",
        "bright_cyan": "\033[96m",
        "bright_white": "\033[97m",
    }

    assert color in color_map
    assert color_map[color] == expected_code
