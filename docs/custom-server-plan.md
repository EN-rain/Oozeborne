# Moon Server — Implementation Complete

> **This document is archived.** The migration to Moon Server is complete.
> See [server-architecture.md](server-architecture.md) for the current system documentation.

---

## What Was Replaced

The original codebase used a legacy backend:
- `main_server/` — Legacy server configuration via Docker Compose
- Authoritative match handler in Lua
- Room create/join RPCs
- Legacy GDScript addon for auth and WebSocket

All of this has been replaced by **Moon Server** under `moon_server/`.

---

## Moon Server Stack (Current)

| Service | Language | Port | Status |
|---|---|---|---|
| `game-server` | Go | 8080 | ✅ Live |
| `lobby-api` | Node.js | 3000 | ✅ Live |
| `admin-portal` | Next.js | 3001 | ✅ Live |
| `postgres` | — | 5432 | ✅ Live |
| `redis` | — | 6379 | ✅ Live |

---

## Completed Milestones

- ✅ M0 — Design Freeze (stack, protocols, schema defined)
- ✅ M1 — Local Stack Boots (Docker Compose up and healthy)
- ✅ M2 — Auth + Identity (JWT login/register, session restore)
- ✅ M3 — Rooms: Create/Join + Redis Registry
- ✅ M4 — Realtime Bring-up (20Hz WebSocket, input → snapshot)
- ✅ M5 — Feature Parity (lobby, class selection, start game)
- ✅ Admin Portal — Moon Control Center (player DB, live tuning, graveyard)

---

## Decommissioned

The following are no longer part of the active stack:
- Legacy Docker Compose and Lua modules
- Legacy GDScript addon
- Legacy API codegen tool
