#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import urllib.error
import urllib.parse
import urllib.request
import uuid


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Send a plain-text message to a Matrix room.")
    parser.add_argument("--message", help="Message body.")
    parser.add_argument("--message-file", help="File containing the message body.")
    parser.add_argument("--msgtype", default="m.notice", help="Matrix message type.")
    parser.add_argument(
        "--homeserver-url",
        default=os.environ.get("MATRIX_HOMESERVER_URL", ""),
        help="Matrix homeserver URL. Defaults to MATRIX_HOMESERVER_URL.",
    )
    parser.add_argument(
        "--access-token",
        default=os.environ.get("MATRIX_ACCESS_TOKEN", ""),
        help="Matrix access token. Defaults to MATRIX_ACCESS_TOKEN.",
    )
    parser.add_argument(
        "--room-id",
        default=os.environ.get("MATRIX_ROOM_ID", ""),
        help="Matrix room id. Defaults to MATRIX_ROOM_ID.",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=int(os.environ.get("MATRIX_REQUEST_TIMEOUT", "20")),
        help="Request timeout in seconds. Defaults to MATRIX_REQUEST_TIMEOUT or 20.",
    )
    parser.add_argument(
        "--user-agent",
        default=os.environ.get(
            "MATRIX_USER_AGENT",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0 Safari/537.36",
        ),
        help="HTTP User-Agent used for Matrix requests.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    message = args.message or ""
    if args.message_file:
        with open(args.message_file, "r", encoding="utf-8") as handle:
            message = handle.read()

    if not message.strip():
        print("matrix message is empty")
        return 1

    missing = []
    if not args.homeserver_url:
        missing.append("MATRIX_HOMESERVER_URL")
    if not args.access_token:
        missing.append("MATRIX_ACCESS_TOKEN")
    if not args.room_id:
        missing.append("MATRIX_ROOM_ID")
    if missing:
        print(f"matrix config missing: {', '.join(missing)}")
        return 2

    txn_id = uuid.uuid4().hex
    room_id = urllib.parse.quote(args.room_id, safe="")
    url = args.homeserver_url.rstrip("/")
    url += f"/_matrix/client/v3/rooms/{room_id}/send/m.room.message/{txn_id}"
    payload = {
        "msgtype": args.msgtype,
        "body": message,
    }
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {args.access_token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": args.user_agent,
        },
        method="PUT",
    )
    try:
        with urllib.request.urlopen(request, timeout=args.timeout) as response:
            body = response.read().decode("utf-8", errors="ignore")
    except urllib.error.HTTPError as exc:
        detail = exc.read(500).decode("utf-8", errors="ignore")
        print(f"matrix http error: {exc.code} {detail}".strip())
        return 1
    except urllib.error.URLError as exc:
        print(f"matrix request failed: {exc.reason}")
        return 1
    except TimeoutError:
        print(f"matrix request timed out after {args.timeout}s")
        return 1
    print(body or "matrix message sent")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
