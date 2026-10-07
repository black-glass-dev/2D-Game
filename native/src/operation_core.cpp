#include "operation_core.hpp"

#include <algorithm>

namespace redline {

void OperationCore::start(float preparation_seconds) {
  current_wave_ = 0;
  alive_ = 0;
  waiting_to_spawn_ = 0;
  spawn_serial_ = 0;
  spawn_timer_ = 0.0F;
  intermission_left_ = std::max(0.0F, preparation_seconds);
  running_ = true;
  complete_ = false;
}

OperationCore::Events OperationCore::tick(float delta_seconds) {
  Events events;
  if (!running_ || complete_) {
    return events;
  }

  const float delta = std::max(0.0F, delta_seconds);
  if (intermission_left_ > 0.0F) {
    intermission_left_ -= delta;
    if (intermission_left_ <= 0.0F) {
      begin_next_wave(events);
    }
    return events;
  }

  if (waiting_to_spawn_ > 0) {
    spawn_timer_ -= delta;
    if (spawn_timer_ <= 0.0F) {
      --waiting_to_spawn_;
      ++alive_;
      events.spawn_serial = ++spawn_serial_;
      // Later waves are denser, but never spawn more often than twice per second.
      spawn_timer_ = std::max(0.48F, 0.95F - static_cast<float>(current_wave_) * 0.12F);
    }
  }
  return events;
}

OperationCore::Events OperationCore::enemy_eliminated() {
  Events events;
  if (!running_ || alive_ <= 0) {
    return events;
  }

  --alive_;
  if (alive_ != 0 || waiting_to_spawn_ != 0) {
    return events;
  }

  events.wave_cleared = current_wave_;
  if (current_wave_ >= static_cast<int>(kWaveSizes.size())) {
    complete_ = true;
    running_ = false;
    events.operation_complete = true;
    return events;
  }
  intermission_left_ = kIntermissionSeconds;
  return events;
}

void OperationCore::stop() {
  running_ = false;
}

void OperationCore::begin_next_wave(Events& events) {
  ++current_wave_;
  waiting_to_spawn_ = kWaveSizes.at(static_cast<std::size_t>(current_wave_ - 1));
  spawn_timer_ = 0.1F;
  events.wave_started = current_wave_;
}

}  // namespace redline
