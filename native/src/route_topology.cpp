#include "route_topology.hpp"

#include <algorithm>
#include <queue>
#include <unordered_map>
#include <utility>

namespace redline {

bool RouteTopology::add_zone(std::string zone_id) {
  if (zone_id.empty()) {
    return false;
  }
  return zones_.insert(std::move(zone_id)).second;
}

bool RouteTopology::add_link(TopologyLink link) {
  if (link.id.empty() || link.from_zone.empty() || link.to_zone.empty() ||
      link.from_zone == link.to_zone || !has_zone(link.from_zone) ||
      !has_zone(link.to_zone) || has_link(link.id)) {
    return false;
  }
  links_.push_back(std::move(link));
  return true;
}

bool RouteTopology::set_link_enabled(std::string_view link_id, bool enabled) {
  const auto link = std::find_if(links_.begin(), links_.end(), [link_id](const TopologyLink& candidate) {
    return candidate.id == link_id;
  });
  if (link == links_.end()) {
    return false;
  }
  link->enabled = enabled;
  return true;
}

bool RouteTopology::has_zone(std::string_view zone_id) const {
  return zones_.contains(std::string(zone_id));
}

bool RouteTopology::has_link(std::string_view link_id) const {
  return std::any_of(links_.begin(), links_.end(), [link_id](const TopologyLink& candidate) {
    return candidate.id == link_id;
  });
}

std::optional<std::vector<std::string>> RouteTopology::find_route(
    std::string_view from_zone, std::string_view to_zone) const {
  const std::string start(from_zone);
  const std::string destination(to_zone);
  if (!has_zone(start) || !has_zone(destination)) {
    return std::nullopt;
  }
  if (start == destination) {
    return std::vector<std::string>{start};
  }

  std::queue<std::string> frontier;
  std::unordered_map<std::string, std::string> predecessor;
  frontier.push(start);
  predecessor.emplace(start, "");

  while (!frontier.empty()) {
    const std::string current = frontier.front();
    frontier.pop();
    for (const TopologyLink& link : links_) {
      if (!link.enabled) {
        continue;
      }
      std::string next;
      if (link.from_zone == current) {
        next = link.to_zone;
      } else if (link.bidirectional && link.to_zone == current) {
        next = link.from_zone;
      } else {
        continue;
      }
      if (!predecessor.emplace(next, current).second) {
        continue;
      }
      if (next == destination) {
        std::vector<std::string> route;
        for (std::string step = destination; !step.empty(); step = predecessor.at(step)) {
          route.push_back(step);
        }
        std::reverse(route.begin(), route.end());
        return route;
      }
      frontier.push(std::move(next));
    }
  }
  return std::nullopt;
}

}  // namespace redline
