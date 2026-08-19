#!/usr/bin/env python3
"""Validate Nightwatch localization resource coverage beyond translation generation."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "Nightwatch/Resources/Localizable.xcstrings"
INFO = ROOT / "Nightwatch/Resources/InfoPlist.xcstrings"
STOREKIT = ROOT / "Nightwatch.storekit"
LEGAL = ROOT / "Nightwatch/Legal/Documents"

APP_LOCALES = [
    "en", "nb", "sv", "fi", "da", "de-DE", "nl-NL", "fr",
    "pl", "it", "es", "cs", "ja", "ko", "zh-Hant",
]
LEGAL_LOCALES = [locale for locale in APP_LOCALES if locale != "en"]
STOREKIT_LOCALES = [
    "en_US", "nb_NO", "sv_SE", "fi_FI", "da_DK", "de_DE", "nl_NL", "fr_FR",
    "pl_PL", "it_IT", "es_ES", "cs_CZ", "ja_JP", "ko_KR", "zh_TW",
]
URL_RE = re.compile(r"https://[^\s)>]+")


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def require_catalog_coverage() -> int:
    catalog = load(CATALOG)
    strings = catalog["strings"]
    expected = set(APP_LOCALES)
    for key, item in strings.items():
        actual = set(item.get("localizations", {}))
        missing = expected - actual
        if missing:
            raise ValueError(f"{key}: missing catalog locales {sorted(missing)}")
        for locale in APP_LOCALES:
            unit = item["localizations"][locale].get("stringUnit", {})
            if not unit.get("value"):
                raise ValueError(f"{key}: empty {locale} value")
            # Apple may keep manually-authored development-language entries in
            # the `new` state. Shipping translations must be explicitly marked
            # translated; the English source only needs to be present.
            if locale != "en" and unit.get("state") != "translated":
                raise ValueError(f"{key}: incomplete {locale} translation")
    return len(strings)


def require_info_plist_coverage() -> int:
    info = load(INFO)
    expected = set(APP_LOCALES)
    for key, item in info["strings"].items():
        actual = set(item.get("localizations", {}))
        missing = expected - actual
        if missing:
            raise ValueError(f"{key}: missing InfoPlist locales {sorted(missing)}")
        for locale in APP_LOCALES:
            unit = item["localizations"][locale].get("stringUnit", {})
            if not unit.get("value"):
                raise ValueError(f"{key}: empty InfoPlist value for {locale}")
            if locale != "en" and unit.get("state") != "translated":
                raise ValueError(f"{key}: incomplete InfoPlist translation for {locale}")
    return len(info["strings"])


def require_storekit_coverage() -> None:
    storekit = load(STOREKIT)
    expected = set(STOREKIT_LOCALES)
    products = [
        subscription
        for group in storekit["subscriptionGroups"]
        for subscription in group["subscriptions"]
    ]
    for product in products:
        actual = {entry["locale"] for entry in product.get("localizations", [])}
        missing = expected - actual
        if missing:
            raise ValueError(
                f"{product['productID']}: missing StoreKit locales {sorted(missing)}"
            )
        for entry in product["localizations"]:
            if entry["locale"] in expected:
                if not entry.get("displayName") or not entry.get("description"):
                    raise ValueError(
                        f"{product['productID']}:{entry['locale']}: incomplete metadata"
                    )
                if "Nightwatch" not in entry["displayName"]:
                    raise ValueError(
                        f"{product['productID']}:{entry['locale']}: product name changed"
                    )


def require_legal_coverage() -> None:
    source_urls = {}
    for name in ("Privacy", "Terms"):
        source = (LEGAL / f"{name}.md").read_text(encoding="utf-8")
        source_urls[name] = set(URL_RE.findall(source))

    for locale in LEGAL_LOCALES:
        folder = LEGAL / f"{locale}.lproj"
        for name in ("Privacy", "Terms"):
            path = folder / f"{name}.md"
            if not path.exists():
                raise ValueError(f"{locale}: missing {name}.md")
            localized = path.read_text(encoding="utf-8")
            if not localized.strip():
                raise ValueError(f"{locale}:{name}: empty legal document")
            missing_urls = source_urls[name] - set(URL_RE.findall(localized))
            if missing_urls:
                raise ValueError(
                    f"{locale}:{name}: missing source URLs {sorted(missing_urls)}"
                )
            if "Nightwatch" not in localized:
                raise ValueError(f"{locale}:{name}: product name missing")


def main() -> None:
    catalog_count = require_catalog_coverage()
    info_count = require_info_plist_coverage()
    require_storekit_coverage()
    require_legal_coverage()
    print(
        f"Validated {catalog_count} app strings + {info_count} InfoPlist string "
        f"across {len(APP_LOCALES)} locales, StoreKit metadata for "
        f"{len(STOREKIT_LOCALES)} locales, and legal documents for "
        f"{len(LEGAL_LOCALES)} non-English locales."
    )


if __name__ == "__main__":
    main()
