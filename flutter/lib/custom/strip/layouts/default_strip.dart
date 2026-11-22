import '../../../consts.dart';
import '../models/key_def.dart';

StripLayout stripLayoutForPlatform(String platform) {
  final altDef = switch (platform) {
    kPeerPlatformMacOS => KeyDef(label: '⌥', keyName: 'alt', type: KeyType.modifier),
    _ => KeyDef(label: 'Alt', keyName: 'alt', type: KeyType.modifier),
  };
  final shiftDef = KeyDef(label: '⇧', keyName: 'shift', type: KeyType.modifier);
  final ctrlDef = KeyDef(label: 'Ctrl', keyName: 'control', type: KeyType.modifier);
  final cmdDef = switch (platform) {
    kPeerPlatformMacOS => KeyDef(label: '⌘', keyName: 'meta', type: KeyType.modifier),
    kPeerPlatformWindows => KeyDef(label: '⊞', keyName: 'meta', type: KeyType.modifier),
    _ => KeyDef(label: 'Super', keyName: 'meta', type: KeyType.modifier),
  };

  return StripLayout(
    rows: [
      // Row 1: disconnect + ▲▼ + ⇧ + Ctrl + ⏎ + platform modifier + Win (non-macOS) + Alt (left)  |  Esc (right)
      StripRow(
        left: [
          KeyDef(label: '✕', keyName: '', type: KeyType.disconnect, widthFactor: 0.7),
          KeyDef(label: '▲▼', keyName: '', type: KeyType.stripToggle, widthFactor: 0.7),
          shiftDef,
          ctrlDef,
          KeyDef(label: '⏎', keyName: 'return', type: KeyType.regular),
          cmdDef,
          if (platform != kPeerPlatformMacOS)
            KeyDef(label: 'Win', keyName: 'win', type: KeyType.regular),
          altDef,
        ],
        right: [
          KeyDef(label: 'Esc', keyName: 'escape', type: KeyType.regular),
        ],
      ),
      // Row 2: 🖥 + Tab + ⚡ + ⌫ + ⌦ + ⎵ + ⊞ (left)  |  ⌨ + ← ↓ ↑ → (right)
      StripRow(
        left: [
          KeyDef(label: '🖥', keyName: '', type: KeyType.displaySwitch, widthFactor: 0.7, height: 48),
          KeyDef(label: 'Tab', keyName: 'tab', type: KeyType.regular, widthFactor: 1.1, height: 48),
          KeyDef(label: '⚡', keyName: '', type: KeyType.macroOpener, widthFactor: 0.9, height: 48),
          KeyDef(label: '⌫', keyName: 'backspace', type: KeyType.regular, widthFactor: 1.0, height: 48),
          KeyDef(label: '⌦', keyName: 'delete', type: KeyType.regular, widthFactor: 1.0, height: 48),
          KeyDef(label: '⎵', keyName: 'space', type: KeyType.regular, widthFactor: 1.2, height: 48),
          KeyDef(label: '⊞', keyName: '', type: KeyType.nextDisplay, widthFactor: 0.8, height: 48),
        ],
        right: [
          KeyDef(label: '⌨', keyName: '', type: KeyType.keyboardToggle, widthFactor: 0.7, height: 48),
          KeyDef(label: '←', keyName: 'left', type: KeyType.regular, widthFactor: 1.0, height: 48),
          KeyDef(label: '↓', keyName: 'down', type: KeyType.regular, widthFactor: 1.0, height: 48),
          KeyDef(label: '↑', keyName: 'up', type: KeyType.regular, widthFactor: 1.0, height: 48),
          KeyDef(label: '→', keyName: 'right', type: KeyType.regular, widthFactor: 1.0, height: 48),
        ],
      ),
    ],
  );
}
