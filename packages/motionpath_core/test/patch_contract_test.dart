import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('classifies authored, metadata, internal, and plugin keys', () {
    expect(
      MotionPathPatchContract.classify('x'),
      MotionPathPatchKeyKind.publicOutput,
    );
    expect(
      MotionPathPatchContract.classify('z'),
      MotionPathPatchKeyKind.rendererMetadata,
    );
    expect(
      MotionPathPatchContract.classify('progress'),
      MotionPathPatchKeyKind.internal,
    );
    expect(
      MotionPathPatchContract.classify(
        'blur',
        plugins: <MotionPathPlugin>[filterPlugin],
      ),
      MotionPathPatchKeyKind.pluginPayload,
    );
  });

  test('normalization strips internal keys and freezes nested values', () {
    final Map<String, Object?> patch = MotionPathPatchContract.normalize(
      <String, Object?>{
        'x': 12,
        'progress': 0.5,
        'filter': <String, Object?>{'blur': 4},
        'instances': <Object?>[
          <String, Object?>{'id': 'a'},
        ],
      },
    );
    expect(patch.keys, containsAll(<String>['x', 'filter', 'instances']));
    expect(patch.containsKey('progress'), isFalse);
    expect(() => patch['x'] = 20, throwsUnsupportedError);
    expect(
      () => (patch['filter']! as Map<String, Object?>)['blur'] = 8,
      throwsUnsupportedError,
    );
    expect(
      () => (patch['instances']! as List<Object?>).clear(),
      throwsUnsupportedError,
    );
  });

  test('all supported plugin outputs normalize through the same boundary', () {
    final List<MotionPathPlugin> plugins = <MotionPathPlugin>[
      pathPlugin,
      imageSequencePlugin,
      cssVariablePlugin,
      filterPlugin,
      scenePlugin,
    ];
    for (final MotionPathPlugin plugin in plugins) {
      final Map<String, Object?> patch = MotionPathPatchContract.normalize(
        <String, Object?>{
          for (final String key in plugin.outputs) key: <String, Object?>{'value': 1},
          for (final String key in plugin.internalKeys) key: 1,
        },
        plugins: <MotionPathPlugin>[plugin],
      );
      for (final String key in plugin.internalKeys) {
        expect(patch.containsKey(key), isFalse, reason: '${plugin.name}: $key');
      }
    }
  });
}
