/// Small deterministic Mulberry32 generator matching the bundled data spec.
/// This belongs to the pure-Dart simulation layer and imports no Flutter code.
class SeededRng {
  SeededRng(int seed) : _state = seed & 0xFFFFFFFF;

  int _state;
  int get state => _state;

  // Sixteen-bit limbs keep multiplication exact on native and browser Dart.
  static int _multiply32(int a, int b) =>
      ((a & 0xFFFF) * (b & 0xFFFF) +
          ((((a >> 16) * (b & 0xFFFF) + (b >> 16) * (a & 0xFFFF)) & 0xFFFF) <<
              16)) &
      0xFFFFFFFF;

  double nextDouble() {
    var t = _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    t = _multiply32(t ^ (t >> 15), t | 1);
    t ^= (t + _multiply32(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF;
    final value = (t ^ (t >> 14)) & 0xFFFFFFFF;
    return value / 4294967296;
  }
}
