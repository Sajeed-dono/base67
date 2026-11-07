/// Small deterministic Mulberry32 generator matching the bundled data spec.
/// This belongs to the pure-Dart simulation layer and imports no Flutter code.
class SeededRng {
  SeededRng(int seed) : _state = seed;

  int _state;

  double nextDouble() {
    var t = _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    t = ((t ^ (t >> 15)) * (t | 1)) & 0xFFFFFFFF;
    t ^= (t + (((t ^ (t >> 7)) * (t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    final value = (t ^ (t >> 14)) & 0xFFFFFFFF;
    return value / 4294967296;
  }
}
