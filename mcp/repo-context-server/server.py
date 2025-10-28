#!/usr/bin/env python3
"""
repo-context-server
Minimal context service for the Jedsy platform.

Goal:
- Expose authoritative, machine-readable metadata about the platform's architecture.
- Allow an AI agent to ask "who owns what?" without guessing.

This is intentionally simple HTTP right now.
Later, this process can be wrapped or spoken to via MCP, but we start with a clean source of truth.
"""

from fastapi import FastAPI, Response
from fastapi.middleware.cors import CORSMiddleware
import json
import pathlib

app = FastAPI(
    title="Jedsy Repo Context Server",
    description="Provides static architectural and ownership metadata for the Jedsy drone network platform.",
    version="0.1.0",
)

# allow local dev usage, tighten later
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # tighten to Nebula/VPN CIDR later
    allow_credentials=True,
    allow_methods=["GET"],
    allow_headers=["*"],
)

BASE_DIR = pathlib.Path(__file__).resolve().parent
SCHEMA_PATH = BASE_DIR / "schema" / "platform_description.json"


@app.get("/healthz")
def healthz():
    return {"status": "ok", "service": "repo-context-server", "version": "0.1.0"}


@app.get("/platform-description")
def get_platform_description():
    """
    Return the static platform description as JSON.
    This defines:
    - environments (dev/prod clusters),
    - security model (Keycloak realm jedsy, roles),
    - network model (Nebula mesh, 192.168.100.x),
    - and all core services (PKI, HC, vpn-dashboard, monitor-service, iac).
    """
    try:
        with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
    except FileNotFoundError:
        return Response(
            content=json.dumps({"error": "platform_description.json not found"}),
            media_type="application/json",
            status_code=500,
        )
    return data


# optional: simple helper endpoint the agent can call to map questions to owners
@app.get("/who-owns/{topic}")
def who_owns(topic: str):
    """
    Very small convenience endpoint for agents.
    `topic` examples:
    - 'ip-assignment'
    - 'live-telemetry'
    - 'historical-flights'
    - 'deployment'
    - 'auth'
    """
    topic = topic.lower()

    mapping = {
        "ip-assignment": {
            "owner": "nebula-vpn-pki",
            "explanation": "PKI assigns Nebula VPN IPs and manages VpnEndpoint lifecycle."
        },
        "live-telemetry": {
            "owner": "nebula-healthcheck-service",
            "explanation": "HC stores raw telemetry (syslog/MAVLink) and current connectivity."
        },
        "historical-flights": {
            "owner": "monitor-service",
            "explanation": "monitor-service derives flights/incidents/statistics from HC data and keeps historical record."
        },
        "deployment": {
            "owner": "iac",
            "explanation": "iac (Pulumi) defines dev/prod clusters on AWS and deploys services via GitHub Actions."
        },
        "auth": {
            "owner": "Keycloak (realm jedsy)",
            "explanation": "Keycloak authenticates humans and services. PKI enforces roles like pki_user and pki_admin."
        },
    }

    if topic in mapping:
        return {
            "topic": topic,
            "owner_service": mapping[topic]["owner"],
            "details": mapping[topic]["explanation"],
        }
    else:
        return {
            "topic": topic,
            "owner_service": "unknown",
            "details": "No mapping defined yet. Update repo-context-server/who_owns() to extend."
        }

