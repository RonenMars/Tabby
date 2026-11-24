import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:get/get.dart';

import '../../input/input_bridge.dart';
import '../../theme/tokens.dart';
import '../layouts/default_strip.dart';
import '../models/key_def.dart';
import '../models/modifier_state.dart';
import 'key_cell.dart';

class PowerStrip extends StatefulWidget {
  final InputBridge inputBridge;
  final ModifierController modifierController;
  final VoidCallback onMacrosTap;
  final VoidCallback onKeyboardTap;
  final VoidCallback onDisconnect;
  final VoidCallback onChatToggle;
  final VoidCallback onDisplaySwitch;
  final VoidCallback onZoomFit;
  final VoidCallback onMouseModeToggle;
  final VoidCallback onClipboardPaste;
  final VoidCallback onNextDisplay;
  final VoidCallback onPrevDisplay;
  final VoidCallback onFileSend;
  final bool leftHanded;
  final FFI ffi;
  final VoidCallback? onSessionsTap;
  final ValueChanged<bool>? onCollapsedChanged;

  const PowerStrip({
    super.key,
    required this.inputBridge,
    required this.modifierController,
    required this.onMacrosTap,
    required this.onKeyboardTap,
    required this.onDisconnect,
    required this.onChatToggle,
    required this.onDisplaySwitch,
    required this.onZoomFit,
    required this.onMouseModeToggle,
    required this.onClipboardPaste,
    required this.onNextDisplay,
    required this.onPrevDisplay,
    required this.onFileSend,
    required this.ffi,
    this.onSessionsTap,
    this.onCollapsedChanged,
    this.leftHanded = false,
  });

  @override
  State<PowerStrip> createState() => _PowerStripState();
}

class _PowerStripState extends State<PowerStrip> {
  bool _collapsed = false;
  final Map<String, LayerLink> _cellLinks = {};
  OverlayEntry? _cmdPopup;
  String? _cmdPopupModifier;
  Timer? _popupTimer;

  static const double _popupW = 44.0;
  static const double _popupH = 36.0;
  static const double _popupGap = 6.0;
  static const double _popupAnchorGap = 6.0;

  @override
  void initState() {
    super.initState();
    widget.modifierController.addListener(_onModifierChanged);
  }

  @override
  void dispose() {
    widget.modifierController.removeListener(_onModifierChanged);
    _dismissCmdPopup();
    super.dispose();
  }

  void _onModifierChanged() {
    final mod = _cmdPopupModifier;
    if (_cmdPopup != null &&
        mod != null &&
        widget.modifierController.modeFor(mod) == ModifierMode.off) {
      _dismissCmdPopup();
    }
  }

  LayerLink _cellLink(String keyName) =>
      _cellLinks.putIfAbsent(keyName, LayerLink.new);

  void _dismissCmdPopup() {
    _popupTimer?.cancel();
    _cmdPopup?.remove();
    _cmdPopup = null;
    _cmdPopupModifier = null;
  }

  List<(String, String, Set<String>)> _popupLabelsFor(String modifier) {
    // (display label, key name, modifiers to send with the tap)
    switch (modifier) {
      case 'meta':
        return const [
          ('C', 'c', {'meta'}),
          ('V', 'v', {'meta'}),
          ('⇥', 'tab', {'meta'}),
          ('W', 'w', {'meta'}),
          ('X', 'x', {'meta'}),
          ('N', 'n', {'meta'}),
          ('⇧V', 'v', {'meta', 'shift'}),
          ('⎵', 'space', {'meta'}),
        ];
      case 'control':
        return const [
          ('◀', 'left', {'control'}),
          ('V', 'v', {'control'}),
          ('▶', 'right', {'control'}),
          ('S', 's', {'control'}),
          ('Q', 'q', {'control'}),
          ('C', 'c', {'control'}),
          ('X', 'x', {'control'}),
        ];
      case 'alt':
        return const [
          ('⏎', 'return', {'alt'}),
        ];
    }
    return const [];
  }

