#!/usr/bin/env python3
"""Apply Nightwatch translations to Apple String Catalogs and StoreKit test metadata.

The translation JSON files are the reviewable source for added locales. This script
keeps the existing String Catalog architecture intact, validates printf placeholder
contracts, and updates only localization dictionaries/StoreKit localization metadata.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOCALIZABLE = ROOT / "Nightwatch/Resources/Localizable.xcstrings"
INFO_PLIST = ROOT / "Nightwatch/Resources/InfoPlist.xcstrings"
STOREKIT = ROOT / "Nightwatch.storekit"
TRANSLATIONS_DIR = Path(__file__).resolve().parent

TARGETS = {
    "pl": "pl_PL",
    "it": "it_IT",
    "es": "es_ES",
    "cs": "cs_CZ",
    "ja": "ja_JP",
    "ko": "ko_KR",
    "zh-Hant": "zh_TW",
}

# Small quality corrections found while auditing already-supported locales.
EXISTING_OVERRIDES: dict[str, dict[str, str]] = {
    "de-DE": {
        "onboarding.quiz.intent.question": "Wie weit würdest du für ein echtes Polarlicht fahren?",
        "onboarding.quiz.obstacle.option.notKnowingWhen": "Nicht zu wissen, wann ich rausgehen soll",
        "onboarding.solution.title": "Schon beim Abendessen wissen, ob sich die Nacht lohnt.",
    },
    "nl-NL": {
        "onboarding.quiz.intent.question": "Hoe ver zou je rijden voor echt noorderlicht?",
        "onboarding.reflection.title": "Op jouw breedtegraad zijn er ongeveer %@ kansrijke nachten per jaar.",
    },
    "fi": {
        "tonight.band.none": "Ei mahdollisuutta",
    },
}

PLACEHOLDER_RE = re.compile(r"%(?:\d+\$)?@|%%")


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def save_json(path: Path, payload: dict) -> None:
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def placeholders(value: str) -> list[str]:
    return PLACEHOLDER_RE.findall(value)


def translated_unit(value: str) -> dict:
    return {"stringUnit": {"state": "translated", "value": value}}


def validate_placeholders(key: str, source: str, translation: str, locale: str) -> None:
    source_tokens = placeholders(source)
    translated_tokens = placeholders(translation)
    if sorted(source_tokens) != sorted(translated_tokens):
        raise ValueError(
            f"{locale}:{key} placeholder mismatch: "
            f"source={source_tokens!r}, translation={translated_tokens!r}"
        )


def apply_string_catalogs() -> dict[str, dict]:
    catalog = load_json(LOCALIZABLE)
    info = load_json(INFO_PLIST)
    source_keys = set(catalog["strings"])

    loaded: dict[str, dict] = {}
    for locale in TARGETS:
        path = TRANSLATIONS_DIR / f"{locale}.json"
        translation = load_json(path)
        loaded[locale] = translation

        translated_keys = set(translation["strings"])
        missing = sorted(source_keys - translated_keys)
        extra = sorted(translated_keys - source_keys)
        if missing or extra:
            raise ValueError(
                f"{locale} catalog coverage mismatch: missing={missing}, extra={extra}"
            )

        for key, item in catalog["strings"].items():
            source = item["localizations"]["en"]["stringUnit"]["value"]
            value = translation["strings"][key]
            validate_placeholders(key, source, value, locale)
            item.setdefault("localizations", {})[locale] = translated_unit(value)

        for key, value in translation["infoPlist"].items():
            if key not in info["strings"]:
                raise ValueError(f"{locale}: unknown InfoPlist key {key}")
            source_item = info["strings"][key]
            source_item.setdefault("localizations", {})[locale] = translated_unit(value)

    for locale, overrides in EXISTING_OVERRIDES.items():
        for key, value in overrides.items():
            item = catalog["strings"][key]
            source = item["localizations"]["en"]["stringUnit"]["value"]
            validate_placeholders(key, source, value, locale)
            item["localizations"][locale] = translated_unit(value)

    save_json(LOCALIZABLE, catalog)
    save_json(INFO_PLIST, info)
    return loaded


def apply_storekit(loaded: dict[str, dict]) -> None:
    storekit = load_json(STOREKIT)
    products = {
        subscription["productID"]: subscription
        for group in storekit["subscriptionGroups"]
        for subscription in group["subscriptions"]
    }

    product_ids = {
        "annual": "com.augustinv.nightwatch.annual",
        "weekly": "com.augustinv.nightwatch.weekly",
    }

    for app_locale, translation in loaded.items():
        storekit_locale = TARGETS[app_locale]
        for period, product_id in product_ids.items():
            product = products[product_id]
            localized = translation["storeKit"][period]
            replacement = {
                "description": localized["description"],
                "displayName": localized["displayName"],
                "locale": storekit_locale,
            }
            product["localizations"] = [
                entry
                for entry in product.get("localizations", [])
                if entry.get("locale") != storekit_locale
            ]
            product["localizations"].append(replacement)
            product["localizations"].sort(key=lambda entry: entry["locale"])

    save_json(STOREKIT, storekit)


def main() -> None:
    loaded = apply_string_catalogs()
    apply_storekit(loaded)
    print(
        f"Applied {len(loaded)} locales across "
        f"{len(load_json(LOCALIZABLE)['strings'])} Localizable keys."
    )


if __name__ == "__main__":
    main()
