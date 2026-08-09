/// Tracks in-flight async loads so late responses are ignored after dispose
/// or when a newer request supersedes the current one.
mixin AsyncLoadGuard {
  int _loadGeneration = 0;

  int beginLoad() => ++_loadGeneration;

  bool isCurrentLoad(int generation) => generation == _loadGeneration;
}
