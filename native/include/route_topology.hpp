#pragma once

#include <cstddef>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_set>
#include <vector>

namespace redline {

/**
 * Navigation-independent link types that a later map adapter can map to Godot
 * NavigationLink3D and traversal systems. They carry no world coordinates.
 */
enum class TraversalKind {
  kWalk,
  kBridge,
  kRappel,
  kLiftShaft,
  kZipline,
};

struct TopologyLink {
  std::string id;
  std::string from_zone;
  std::string to_zone;
  TraversalKind kind{TraversalKind::kWalk};
  bool bidirectional{true};
  bool enabled{true};
};

/**
 * A deterministic, engine-agnostic graph for validating map traversal topology.
 *
 * This class deliberately has no Vector3, collision, scene, or coordinate data.
 * M4 can therefore prepare and test route connectivity before the authoritative
 * Highrise coordinate packet is available. A later Godot adapter must populate
 * it only from validated graybox/navigation data.
 */
class RouteTopology {
 public:
  [[nodiscard]] bool add_zone(std::string zone_id);
  [[nodiscard]] bool add_link(TopologyLink link);
  [[nodiscard]] bool set_link_enabled(std::string_view link_id, bool enabled);

  [[nodiscard]] bool has_zone(std::string_view zone_id) const;
  [[nodiscard]] bool has_link(std::string_view link_id) const;
  [[nodiscard]] std::size_t zone_count() const noexcept { return zones_.size(); }
  [[nodiscard]] std::size_t link_count() const noexcept { return links_.size(); }

  /**
   * Return an enabled traversal route as zone IDs, including both endpoints.
   * `std::nullopt` means either endpoint is unknown or no enabled route exists.
   */
  [[nodiscard]] std::optional<std::vector<std::string>> find_route(
      std::string_view from_zone, std::string_view to_zone) const;

 private:
  std::unordered_set<std::string> zones_;
  std::vector<TopologyLink> links_;
};

}  // namespace redline
