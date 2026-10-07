#include "operation_core.hpp"

#include <cassert>
#include <iostream>

using redline::OperationCore;

namespace {

OperationCore::Events start_next_wave(OperationCore& core) {
  return core.tick(1.5F);
}

OperationCore::Events clear_current_wave(OperationCore& core) {
  OperationCore::Events final_event;
  int guard = 0;
  while (core.waiting_to_spawn() > 0 || core.alive() > 0) {
    assert(++guard < 1000);
    const auto tick_event = core.tick(1.0F);
    if (tick_event.spawn_serial != 0) {
      final_event = core.enemy_eliminated();
    }
  }
  return final_event;
}

}  // namespace

int main() {
  OperationCore core;
  core.start();
  assert(core.is_running());
  assert(core.current_wave() == 0);
  assert(core.enemy_eliminated().wave_cleared == 0);  // Cannot underflow alive count.

  auto event = start_next_wave(core);
  assert(event.wave_started == 1);
  assert(core.waiting_to_spawn() == 6);
  event = clear_current_wave(core);
  assert(event.wave_cleared == 1);
  assert(!event.operation_complete);
  assert(core.current_wave() == 1);
  assert(core.alive() == 0);

  event = core.tick(4.0F);
  assert(event.wave_started == 2);
  assert(core.waiting_to_spawn() == 9);
  event = clear_current_wave(core);
  assert(event.wave_cleared == 2);

  event = core.tick(4.0F);
  assert(event.wave_started == 3);
  assert(core.waiting_to_spawn() == 12);
  event = clear_current_wave(core);
  assert(event.wave_cleared == 3);
  assert(event.operation_complete);
  assert(core.is_complete());
  assert(!core.is_running());

  // A stopped or completed game must be inert.
  assert(core.tick(20.0F).spawn_serial == 0);
  core.stop();
  assert(!core.is_running());

  std::cout << "OperationCore tests passed: 3 waves, 27 spawns, completion state.\n";
}
