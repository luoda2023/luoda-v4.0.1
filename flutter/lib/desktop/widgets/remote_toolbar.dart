import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luoda_flutter/common/widgets/audio_input.dart';
import 'package:luoda_flutter/common/widgets/dialog.dart';
import 'package:luoda_flutter/common/widgets/toolbar.dart';
import 'package:luoda_flutter/models/chat_model.dart';
import 'package:luoda_flutter/models/state_model.dart';
import 'package:luoda_flutter/consts.dart';
import 'package:luoda_flutter/utils/multi_window_manager.dart';
import 'package:luoda_flutter/plugin/widgets/desc_ui.dart';
import 'package:luoda_flutter/plugin/common.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_size/window_size.dart' as window_size;

import '../../common.dart';
import '../../models/model.dart';
import '../../models/platform_model.dart';
import '../../common/shared_state.dart';
import './popup_menu.dart';
import './kb_layout_type_chooser.dart';
import 'package:luoda_flutter/utils/scale.dart';
import 'package:luoda_flutter/common/widgets/custom_scale_base.dart';


part 'remote_toolbar_theme.dart';
part 'remote_toolbar_menus.dart';

class RemoteToolbar extends StatefulWidget {
  final String id;
  final FFI ffi;
  final ToolbarState state;
  final Function(int, Function(bool)) onEnterOrLeaveImageSetter;
  final Function(int) onEnterOrLeaveImageCleaner;
  final Function(VoidCallback) setRemoteState;

  RemoteToolbar({
    Key? key,
    required this.id,
    required this.ffi,
    required this.state,
    required this.onEnterOrLeaveImageSetter,
    required this.onEnterOrLeaveImageCleaner,
    required this.setRemoteState,
  }) : super(key: key);

  @override
  State<RemoteToolbar> createState() => _RemoteToolbarState();
}

class _RemoteToolbarState extends State<RemoteToolbar> {
  late Debouncer<int> _debouncerHide;
  bool _isCursorOverImage = false;
  final _fractionX = 0.5.obs;
  final _dragging = false.obs;

  int get windowId => stateGlobal.windowId;

  void _setFullscreen(bool v) {
    stateGlobal.setFullscreen(v);
    // stateGlobal.fullscreen is RxBool now, no need to call setState.
    // setState(() {});
  }

  RxBool get collapse => widget.state.collapse;
  RxBool get hide => widget.state.hide;
  bool get pin => widget.state.pin;

  PeerInfo get pi => widget.ffi.ffiModel.pi;
  FfiModel get ffiModel => widget.ffi.ffiModel;

  triggerAutoHide() => _debouncerHide.value = _debouncerHide.value + 1;

  void _minimize() async =>
      await WindowController.fromWindowId(windowId).minimize();

