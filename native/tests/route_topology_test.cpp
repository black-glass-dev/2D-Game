#include "route_topology.hpp"

#include <cassert>
#include <iostream>
#include <string>
#include <utility>
#include <vector>

using redline::RouteTopology;
using redline::TopologyLink;
using redline::TraversalKind;

namespace {

TopologyLink make_link(std::string id, std::string from, std::string to, TraversalKind kind,
                       bool bidirectional = true, bool enabled = true) {
  return TopologyLink{
      .id = std::move(id),
      .from_zone = std::move(from),
      .to_zone = std::move(to),
      .kind = kind,
      .bidirectional = bidirectional,
      .enabled = enabled,
  };
}

}  // namespace

int main() {
  RouteTopology topology;
  assert(!topology.add_zone(""));
  assert(topology.add_zone("alpha"));
  assert(topology.add_zone("bravo"));
  assert(topology.add_zone("charlie"));
  assert(topology.add_zone("delta"));
  assert(!topology.add_zone("alpha"));
  assert(topology.zone_count() == 4);
  assert(topology.has_zone("bravo"));
  assert(!topology.has_zone("unknown"));

  assert(!topology.add_link(make_link("missing-endpoint", "alpha", "unknown", TraversalKind::kWalk)));
  assert(!topology.add_link(make_link("self-link", "alpha", "alpha", TraversalKind::kWalk)));
  assert(topology.add_link(make_link("walk-alpha-bravo", "alpha", "bravo", TraversalKind::kWalk)));
  assert(topology.add_link(make_link("bridge-bravo-charlie", "bravo", "charlie",
                                     TraversalKind::kBridge)));
  assert(topology.add_link(make_link("zipline-charlie-delta", "charlie", "delta",
                                     TraversalKind::kZipline, false)));
  assert(topology.add_link(make_link("rappel-bravo-delta", "bravo", "delta",
                                     TraversalKind::kRappel, true, false)));
  assert(!topology.add_link(make_link("walk-alpha-bravo", "alpha", "bravo", TraversalKind::kWalk)));
  assert(topology.link_count() == 4);
  assert(topology.has_link("bridge-bravo-charlie"));
  assert(!topology.has_link("unknown-link"));

  const auto initial_route = topology.find_route("alpha", "delta");
  assert(initial_route.has_value());
  assert((*initial_route == std::vector<std::string>{"alpha", "bravo", "charlie", "delta"}));
  assert(!topology.find_route("delta", "alpha").has_value());  // Zipline is one-way.
  assert((topology.find_route("alpha", "alpha") == std::vector<std::string>{"alpha"}));
  assert(!topology.find_route("alpha", "unknown").has_value());

  assert(topology.set_link_enabled("bridge-bravo-charlie", false));
  assert(!topology.find_route("alpha", "delta").has_value());
  assert(topology.set_link_enabled("rappel-bravo-delta", true));
  const auto fallback_route = topology.find_route("alpha", "delta");
  assert(fallback_route.has_value());
  assert((*fallback_route == std::vector<std::string>{"alpha", "bravo", "delta"}));
  assert(!topology.set_link_enabled("unknown-link", true));

  std::cout << "RouteTopology tests passed: registration, traversal direction, disabled links, fallback.\n";
}
