import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('scroll driver detach and dispose are idempotent', () {
    final List<double> seen = <double>[];
    final MotionPathScrollDriver driver = MotionPathScrollDriver(
      binding: const MotionPathScrollBinding(end: 100),
      onProgress: seen.add,
    );
    driver.detach();
    driver.dispose();
    driver.dispose();
    expect(driver.controller, isNull);
    expect(seen, isEmpty);
  });

  testWidgets('ticker driver can stop and dispose repeatedly', (WidgetTester tester) async {
    final MotionPathEngine engine = MotionPathEngine();
    late MotionPathTickerDriver driver;
    await tester.pumpWidget(_TickerHost(onReady: (MotionPathTickerProvider provider) {
      driver = MotionPathTickerDriver(engine, provider);
      driver.start();
    }));
    expect(driver.isActive, isTrue);
    driver.stop();
    driver.stop();
    driver.dispose();
    driver.dispose();
    expect(driver.isActive, isFalse);
  });
}

class MotionPathTickerProvider extends StatefulWidget {
  const MotionPathTickerProvider({required this.child, super.key});
  final Widget child;
  @override
  State<MotionPathTickerProvider> createState() => _MotionPathTickerProviderState();
}

class _MotionPathTickerProviderState extends State<MotionPathTickerProvider>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) => widget.child;
}

class _TickerHost extends StatelessWidget {
  const _TickerHost({required this.onReady});
  final void Function(MotionPathTickerProvider provider) onReady;
  @override
  Widget build(BuildContext context) {
    final MotionPathTickerProvider provider = MotionPathTickerProvider(
      child: Builder(builder: (BuildContext context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onReady(context.findAncestorStateOfType<_MotionPathTickerProviderState>()!.widget);
        });
        return const SizedBox.shrink();
      }),
    );
    return provider;
  }
}