  @override
  initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _fractionX.value = double.tryParse(await bind.sessionGetOption(
                  sessionId: widget.ffi.sessionId,
                  arg: 'remote-menubar-drag-x') ??
              '0.5') ??
          0.5;
      // Initialize toolbar states (collapse, hide) from session options
      widget.state.init(widget.ffi.sessionId);
    });

    _debouncerHide = Debouncer<int>(
      Duration(milliseconds: 5000),
      onChanged: _debouncerHideProc,
      initialValue: 0,
    );

    widget.onEnterOrLeaveImageSetter(identityHashCode(this), (enter) {
      if (enter) {
        triggerAutoHide();
        _isCursorOverImage = true;
      } else {
        _isCursorOverImage = false;
      }
    });
  }

  _debouncerHideProc(int v) {
    if (!pin && collapse.isFalse && _isCursorOverImage && _dragging.isFalse) {
      collapse.value = true;
    }
  }

  @override
  dispose() {
    super.dispose();

    widget.onEnterOrLeaveImageCleaner(identityHashCode(this));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Wait for initialization to complete to prevent flickering
      if (!widget.state.initialized.value) {
        return const SizedBox.shrink();
      }
      // If toolbar is hidden, return empty widget
      if (hide.value) {
        return const SizedBox.shrink();
      }
      return Align(
        alignment: Alignment.topCenter,
        child: collapse.isFalse
            ? _buildToolbar(context)
            : _buildDraggableCollapse(context),
      );
    });
  }

  Widget _buildDraggableCollapse(BuildContext context) {
    return Obx(() {
      if (collapse.isFalse && _dragging.isFalse) {
        triggerAutoHide();
      }
      final borderRadius = BorderRadius.vertical(
        bottom: Radius.circular(5),
      );
      return Align(
        alignment: FractionalOffset(_fractionX.value, 0),
        child: Offstage(
          offstage: _dragging.isTrue,
          child: Material(
            elevation: _ToolbarTheme.elevation,
            shadowColor: MyTheme.color(context).shadow,
            borderRadius: borderRadius,
            child: _DraggableShowHide(
              id: widget.id,
              sessionId: widget.ffi.sessionId,
              dragging: _dragging,
              fractionX: _fractionX,
              toolbarState: widget.state,
              setFullscreen: _setFullscreen,
              setMinimize: _minimize,
              borderRadius: borderRadius,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildToolbar(BuildContext context) {
    // Left group: primary remote-control functions (matches the reference layout).
    final List<Widget> leftItems = [];
    leftItems
        .add(_ControlMenu(id: widget.id, ffi: widget.ffi, state: widget.state));
    leftItems.add(_TerminalMenu(id: widget.id, ffi: widget.ffi));
    leftItems.add(_FileMenu(id: widget.id, ffi: widget.ffi));
    leftItems.add(_ClipboardMenu(id: widget.id, ffi: widget.ffi));
    // Do not show keyboard for camera connection type.
    if (widget.ffi.connType == ConnType.defaultConn) {
      leftItems.add(_KeyboardMenu(id: widget.id, ffi: widget.ffi));
    }
    leftItems.add(_ScreenshotButton(id: widget.id, ffi: widget.ffi));
    leftItems.add(_SystemMenu(id: widget.id, ffi: widget.ffi));
    if (!isWebDesktop) {
      leftItems.add(_MobileActionMenu(ffi: widget.ffi));
    }
    leftItems.add(Obx(() {
      if (PrivacyModeState.find(widget.id).isEmpty &&
          pi.displaysCount.value > 1) {
        return _MonitorMenu(
            id: widget.id,
            ffi: widget.ffi,
            setRemoteState: widget.setRemoteState);
      } else {
        return Offstage();
      }
    }));

    // Right group: view / session controls.
    final List<Widget> rightItems = [];
    rightItems.add(_DisplayMenu(
      id: widget.id,
      ffi: widget.ffi,
      state: widget.state,
      setFullscreen: _setFullscreen,
    ));
    rightItems.add(_FullscreenButton(setFullscreen: _setFullscreen));
    if (!isWeb) {
      rightItems.add(_RecordMenu());
    }
    rightItems.add(_CloseMenu(id: widget.id, ffi: widget.ffi));
    rightItems.add(_PinMenu(state: widget.state));

    final toolbarBorderRadius = BorderRadius.all(Radius.circular(8.0));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: _ToolbarTheme.elevation,
          shadowColor: MyTheme.color(context).shadow,
          borderRadius: toolbarBorderRadius,
          color: _ToolbarTheme.barBackground,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Theme(
              data: themeData(),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  ...leftItems,
                  Container(
                    width: 1,
                    height: 28,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    color: Colors.white24,
                  ),
                  ...rightItems,
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
        _buildDraggableCollapse(context),
      ],
    );
  }

  ThemeData themeData() {
    return Theme.of(context).copyWith(
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          minimumSize: MaterialStatePropertyAll(Size(64, 32)),
          textStyle: MaterialStatePropertyAll(
            TextStyle(fontWeight: FontWeight.normal),
          ),
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(_ToolbarTheme.menuButtonBorderRadius))),
        ),
      ),
      dividerTheme: DividerThemeData(
        space: _ToolbarTheme.dividerSpaceToAction,
        color: _ToolbarTheme.dividerColor(context),
      ),
      menuBarTheme: MenuBarThemeData(
          style: MenuStyle(
        padding: MaterialStatePropertyAll(EdgeInsets.zero),
        elevation: MaterialStatePropertyAll(0),
        shape: MaterialStatePropertyAll(BeveledRectangleBorder()),
      ).copyWith(
              backgroundColor:
                  Theme.of(context).menuBarTheme.style?.backgroundColor)),
    );
  }
}

class InputModeMenu {
  final String key;
  final String menu;

  InputModeMenu({required this.key, required this.menu});
}

_menuDismissCallback(FFI ffi) => ffi.inputModel.refreshMousePos();

Widget _buildPointerTrackWidget(Widget child, FFI? ffi) {
  return Listener(
    onPointerHover: (PointerHoverEvent e) => {
      if (ffi != null) {ffi.inputModel.lastMousePos = e.position}
    },
    child: MouseRegion(
      child: child,
    ),
  );
}

class EdgeThicknessControl extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ColorScheme? colorScheme;

  const EdgeThicknessControl({
    Key? key,
    required this.value,
    this.onChanged,
    this.colorScheme,
  }) : super(key: key);

  static const double kMin = 20;
  static const double kMax = 150;

  @override
  Widget build(BuildContext context) {
    final colorScheme = this.colorScheme ?? Theme.of(context).colorScheme;

    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: colorScheme.primary,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.1),
        showValueIndicator: ShowValueIndicator.never,
        thumbShape: _RectValueThumbShape(
          min: EdgeThicknessControl.kMin,
          max: EdgeThicknessControl.kMax,
          width: 52,
          height: 24,
          radius: 4,
          unit: 'px',
        ),
      ),
      child: Semantics(
        value: value.toInt().toString(),
        child: Slider(
          value: value,
          min: EdgeThicknessControl.kMin,
          max: EdgeThicknessControl.kMax,
          divisions:
              (EdgeThicknessControl.kMax - EdgeThicknessControl.kMin).round(),
          semanticFormatterCallback: (double newValue) =>
              "${newValue.round()}px",
          onChanged: onChanged,
        ),
      ),
    );

    return slider;
  }
}

