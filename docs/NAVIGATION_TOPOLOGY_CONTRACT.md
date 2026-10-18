# Navigation Topology Contract

## Scope and boundary

`native/include/route_topology.hpp` and `native/src/route_topology.cpp` provide an engine-independent traversal graph for a later Godot navigation adapter. It stores zone identifiers and enabled/disabled traversal links only. It has **no** world coordinates, collision, NavMesh, `Vector3`, scene path, enemy spawn, cover, or Highrise endpoint data.

This is M4 infrastructure, not Highrise navigation evidence. `MP_RF_02` remains locked and no current source claims that any roof, office, lobby, bridge, gap, rappel, lift, zipline, supply node, or wave route has been connected.

## Core contract

`RouteTopology` accepts a zone only once and accepts a link only when:

1. the link ID, source zone, and destination zone are non-empty;
2. both endpoint zones are already registered;
3. the link does not connect a zone to itself; and
4. no link with that ID already exists.

A link has an explicit traversal kind (`walk`, `bridge`, `rappel`, `lift shaft`, or `zipline`), direction policy, and enabled state. `find_route()` returns an enabled breadth-first route as zone IDs or no route when an endpoint is unknown/disconnected. A disabled link immediately stops participating in route selection; this makes future blocked-bridge/lift/rappel state testing deterministic without changing world geometry.

## M4 integration sequence

After the authoritative B2 packet passes `tools/validate_highrise_manifest.py`:

1. build graybox collision and navigation strictly from the staged coordinate/frame data;
2. create the Godot navigation/traversal adapter from the **actual** validated endpoints;
3. register only those actual zones and links in `RouteTopology`;
4. add map-specific tests for every approved route, one-way condition, disabled-link fallback, spawn-to-objective path, and floor transition; and
5. compare the tests with navigation/capture evidence before Gate 2.

No endpoint pair or route is prefilled here because the authoritative B2 coordinates/top-down reference are still absent. The unit test uses neutral `alpha`/`bravo`/`charlie`/`delta` identifiers solely to verify generic graph behavior; it is not a map design substitute.

## Verification

Run:

```bash
./scripts/run_native_tests.sh
```

The route suite verifies duplicate/dangling/self-link rejection, directional traversal, link enable/disable behavior, fallback routing, unknown endpoints, and the zero-length same-zone route. It runs beside the existing three-wave `OperationCore` regression test.
