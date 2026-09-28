"""Short, safe descriptions of failures in external data services.

Used in API error responses so operators can see *why* live data failed
(e.g. "HTTP 429 from marine-api.open-meteo.com") without exposing internals.
"""

import socket
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse

import requests


def describe_upstream_error(exc: BaseException) -> str:
    if isinstance(exc, HTTPError):
        return f"HTTP {exc.code} from {urlparse(exc.url or '').hostname}"
    if isinstance(exc, requests.HTTPError) and exc.response is not None:
        host = urlparse(exc.response.url).hostname
        return f"HTTP {exc.response.status_code} from {host}"
    if isinstance(exc, (TimeoutError, socket.timeout, requests.Timeout)):
        return "timed out"
    if isinstance(exc, URLError):
        reason = exc.reason
        if isinstance(reason, (TimeoutError, socket.timeout)):
            return "timed out"
        return f"connection failed ({type(reason).__name__})"
    if isinstance(exc, requests.ConnectionError):
        return "connection failed"
    return type(exc).__name__
