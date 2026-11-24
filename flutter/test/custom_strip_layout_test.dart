import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/custom/strip/layouts/default_strip.dart';
import 'package:flutter_hbb/custom/strip/models/key_def.dart';
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

  test('row 1 puts Tab left of Ctrl and Esc left of the keyboard toggle', () {
    final row = stripLayoutForPlatform(kPeerPlatformMacOS).rows.first;
    final left = row.left.map((k) => k.label).toList();

    expect(left.take(3), ['✕', '▲▼', '⇧']);
    expect(left[left.indexOf('Ctrl') - 1], 'Tab');
    expect(row.right.map((k) => k.label), ['Y', 'Esc', '⌨']);
    expect(row.right.first.type, KeyType.typeString);
    expect(row.right.first.keyString, 'yes');
    expect(row.right.first.sendEnter, isTrue);
    expect(row.right.map((k) => k.label), isNot(contains('⇧')));
  });

  test('row 2 keeps editing keys and arrows and drops the strip macros button', () {
    final row = stripLayoutForPlatform(kPeerPlatformMacOS).rows[1];
    final all = [...row.left, ...row.middle, ...row.right].map((k) => k.label);

    expect(row.left.map((k) => k.label), ['🖥', '⌫', '⌦', '⎵', '⊞']);
    expect(row.middle, isEmpty);
    expect(row.right.map((k) => k.label), ['←', '↓', '↑', '→']);
    expect(all.where(['⚡', 'Tab', '⌨', '📎', '💬', '⏫', '⏬', '⧉'].contains), isEmpty);
  });
}
