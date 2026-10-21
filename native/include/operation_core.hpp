#pragma once

#include <array>

namespace redline {

/**
 * Deterministic, engine-agnostic survival pacing model.
 *
 * This is deliberately free of rendering and Android APIs. The same class can be
 * compiled for desktop tests, a Godot GDExtension, or Android NDK code without
 * changing combat pacing rules.
 */
class OperationCore {
 public:
  struct Events {
    int wave_started{0};
    int spawn_serial{0};
    int wave_cleared{0};
    bool operation_complete{false};
  };

  void start(float preparation_seconds = 1.5F);
  [[nodiscard]] Events tick(float delta_seconds);
  [[nodiscard]] Events enemy_eliminated();
  void stop();

  [[nodiscard]] int current_wave() const noexcept { return current_wave_; }
  [[nodiscard]] int alive() const noexcept { return alive_; }
  [[nodiscard]] int waiting_to_spawn() const noexcept { return waiting_to_spawn_; }
  [[nodiscard]] bool is_running() const noexcept { return running_; }
  [[nodiscard]] bool is_complete() const noexcept { return complete_; }

 private:
  static constexpr std::array<int, 3> kWaveSizes{6, 9, 12};
  static constexpr float kIntermissionSeconds = 4.0F;

  void begin_next_wave(Events& events);

  int current_wave_{0};
  int alive_{0};
  int waiting_to_spawn_{0};
  int spawn_serial_{0};
  float spawn_timer_{0.0F};
  float intermission_left_{0.0F};
  bool running_{false};
  bool complete_{false};
};

}  // namespace redline
