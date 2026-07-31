import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('rejects duplicate plugin names', () {
    final MotionPathPlugin plugin = MotionPathPlugin(
      name: 'custom',
      compose: (Map<String, Object?> raw) => raw,
    );
    final MotionPathPluginRegistry registry = MotionPathPluginRegistry(
      plugins: <MotionPathPlugin>[plugin],
    );
    expect(() => registry.register(plugin), throwsStateError);
  });

  test('rejects empty plugin names', () {
    expect(
      () => MotionPathPluginRegistry(
        plugins: <MotionPathPlugin>[
          MotionPathPlugin(
            name: ' ',
            compose: (Map<String, Object?> raw) => raw,
          ),
        ],
      ),
      throwsStateError,
    );
  });

  test('rejects duplicate plugin outputs', () {
    expect(
      () => assertPluginContract(
        MotionPathPlugin(
          name: 'bad',
          outputs: const <String>['x', 'x'],
          compose: (Map<String, Object?> raw) => raw,
        ),
      ),
      throwsStateError,
    );
  });
}
