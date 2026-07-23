import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/custom/strip/layouts/default_strip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Win key is hidden for macOS peers', () {
    final labels = stripLayoutForPlatform(kPeerPlatformMacOS)
        .rows
        .first
        .left
        .map((key) => key.label);

    expect(labels, isNot(contains('Win')));
  });

  test('Win key remains available for Windows peers', () {
    final labels = stripLayoutForPlatform(kPeerPlatformWindows)
        .rows
        .first
        .left
        .map((key) => key.label);

    expect(labels, contains('Win'));
  });
}
