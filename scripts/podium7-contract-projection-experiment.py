#!/usr/bin/env python3
"""Pure experiment for projecting Podium Catalog JSON Contract 2.0 into BPT2 publication rows.

This is intentionally NOT production ingestion code. It tests whether the integration boundary can
remain a deterministic projection rather than becoming a second entity resolver.
"""

from __future__ import annotations

import copy
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


SUPPORTED_CONTRACT = "2.0"


@dataclass
class ProjectionState:
    # Podium canonical ID -> model year -> stable synthetic BPT2 publication key.
    rows: dict[str, dict[int | None, str]] = field(default_factory=dict)
    # Historical Podium ID -> live Podium canonical ID.
    redirects: dict[str, str] = field(default_factory=dict)
    # Last accepted canonical payload, retained to prove correction/replay semantics.
    snapshots: dict[str, dict[str, Any]] = field(default_factory=dict)


def require_entity(payload: dict[str, Any]) -> dict[str, Any]:
    if payload.get("contractVersion") != SUPPORTED_CONTRACT:
        raise ValueError("unsupported contract version")
    entity = payload.get("entity")
    if not isinstance(entity, dict):
        raise ValueError("entity is required")
    podium_id = entity.get("id")
    if not isinstance(podium_id, str) or not podium_id:
        raise ValueError("entity.id is required")
    return entity


def model_years(entity: dict[str, Any]) -> tuple[int | None, ...]:
    start = entity.get("model_year_from")
    end = entity.get("model_year_to")
    if start is None and end is None:
        return (None,)
    if not isinstance(start, int) or not isinstance(end, int):
        raise ValueError("model-year range must be complete or fully null")
    if start > end:
        raise ValueError("model-year range is invalid")
    # Experiment guard: projection expansion must be explicit and bounded. A larger range is a
    # product-policy question, not something the adapter may silently reinterpret.
    if end - start > 10:
        raise ValueError("model-year range is too wide for automatic point projection")
    return tuple(range(start, end + 1))


def stable_publication_key(podium_id: str, year: int | None) -> str:
    suffix = "unknown" if year is None else str(year)
    return f"podium:{podium_id}:my:{suffix}"


def apply(payload: dict[str, Any], state: ProjectionState) -> None:
    entity = require_entity(payload)
    podium_id = entity["id"]

    redirects_from = payload.get("redirectsFrom")
    if not isinstance(redirects_from, list) or any(not isinstance(x, str) or not x for x in redirects_from):
        raise ValueError("redirectsFrom must be an array of non-empty strings")

    # Redirect handling is identifier-driven. Labels are deliberately irrelevant.
    for historical_id in redirects_from:
        if historical_id == podium_id:
            raise ValueError("canonical ID cannot redirect from itself")
        prior_target = state.redirects.get(historical_id)
        if prior_target is not None and prior_target != podium_id:
            raise ValueError("historical ID cannot move between canonical targets silently")
        state.redirects[historical_id] = podium_id
        # If this process had previously seen the historical entity as canonical, retire its rows.
        state.rows.pop(historical_id, None)
        state.snapshots.pop(historical_id, None)

    years = model_years(entity)
    expected = {year: stable_publication_key(podium_id, year) for year in years}

    # Stable Podium ID owns publication identity. Correction replaces the projection shape for
    # that ID; it never creates another entity by comparing presentation labels.
    state.rows[podium_id] = expected
    state.snapshots[podium_id] = copy.deepcopy(payload)


def assert_experiment(fixtures: dict[str, Any]) -> None:
    initial = fixtures["initial"]
    corrected = fixtures["correctedSameId"]
    merged = fixtures["mergedWithRedirect"]
    label_collision = fixtures["sameLabelsDifferentId"]

    state = ProjectionState()

    apply(initial, state)
    canonical_id = initial["entity"]["id"]
    initial_rows = copy.deepcopy(state.rows)
    initial_snapshot = copy.deepcopy(state.snapshots[canonical_id])

    # 1. Replay is idempotent.
    apply(initial, state)
    assert state.rows == initial_rows
    assert state.snapshots[canonical_id] == initial_snapshot

    # 2. A two-year Podium range becomes two BPT2 point-publication identities without inventing
    # a year or collapsing the range.
    assert set(state.rows[canonical_id]) == {2025, 2026}
    assert len(set(state.rows[canonical_id].values())) == 2

    # 3. Correction with the same stable Podium ID updates the snapshot while retaining the same
    # publication keys for unchanged years.
    before_keys = copy.deepcopy(state.rows[canonical_id])
    apply(corrected, state)
    assert state.rows[canonical_id] == before_keys
    assert state.snapshots[canonical_id]["entity"]["variant"] == corrected["entity"]["variant"]

    # 4. Equal labels under a DIFFERENT Podium ID must not be merged by the adapter. This proves the
    # adapter is not a second string/entity resolver.
    other_id = label_collision["entity"]["id"]
    apply(label_collision, state)
    assert other_id != canonical_id
    assert other_id in state.rows
    assert canonical_id in state.rows

    # 5. Podium merge/redirect retires the historical publication rows and records the alias to the
    # surviving canonical ID without label matching.
    historical_id = merged["redirectsFrom"][0]
    assert historical_id == other_id
    apply(merged, state)
    assert state.redirects[historical_id] == canonical_id
    assert historical_id not in state.rows
    assert canonical_id in state.rows

    # 6. Marketplace availability is local by construction: all information needed for the read
    # projection is retained in state after apply(); no Podium callback exists in this experiment.
    offline_copy = copy.deepcopy(state)
    assert offline_copy.rows == state.rows
    assert offline_copy.snapshots[canonical_id]["contractVersion"] == SUPPORTED_CONTRACT

    print("PODIUM7_CONTRACT_VERSION: PASS")
    print("PODIUM7_REPLAY_IDEMPOTENT: PASS")
    print("PODIUM7_MODEL_YEAR_1_TO_N: PASS")
    print("PODIUM7_STABLE_ID_CORRECTION: PASS")
    print("PODIUM7_NO_LABEL_RESOLUTION: PASS")
    print("PODIUM7_REDIRECT_MERGE: PASS")
    print("PODIUM7_OFFLINE_PUBLICATION_STATE: PASS")


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {Path(sys.argv[0]).name} <fixture.json>", file=sys.stderr)
        return 2
    fixture_path = Path(sys.argv[1])
    fixtures = json.loads(fixture_path.read_text(encoding="utf-8"))
    assert_experiment(fixtures)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
