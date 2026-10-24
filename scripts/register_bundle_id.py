#!/usr/bin/env python3
"""Register the iOS bundle id with App Store Connect if it is missing.

The App Store Connect app record itself cannot be created with this API.
"""

import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

import jwt

BUNDLE_ID = os.environ.get("BUNDLE_ID", "es.verkvest.cindarc")
APP_NAME = os.environ.get("APP_NAME", "Cindarc")
KEY_ID = os.environ["APPSTORE_API_KEY_ID"]
ISSUER_ID = os.environ["APPSTORE_API_ISSUER_ID"]
KEY_PATH = os.environ["APPSTORE_API_KEY_PATH"]


def token() -> str:
    key = open(KEY_PATH, "r", encoding="utf-8").read()
    now = int(time.time())
    encoded = jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"},
        key,
        algorithm="ES256",
        headers={"kid": KEY_ID, "typ": "JWT"},
    )
    if isinstance(encoded, bytes):
        encoded = encoded.decode("utf-8")
    return encoded


def request(method, url, body, auth):
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {auth}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            raw = response.read().decode("utf-8")
            return response.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        raw = error.read().decode("utf-8", errors="replace")
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            parsed = {"raw": raw}
        return error.code, parsed


def main() -> None:
    auth = token()
    query = urllib.parse.urlencode(
        {"filter[identifier]": BUNDLE_ID, "limit": "5"},
        safe="[]",
    )
    status, payload = request(
        "GET",
        f"https://api.appstoreconnect.apple.com/v1/bundleIds?{query}",
        None,
        auth,
    )
    if status != 200:
        print(json.dumps(payload, indent=2))
        sys.exit(f"bundle id lookup failed with HTTP {status}")
    existing = payload.get("data") or []
    if existing:
        print(f"bundle id {BUNDLE_ID} already registered ({existing[0].get('id')})")
        return
    body = {
        "data": {
            "type": "bundleIds",
            "attributes": {
                "name": APP_NAME,
                "identifier": BUNDLE_ID,
                "platform": "IOS",
            },
        }
    }
    status, payload = request(
        "POST",
        "https://api.appstoreconnect.apple.com/v1/bundleIds",
        body,
        auth,
    )
    if status in (201, 200):
        print(f"registered bundle id {BUNDLE_ID}")
        return
    if status == 409:
        print(f"bundle id {BUNDLE_ID} already registered")
        return
    print(json.dumps(payload, indent=2))
    sys.exit(f"bundle id registration failed with HTTP {status}")


if __name__ == "__main__":
    main()
