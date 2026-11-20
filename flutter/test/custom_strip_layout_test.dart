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

  test('row 1 puts Esc between close and shift', () {
    final labels =
        stripLayoutForPlatform(kPeerPlatformMacOS).rows.first.left.map((k) => k.label).toList();

    expect(labels.sublist(0, 3), ['✕', 'Esc', '⇧']);
  });

  test('row 2 centers the four arrows and drops moved keys', () {
    final row = stripLayoutForPlatform(kPeerPlatformMacOS).rows[1];
    final all = [...row.left, ...row.middle, ...row.right].map((k) => k.label);

    expect(row.middle.map((k) => k.label), ['←', '↓', '↑', '→']);
    expect(all, isNot(containsAny(['📎', '💬', '⏫', '⏬', '⧉'])));
  });
}
