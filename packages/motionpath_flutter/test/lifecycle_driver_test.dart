import 'package:flutter/widgets.dart';
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

  testWidgets('ticker driver can stop and dispose repeatedly',
      (WidgetTester tester) async {
    final MotionPathEngine engine = MotionPathEngine();
    late MotionPathTickerDriver driver;
    await tester.pumpWidget(_TickerHost(onReady: (TickerProvider provider) {
      driver = MotionPathTickerDriver(engine, provider);
      driver.start();
    }));
    await tester.pump();
    expect(driver.isActive, isTrue);
    driver.stop();
    driver.stop();
    driver.dispose();
    driver.dispose();
    expect(driver.isActive, isFalse);
  });
}

class _TickerHost extends StatefulWidget {
  const _TickerHost({required this.onReady});

  final void Function(TickerProvider provider) onReady;

  @override
  State<_TickerHost> createState() => _TickerHostState();
}

class _TickerHostState extends State<_TickerHost>
    with SingleTickerProviderStateMixin {
  bool _reported = false;

  @override
  Widget build(BuildContext context) {
    if (!_reported) {
      _reported = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onReady(this);
        }
      });
    }
    return const SizedBox.shrink();
  }
}