  void _showCmdPopup(KeyDef k) {
    final modifier = k.keyName;
    _showPopup(modifier, perRow: modifier == 'control' ? 4 : null, [
      for (final l in _popupLabelsFor(modifier))
        (
          l.$1,
          () {
            widget.inputBridge.tapKey(l.$2, modifiers: l.$3);
            while (widget.modifierController.modeFor(modifier) !=
                ModifierMode.off) {
              widget.modifierController.cycleTap(modifier);
            }
            _dismissCmdPopup();
          }
        ),
    ]);
    _cmdPopupModifier = modifier;
  }

  // Double-tap on ⊞: ◀ / ▶ for the previous or next remote display.
  // A single tap steps to the next display directly.
  void _toggleDisplayPopup() {
    if (_cmdPopup != null) {
      _dismissCmdPopup();
      return;
    }
    _showPopup('display', [
      ('◀', () { _dismissCmdPopup(); widget.onPrevDisplay(); }),
      ('▶', () { _dismissCmdPopup(); widget.onNextDisplay(); }),
    ]);
    _popupTimer = Timer(const Duration(seconds: 4), _dismissCmdPopup);
  }

  // `perRow` wraps the buttons onto several centered lines (default: one line).
  void _showPopup(String linkKey, List<(String, VoidCallback)> items,
      {int? perRow}) {
    _dismissCmdPopup();
    final link = _cellLink(linkKey);
    final cols = perRow ?? items.length;
    final rows = (items.length / cols).ceil();
    final totalW = _popupW * cols + _popupGap * (cols - 1);
    final totalH = _popupH * rows + _popupGap * (rows - 1);

    _cmdPopup = OverlayEntry(
      builder: (ctx) {
        final shift = _horizontalShiftFor(ctx, link, totalW);
        return Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            // Anchor the popup's bottom-center to the cell's top-center,
            // then lift by `_popupAnchorGap` for breathing room. Using the
            // follower means the popup tracks the cell across collapse/
            // expand and keyboard show/hide without recomputing positions.
            // `shift` nudges horizontally so wide popups (e.g. 7-button Ctrl)
            // stay inside the screen even when the cell is near an edge.
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            offset: Offset(shift, -_popupAnchorGap),
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: totalW,
                height: totalH,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var r = 0; r < rows; r++) ...[
                      if (r > 0) const SizedBox(height: _popupGap),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = r * cols;
                              i < (r + 1) * cols && i < items.length;
                              i++) ...[
                            if (i > r * cols) const SizedBox(width: _popupGap),
                            _cmdPopupButton(
                              items[i].$1,
                              items[i].$2,
                              _popupW,
                              _popupH,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_cmdPopup!);
  }

  // Returns a horizontal offset (in cell-local coordinates) that shifts a
  // popup of width `totalW` so it stays inside the screen. Returns 0 when
  // the centered placement already fits or the cell's RenderBox hasn't
  // laid out yet. We look up the cell via the LayerLink target's context
  // — `leaderSize` is set by the LeaderLayer but `LeaderLayer.offset` is
  // parent-relative, not global, so we resolve the global position
  // through the target widget's RenderBox below.
  double _horizontalShiftFor(
      BuildContext ctx, LayerLink link, double totalW) {
    final cellSize = link.leaderSize;
    final targetCtx = _targetContextFor(link);
    if (cellSize == null || targetCtx == null) return 0;
    final box = targetCtx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return 0;
    final cellGlobalLeft = box.localToGlobal(Offset.zero).dx;
    final mq = MediaQuery.of(ctx);
    final screenW = mq.size.width;
    final safeL = mq.viewPadding.left;
    final safeR = mq.viewPadding.right;

    final popupLeft = cellGlobalLeft + cellSize.width / 2 - totalW / 2;
    final popupRight = popupLeft + totalW;

    double shift = 0;
    if (popupLeft < safeL) {
      shift = safeL - popupLeft;
    } else if (popupRight > screenW - safeR) {
      shift = (screenW - safeR) - popupRight;
    }
    return shift;
  }

  // Tracks the BuildContext of each CompositedTransformTarget so the
  // overflow-shift helper can resolve its RenderBox for global coords.
  final Map<LayerLink, BuildContext> _targetCtxByLink = {};
  BuildContext? _targetContextFor(LayerLink link) => _targetCtxByLink[link];

  Widget _cmdPopupButton(
      String label, VoidCallback onTap, double w, double h) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: AppTokens.colorPrimary,
          borderRadius: BorderRadius.circular(AppTokens.radiusKey),
          boxShadow: const [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black38,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style:
              AppTokens.fontKey.copyWith(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ffi.ffiModel,
      builder: (context, _) => _buildStrip(widget.ffi.ffiModel.pi.platform),
    );
  }

  Widget _buildStrip(String platform) {
    final layout = widget.leftHanded
        ? stripLayoutForPlatform(platform).mirrored()
        : stripLayoutForPlatform(platform);

    // When collapsed only the first row (row 0) is shown so the user can
    // still reach the stripToggle key to expand again.
    final visibleRows = _collapsed ? layout.rows.take(1).toList() : layout.rows;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceSm,
        vertical: AppTokens.spaceXs,
      ),
      decoration: const BoxDecoration(
        color: AppTokens.colorBgSurface,
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black26,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: visibleRows.map((row) {
          return Padding(
            // Row with a centered arrow cluster gets extra room above it.
            padding: EdgeInsets.only(top: row.middle.isEmpty ? 2 : 8, bottom: 2),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double leftW = _clusterWidth(row.left);
                double middleW = _clusterWidth(row.middle);
                double rightW = _clusterWidth(row.right);
                double totalW = leftW + middleW + rightW + (row.middle.isEmpty ? 0 : 16);
                double available = constraints.maxWidth;
                double scale = totalW > available ? available / totalW : 1.0;
                // Equal spacers keep the gap before the arrow cluster the same
                // size as the gap after it. Equal Expanded slots do not: the
                // left cluster is wider, so it overflowed into the arrows.
                return Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _clusterKeys(row.left, scale),
                    ),
                    const Spacer(),
                    ..._clusterKeys(row.middle, scale),
                    if (row.middle.isNotEmpty) const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _clusterKeys(row.right, scale),
                    ),
                  ],
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // Extra space between Esc and the keyboard toggle, on top of the
  // usual key padding. The pair stays together when the strip is mirrored.
  static const _kEscKeyboardGap = 12.0;

  bool _escBesideKeyboard(KeyDef a, KeyDef b) {
    final escThenKeyboard =
        a.keyName == 'escape' && b.type == KeyType.keyboardToggle;
    final keyboardThenEsc =
        a.type == KeyType.keyboardToggle && b.keyName == 'escape';
    return escThenKeyboard || keyboardThenEsc;
  }

  double _clusterWidth(List<KeyDef> keys) {
    var width = 0.0;
    for (var i = 0; i < keys.length; i++) {
      width += kKeyBaseWidth * keys[i].widthFactor + 4;
      if (i > 0 && _escBesideKeyboard(keys[i - 1], keys[i])) {
        width += _kEscKeyboardGap;
      }
    }
    return width;
  }

  List<Widget> _clusterKeys(List<KeyDef> keys, double scale) {
    final children = <Widget>[];
    for (var i = 0; i < keys.length; i++) {
      if (i > 0 && _escBesideKeyboard(keys[i - 1], keys[i])) {
        children.add(SizedBox(width: _kEscKeyboardGap * scale));
      }
      children.add(_wrapScaled(keys[i], scale));
    }
    return children;
  }

  Widget _wrapScaled(KeyDef k, double scale) {
    if (k.type == KeyType.displaySwitch || k.type == KeyType.nextDisplay) {
      return Obx(() {
        if (widget.ffi.ffiModel.pi.displays.length <= 1) return const SizedBox.shrink();
        return _keyCell(k, scale);
      });
    }
    if (k.type == KeyType.sessionSwitch) {
      if (widget.onSessionsTap == null) return const SizedBox.shrink();
    }
    return _keyCell(k, scale);
  }

  Widget _keyCell(KeyDef k, double scale) {
    final scaled = scale < 1.0 ? k.copyWith(widthFactor: k.widthFactor * scale) : k;
    final cell = KeyCell(
      keyDef: scaled,
      modifierController: widget.modifierController,
      onTap: () => _handle(k),
      onDoubleTap: k.type == KeyType.nextDisplay
          ? () {
              HapticFeedback.lightImpact();
              _toggleDisplayPopup();
            }
          : null,
      onPressStart: k.type == KeyType.regular
          ? () => _onRegularPressStart(k)
          : null,
      onPressEnd: k.type == KeyType.regular
          ? () => _onRegularPressEnd(k)
          : null,
    );
    final hasPopup = k.type == KeyType.modifier &&
        (k.keyName == 'meta' || k.keyName == 'control' || k.keyName == 'alt');
    if (hasPopup || k.type == KeyType.nextDisplay) {
      final link = _cellLink(hasPopup ? k.keyName : 'display');
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 2 * scale),
        child: CompositedTransformTarget(
          link: link,
          child: Builder(builder: (ctx) {
            _targetCtxByLink[link] = ctx;
            return cell;
          }),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2 * scale),
      child: cell,
    );
  }

  void _handle(KeyDef k) {
    HapticFeedback.lightImpact();
    switch (k.type) {
      case KeyType.modifier:
        widget.modifierController.cycleTap(k.keyName);
        if ((k.keyName == 'meta' || k.keyName == 'control' || k.keyName == 'alt') &&
            widget.modifierController.modeFor(k.keyName) != ModifierMode.off) {
          _showCmdPopup(k);
        }
      case KeyType.macroOpener:
        widget.onMacrosTap();
      case KeyType.keyboardToggle:
        widget.onKeyboardTap();
      case KeyType.stripToggle:
        setState(() => _collapsed = !_collapsed);
        // SizeChangedLayoutNotifier alone is unreliable for this toggle
        // (framework warns it races with the layout pipeline). Tell the
        // parent directly so it can recompute canvasBottom.
        widget.onCollapsedChanged?.call(_collapsed);
      case KeyType.disconnect:
        widget.onDisconnect();
      case KeyType.chatToggle:
        widget.onChatToggle();
      case KeyType.displaySwitch:
        widget.onDisplaySwitch();
      case KeyType.zoomFit:
        widget.onZoomFit();
      case KeyType.mouseModeToggle:
        widget.onMouseModeToggle();
      case KeyType.clipboardPaste:
        widget.onClipboardPaste();
      case KeyType.nextDisplay:
        _dismissCmdPopup();
        widget.onNextDisplay();
      case KeyType.fileSend:
        widget.onFileSend();
      case KeyType.arrowCross:
        // arrowCross removed — individual arrow keys added directly to strip
        break;
      case KeyType.typeString:
        unawaited(_sendTypeString(k));
      case KeyType.sessionSwitch:
        widget.onSessionsTap?.call();
      case KeyType.regular:
        // Regular keys go through onPressStart / onPressEnd in KeyCell so the
        // held modifier (if any) stays down until the in-flight tap finishes.
        break;
      case KeyType.layer:
        // Fn layer not implemented in v1 — use macros instead
        break;
    }
  }

  // Enter has to follow the typed text, so the string future is awaited
  // before the return key goes out.
  Future<void> _sendTypeString(KeyDef k) async {
    final text = k.keyString;
    if (text == null) return;
    await widget.inputBridge.typeString(text);
    if (k.sendEnter) await widget.inputBridge.tapKey('return');
  }

  // Haptic fires once on touch-down inside _RepeatingKeyButton (not here),
  // so repeat ticks don't buzz on every fire. Held modifiers are passed
  // as flags on the KeyEvent — see ModifierController doc for the why.
  Future<void> _onRegularPressStart(KeyDef k) => widget.inputBridge.tapKey(
        k.keyName,
        modifiers: widget.modifierController.heldModifiers,
      );

  void _onRegularPressEnd(KeyDef k) {
    widget.modifierController.releaseOneShot();
  }
}
