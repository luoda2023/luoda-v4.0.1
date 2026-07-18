part of 'remote_toolbar.dart';

class _PinMenu extends StatelessWidget {
  final ToolbarState state;
  const _PinMenu({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => _IconMenuButton(
        assetName: state.pin ? "assets/pinned.svg" : "assets/unpinned.svg",
        tooltip: state.pin ? 'Unpin Toolbar' : 'Pin Toolbar',
        onPressed: state.switchPin,
        color:
            state.pin ? _ToolbarTheme.blueColor : _ToolbarTheme.labelButtonColor,
        hoverColor: state.pin
            ? _ToolbarTheme.hoverBlueColor
            : _ToolbarTheme.labelButtonHover,
        label: '固定',
      ),
    );
  }
}

class _MobileActionMenu extends StatelessWidget {
  final FFI ffi;
  const _MobileActionMenu({Key? key, required this.ffi}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!ffi.ffiModel.isPeerAndroid) return Offstage();
    return Obx(() => _IconMenuButton(
          assetName: 'assets/actions_mobile.svg',
          tooltip: 'Mobile Actions',
          onPressed: () => ffi.dialogManager.setMobileActionsOverlayVisible(
              !ffi.dialogManager.mobileActionsOverlayVisible.value),
          color: ffi.dialogManager.mobileActionsOverlayVisible.isTrue
              ? _ToolbarTheme.blueColor
              : _ToolbarTheme.labelButtonColor,
          hoverColor: ffi.dialogManager.mobileActionsOverlayVisible.isTrue
              ? _ToolbarTheme.hoverBlueColor
              : _ToolbarTheme.labelButtonHover,
          label: '移动端',
        ));
  }
}

class _MonitorMenu extends StatelessWidget {
  final String id;
  final FFI ffi;
  final Function(VoidCallback) setRemoteState;
  const _MonitorMenu({
    Key? key,
    required this.id,
    required this.ffi,
    required this.setRemoteState,
  }) : super(key: key);

  bool get showMonitorsToolbar =>
      bind.mainGetUserDefaultOption(key: kKeyShowMonitorsToolbar) == 'Y';

  bool get supportIndividualWindows =>
      !isWeb && ffi.ffiModel.pi.isSupportMultiDisplay;

  @override
  Widget build(BuildContext context) => showMonitorsToolbar
      ? buildMultiMonitorMenu(context)
      : Obx(() => buildMonitorMenu(context));

  Widget buildMonitorMenu(BuildContext context) {
    final width = SimpleWrapper<double>(0);
    final monitorsIcon =
        globalMonitorsWidget(width, Colors.white, Colors.black38);
    return _IconSubmenuButton(
        tooltip: 'Select Monitor',
        icon: monitorsIcon,
        ffi: ffi,
        width: width.value,
        color: _ToolbarTheme.labelButtonColor,
        hoverColor: _ToolbarTheme.labelButtonHover,
        label: '显示器',
        menuStyle: MenuStyle(
            padding:
                MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 6))),
        menuChildrenGetter: (_) => [buildMonitorSubmenuWidget(context)]);
  }

  Widget buildMultiMonitorMenu(BuildContext context) {
    return Row(children: buildMonitorList(context, true));
  }

  Widget buildMonitorSubmenuWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: buildMonitorList(context, false)),
        supportIndividualWindows ? Divider() : Offstage(),
        supportIndividualWindows ? chooseDisplayBehavior() : Offstage(),
      ],
    );
  }

  Widget chooseDisplayBehavior() {
    final value =
        bind.sessionGetDisplaysAsIndividualWindows(sessionId: ffi.sessionId) ==
            'Y';
    return CkbMenuButton(
        value: value,
        onChanged: (value) async {
          if (value == null) return;
          await bind.sessionSetDisplaysAsIndividualWindows(
              sessionId: ffi.sessionId, value: value ? 'Y' : 'N');
        },
        ffi: ffi,
        child: Text(translate('Show displays as individual windows')));
  }

  buildOneMonitorButton(i, curDisplay) => Text(
        '${i + 1}',
        style: TextStyle(
          color: i == curDisplay
              ? _ToolbarTheme.blueColor
              : _ToolbarTheme.inactiveColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );

  List<Widget> buildMonitorList(BuildContext context, bool isMulti) {
    final List<Widget> monitorList = [];
    final pi = ffi.ffiModel.pi;

    buildMonitorButton(int i) => Obx(() {
          RxInt display = CurrentDisplayState.find(id);

          final isAllMonitors = i == kAllDisplayValue;
          final width = SimpleWrapper<double>(0);
          Widget? monitorsIcon;
          if (isAllMonitors) {
            monitorsIcon = globalMonitorsWidget(
                width, Colors.white, _ToolbarTheme.blueColor);
          }
          return _IconMenuButton(
            tooltip: isMulti
                ? ''
                : isAllMonitors
                    ? 'all monitors'
                    : '#${i + 1} monitor',
            hMargin: isMulti ? null : 6,
            vMargin: isMulti ? null : 12,
            topLevel: false,
            color: i == display.value
                ? _ToolbarTheme.blueColor
                : _ToolbarTheme.inactiveColor,
            hoverColor: i == display.value
                ? _ToolbarTheme.hoverBlueColor
                : _ToolbarTheme.hoverInactiveColor,
            width: isAllMonitors ? width.value : null,
            icon: isAllMonitors
                ? monitorsIcon
                : Container(
                    alignment: AlignmentDirectional.center,
                    constraints:
                        const BoxConstraints(minHeight: _ToolbarTheme.height),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/screen.svg",
                          colorFilter:
                              ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
                        Obx(() => buildOneMonitorButton(i, display.value)),
                      ],
                    ),
                  ),
            onPressed: () => onPressed(i, pi, isMulti),
          );
        });

    for (int i = 0; i < pi.displays.length; i++) {
      monitorList.add(buildMonitorButton(i));
    }
    if (supportIndividualWindows && pi.displays.length > 1) {
      monitorList.add(buildMonitorButton(kAllDisplayValue));
    }
    return monitorList;
  }

  globalMonitorsWidget(
      SimpleWrapper<double> width, Color activeTextColor, Color activeBgColor) {
    getMonitors() {
      final pi = ffi.ffiModel.pi;
      RxInt display = CurrentDisplayState.find(id);
      final rect = ffi.ffiModel.globalDisplaysRect();
      if (rect == null) {
        return Offstage();
      }

      final scale = _ToolbarTheme.buttonSize / rect.height * 0.75;
      final startY = (_ToolbarTheme.buttonSize - rect.height * scale) * 0.5;
      final startX = startY;

      final children = <Widget>[];
      for (var i = 0; i < pi.displays.length; i++) {
        final d = pi.displays[i];
        double s = d.scale;
        int dWidth = d.width.toDouble() ~/ s;
        int dHeight = d.height.toDouble() ~/ s;
        final fontSize = (dWidth * scale < dHeight * scale
                ? dWidth * scale
                : dHeight * scale) *
            0.65;
        children.add(Positioned(
          left: (d.x - rect.left) * scale + startX,
          top: (d.y - rect.top) * scale + startY,
          width: dWidth * scale,
          height: dHeight * scale,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1.0,
              ),
              color: display.value == i ? activeBgColor : Colors.white,
            ),
            child: Center(
                child: Text(
              '${i + 1}',
              style: TextStyle(
                color: display.value == i
                    ? activeTextColor
                    : _ToolbarTheme.inactiveColor,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            )),
          ),
        ));
      }
      width.value = rect.width * scale + startX * 2;
      return SizedBox(
        width: width.value,
        height: rect.height * scale + startY * 2,
        child: Stack(
          children: children,
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(height: _ToolbarTheme.buttonSize),
        getMonitors(),
      ],
    );
  }

  onPressed(int i, PeerInfo pi, bool isMulti) {
    if (!isMulti) {
      // If show monitors in toolbar(`buildMultiMonitorMenu()`), then the menu will dismiss automatically.
      _menuDismissCallback(ffi);
    }
    RxInt display = CurrentDisplayState.find(id);
    if (display.value != i) {
      final isChooseDisplayToOpenInNewWindow = pi.isSupportMultiDisplay &&
          bind.sessionGetDisplaysAsIndividualWindows(
                  sessionId: ffi.sessionId) ==
              'Y';
      if (isChooseDisplayToOpenInNewWindow) {
        openMonitorInNewTabOrWindow(i, ffi.id, pi);
      } else {
        openMonitorInTheSameTab(i, ffi, pi, updateCursorPos: !isMulti);
      }
    }
  }
}

class _ControlMenu extends StatelessWidget {
  final String id;
  final FFI ffi;
  final ToolbarState state;
  _ControlMenu(
      {Key? key, required this.id, required this.ffi, required this.state})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _IconSubmenuButton(
        tooltip: 'Control Actions',
        svg: "assets/actions.svg",
        color: _ToolbarTheme.labelButtonColor,
        hoverColor: _ToolbarTheme.labelButtonHover,
        label: '控制',
        ffi: ffi,
        menuChildrenGetter: (_) => toolbarControls(context, id, ffi).map((e) {
              if (e.divider) {
                return Divider();
              } else {
                return MenuButton(
                    child: e.child,
                    onPressed: e.onPressed,
                    ffi: ffi,
                    trailingIcon: e.trailingIcon);
              }
            }).toList());
  }
}

class ScreenAdjustor {
  final String id;
  final FFI ffi;
  final VoidCallback cbExitFullscreen;
  window_size.Screen? _screen;

  ScreenAdjustor({
    required this.id,
    required this.ffi,
    required this.cbExitFullscreen,
  });

  bool get isFullscreen => stateGlobal.fullscreen.isTrue;
  int get windowId => stateGlobal.windowId;

  adjustWindow(BuildContext context) {
    return futureBuilder(
        future: isWindowCanBeAdjusted(),
        hasData: (data) {
          final visible = data as bool;
          if (!visible) return Offstage();
          return Column(
            children: [
              MenuButton(
                  child: Text(translate('Adjust Window')),
                  onPressed: () => doAdjustWindow(context),
                  ffi: ffi),
              Divider(),
            ],
          );
        });
  }

  doAdjustWindow(BuildContext context) async {
    await updateScreen();
    if (_screen != null) {
      cbExitFullscreen();
      double scale = _screen!.scaleFactor;
      final wndRect = await WindowController.fromWindowId(windowId).getFrame();
      final mediaSize = MediaQueryData.fromView(View.of(context)).size;
      // On windows, wndRect is equal to GetWindowRect and mediaSize is equal to GetClientRect.
      // https://stackoverflow.com/a/7561083
      double magicWidth =
          wndRect.right - wndRect.left - mediaSize.width * scale;
      double magicHeight =
          wndRect.bottom - wndRect.top - mediaSize.height * scale;
      final canvasModel = ffi.canvasModel;
      final width = (canvasModel.getDisplayWidth() * canvasModel.scale +
                  CanvasModel.leftToEdge +
                  CanvasModel.rightToEdge) *
              scale +
          magicWidth;
      final height = (canvasModel.getDisplayHeight() * canvasModel.scale +
                  CanvasModel.topToEdge +
                  CanvasModel.bottomToEdge) *
              scale +
          magicHeight;
      double left = wndRect.left + (wndRect.width - width) / 2;
      double top = wndRect.top + (wndRect.height - height) / 2;

      Rect frameRect = _screen!.frame;
      if (!isFullscreen) {
        frameRect = _screen!.visibleFrame;
      }
      if (left < frameRect.left) {
        left = frameRect.left;
      }
      if (top < frameRect.top) {
        top = frameRect.top;
      }
      if ((left + width) > frameRect.right) {
        left = frameRect.right - width;
      }
      if ((top + height) > frameRect.bottom) {
        top = frameRect.bottom - height;
      }
      await WindowController.fromWindowId(windowId)
          .setFrame(Rect.fromLTWH(left, top, width, height));
      stateGlobal.setMaximized(false);
    }
  }

  updateScreen() async {
    final String info =
        isWeb ? screenInfo : await _getScreenInfoDesktop() ?? '';
    if (info.isEmpty) {
      _screen = null;
    } else {
      final screenMap = jsonDecode(info);
      _screen = window_size.Screen(
          Rect.fromLTRB(screenMap['frame']['l'], screenMap['frame']['t'],
              screenMap['frame']['r'], screenMap['frame']['b']),
          Rect.fromLTRB(
              screenMap['visibleFrame']['l'],
              screenMap['visibleFrame']['t'],
              screenMap['visibleFrame']['r'],
              screenMap['visibleFrame']['b']),
          screenMap['scaleFactor']);
    }
  }

  _getScreenInfoDesktop() async {
    final v = await luodaWinManager.call(
        WindowType.Main, kWindowGetWindowInfo, '');
    return v.result;
  }

  Future<bool> isWindowCanBeAdjusted() async {
    final viewStyle =
        await bind.sessionGetViewStyle(sessionId: ffi.sessionId) ?? '';
    if (viewStyle != kRemoteViewStyleOriginal) {
      return false;
    }
    if (!isWeb) {
      final remoteCount = RemoteCountState.find().value;
      if (remoteCount != 1) {
        return false;
      }
    }
    if (_screen == null) {
      return false;
    }
    final scale = kIgnoreDpi ? 1.0 : _screen!.scaleFactor;
    double selfWidth = _screen!.visibleFrame.width;
    double selfHeight = _screen!.visibleFrame.height;
    if (isFullscreen) {
      selfWidth = _screen!.frame.width;
      selfHeight = _screen!.frame.height;
    }

    final canvasModel = ffi.canvasModel;
    final displayWidth = canvasModel.getDisplayWidth();
    final displayHeight = canvasModel.getDisplayHeight();
    final requiredWidth =
        CanvasModel.leftToEdge + displayWidth + CanvasModel.rightToEdge;
    final requiredHeight =
        CanvasModel.topToEdge + displayHeight + CanvasModel.bottomToEdge;
    return selfWidth > (requiredWidth * scale) &&
        selfHeight > (requiredHeight * scale);
  }
}

class _DisplayMenu extends StatefulWidget {
  final String id;
  final FFI ffi;
  final ToolbarState state;
  final Function(bool) setFullscreen;
  final Widget pluginItem;
  _DisplayMenu(
      {Key? key,
      required this.id,
      required this.ffi,
      required this.state,
      required this.setFullscreen})
      : pluginItem = LocationItem.createLocationItem(
          id,
          ffi,
          kLocationClientRemoteToolbarDisplay,
          true,
        ),
        super(key: key);

  @override
  State<_DisplayMenu> createState() => _DisplayMenuState();
}

class _DisplayMenuState extends State<_DisplayMenu> {
  final RxInt _customPercent = 100.obs;
  late final ScreenAdjustor _screenAdjustor = ScreenAdjustor(
    id: widget.id,
    ffi: widget.ffi,
    cbExitFullscreen: () => widget.setFullscreen(false),
  );

  int get windowId => stateGlobal.windowId;
  Map<String, bool> get perms => widget.ffi.ffiModel.permissions;
  PeerInfo get pi => widget.ffi.ffiModel.pi;
  FfiModel get ffiModel => widget.ffi.ffiModel;
  FFI get ffi => widget.ffi;
  String get id => widget.id;

  @override
  void initState() {
    super.initState();
    // Initialize custom percent from stored option once
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final v = await getSessionCustomScalePercent(widget.ffi.sessionId);
        if (_customPercent.value != v) {
          _customPercent.value = v;
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    _screenAdjustor.updateScreen();
    menuChildrenGetter(_IconSubmenuButtonState state) {
      final menuChildren = <Widget>[
        _screenAdjustor.adjustWindow(context),
        viewStyle(customPercent: _customPercent),
        scrollStyle(state, colorScheme),
        imageQuality(),
        codec(),
        if (ffi.connType == ConnType.defaultConn)
          _ResolutionsMenu(
            id: widget.id,
            ffi: widget.ffi,
            screenAdjustor: _screenAdjustor,
          ),
        if (showVirtualDisplayMenu(ffi) && ffi.connType == ConnType.defaultConn)
          _SubmenuButton(
            ffi: widget.ffi,
            menuChildren: getVirtualDisplayMenuChildren(ffi, id, null),
            child: Text(translate("Virtual display")),
          ),
        if (ffi.connType == ConnType.defaultConn) cursorToggles(),
        Divider(),
        toggles(),
      ];
      // privacy mode
      if (ffi.connType == ConnType.defaultConn &&
          ffiModel.keyboard &&
          pi.features.privacyMode) {
        final privacyModeState = PrivacyModeState.find(id);
        final privacyModeList =
            toolbarPrivacyMode(privacyModeState, context, id, ffi);
        if (privacyModeList.length == 1) {
          menuChildren.add(CkbMenuButton(
              value: privacyModeList[0].value,
              onChanged: privacyModeList[0].onChanged,
              child: privacyModeList[0].child,
              ffi: ffi));
        } else if (privacyModeList.length > 1) {
          menuChildren.addAll([
            Divider(),
            _SubmenuButton(
                ffi: widget.ffi,
                child: Text(translate('Privacy mode')),
                menuChildren: privacyModeList
                    .map((e) => CkbMenuButton(
                        value: e.value,
                        onChanged: e.onChanged,
                        child: e.child,
                        ffi: ffi))
                    .toList()),
          ]);
        }
      }
      if (ffi.connType == ConnType.defaultConn) {
        menuChildren.add(widget.pluginItem);
      }
      return menuChildren;
    }

    return _IconSubmenuButton(
      tooltip: 'Display Settings',
      svg: "assets/display.svg",
      ffi: widget.ffi,
      color: _ToolbarTheme.labelButtonColor,
      hoverColor: _ToolbarTheme.labelButtonHover,
      label: '画质',
      menuChildrenGetter: menuChildrenGetter,
    );
  }

  viewStyle({required RxInt customPercent}) {
    return futureBuilder(
        future: toolbarViewStyle(context, widget.id, widget.ffi),
        hasData: (data) {
          final v = data as List<TRadioMenu<String>>;
          final bool isCustomSelected = v.isNotEmpty
              ? v.first.groupValue == kRemoteViewStyleCustom
              : false;
          return Column(children: [
            ...v.map((e) {
              final isCustom = e.value == kRemoteViewStyleCustom;
              final child =
                  isCustom ? Text(translate('Scale custom')) : e.child;
              // Whether the current selection is already custom
              final bool isGroupCustomSelected =
                  e.groupValue == kRemoteViewStyleCustom;
              // Keep menu open when switching INTO custom so the slider is visible immediately
              final bool keepOpenForThisItem =
                  isCustom && !isGroupCustomSelected;
              return RdoMenuButton<String>(
                  value: e.value,
                  groupValue: e.groupValue,
                  onChanged: (value) {
                    // Perform the original change
                    e.onChanged?.call(value);
                    // Only force a rebuild when we keep the menu open to reveal the slider
                    if (keepOpenForThisItem) {
                      setState(() {});
                    }
                  },
                  child: child,
                  ffi: ffi,
                  // When entering custom, keep submenu open to show the slider controls
                  closeOnActivate: !keepOpenForThisItem);
            }).toList(),
            // Only show a divider when custom is NOT selected
            if (!isCustomSelected) Divider(),
            _customControlsIfCustomSelected(
                onChanged: (v) => customPercent.value = v),
          ]);
        });
  }

  Widget _customControlsIfCustomSelected({ValueChanged<int>? onChanged}) {
    return futureBuilder(future: () async {
      final current = await bind.sessionGetViewStyle(sessionId: ffi.sessionId);
      return current == kRemoteViewStyleCustom;
    }(), hasData: (data) {
      final isCustom = data as bool;
      return AnimatedSwitcher(
        duration: Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: isCustom
            ? _CustomScaleMenuControls(ffi: ffi, onChanged: onChanged)
            : SizedBox.shrink(),
      );
    });
  }

  scrollStyle(_IconSubmenuButtonState state, ColorScheme colorScheme) {
    return futureBuilder(future: () async {
      final viewStyle =
          await bind.sessionGetViewStyle(sessionId: ffi.sessionId) ?? '';
      final visible = viewStyle == kRemoteViewStyleOriginal ||
          viewStyle == kRemoteViewStyleCustom;
      final scrollStyle =
          await bind.sessionGetScrollStyle(sessionId: ffi.sessionId) ?? '';
      final edgeScrollEdgeThickness = await bind
          .sessionGetEdgeScrollEdgeThickness(sessionId: ffi.sessionId);
      return {
        'visible': visible,
        'scrollStyle': scrollStyle,
        'edgeScrollEdgeThickness': edgeScrollEdgeThickness,
      };
    }(), hasData: (data) {
      final visible = data['visible'] as bool;
      if (!visible) return Offstage();
      final groupValue = data['scrollStyle'] as String;
      final edgeScrollEdgeThickness = data['edgeScrollEdgeThickness'] as int;

      onChangeScrollStyle(String? value) async {
        if (value == null) return;
        await bind.sessionSetScrollStyle(
            sessionId: ffi.sessionId, value: value);
        widget.ffi.canvasModel.updateScrollStyle();
        state.setState(() {});
      }

      onChangeEdgeScrollEdgeThickness(double? value) async {
        if (value == null) return;
        final newThickness = value.round();
        await bind.sessionSetEdgeScrollEdgeThickness(
            sessionId: ffi.sessionId, value: newThickness);
        widget.ffi.canvasModel.updateEdgeScrollEdgeThickness(newThickness);
        state.setState(() {});
      }

      return Obx(() => Column(children: [
            RdoMenuButton<String>(
              child: Text(translate('ScrollAuto')),
              value: kRemoteScrollStyleAuto,
              groupValue: groupValue,
              onChanged: widget.ffi.canvasModel.imageOverflow.value
                  ? (value) => onChangeScrollStyle(value)
                  : null,
              closeOnActivate: groupValue != kRemoteScrollStyleEdge,
              ffi: widget.ffi,
            ),
            RdoMenuButton<String>(
              child: Text(translate('Scrollbar')),
              value: kRemoteScrollStyleBar,
              groupValue: groupValue,
              onChanged: widget.ffi.canvasModel.imageOverflow.value
                  ? (value) => onChangeScrollStyle(value)
                  : null,
              closeOnActivate: groupValue != kRemoteScrollStyleEdge,
              ffi: widget.ffi,
            ),
            if (!isWeb) ...[
              RdoMenuButton<String>(
                child: Text(translate('ScrollEdge')),
                value: kRemoteScrollStyleEdge,
                groupValue: groupValue,
                closeOnActivate: false,
                onChanged: widget.ffi.canvasModel.imageOverflow.value
                    ? (value) => onChangeScrollStyle(value)
                    : null,
                ffi: widget.ffi,
              ),
              Offstage(
                  offstage: groupValue != kRemoteScrollStyleEdge,
                  child: EdgeThicknessControl(
                    value: edgeScrollEdgeThickness.toDouble(),
                    onChanged: onChangeEdgeScrollEdgeThickness,
                    colorScheme: colorScheme,
                  )),
            ],
            Divider(),
          ]));
    });
  }

  imageQuality() {
    return futureBuilder(
        future: toolbarImageQuality(context, widget.id, widget.ffi),
        hasData: (data) {
          final v = data as List<TRadioMenu<String>>;
          return _SubmenuButton(
            ffi: widget.ffi,
            child: Text(translate('Image Quality')),
            menuChildren: v
                .map((e) => RdoMenuButton<String>(
                    value: e.value,
                    groupValue: e.groupValue,
                    onChanged: e.onChanged,
                    child: e.child,
                    ffi: ffi))
                .toList(),
          );
        });
  }

  codec() {
    return futureBuilder(
        future: toolbarCodec(context, id, ffi),
        hasData: (data) {
          final v = data as List<TRadioMenu<String>>;
          if (v.isEmpty) return Offstage();

          return _SubmenuButton(
              ffi: widget.ffi,
              child: Text(translate('Codec')),
              menuChildren: v
                  .map((e) => RdoMenuButton(
                      value: e.value,
                      groupValue: e.groupValue,
                      onChanged: e.onChanged,
                      child: e.child,
                      ffi: ffi))
                  .toList());
        });
  }

  cursorToggles() {
    return futureBuilder(
        future: toolbarCursor(context, id, ffi),
        hasData: (data) {
          final v = data as List<TToggleMenu>;
          if (v.isEmpty) return Offstage();
          return Column(children: [
            Divider(),
            ...v
                .map((e) => CkbMenuButton(
                    value: e.value,
                    onChanged: e.onChanged,
                    child: e.child,
                    ffi: ffi))
                .toList(),
          ]);
        });
  }

  toggles() {
    return futureBuilder(
        future: toolbarDisplayToggle(context, id, ffi),
        hasData: (data) {
          final v = data as List<TToggleMenu>;
          if (v.isEmpty) return Offstage();
          return Column(
              children: v
                  .map((e) => CkbMenuButton(
                      value: e.value,
                      onChanged: e.onChanged,
                      child: e.child,
                      ffi: ffi))
                  .toList());
        });
  }
}

class _CustomScaleMenuControls extends StatefulWidget {
  final FFI ffi;
  final ValueChanged<int>? onChanged;
  const _CustomScaleMenuControls({Key? key, required this.ffi, this.onChanged})
      : super(key: key);

  @override
  State<_CustomScaleMenuControls> createState() =>
      _CustomScaleMenuControlsState();
}

class _CustomScaleMenuControlsState
    extends CustomScaleControls<_CustomScaleMenuControls> {
  @override
  FFI get ffi => widget.ffi;

  @override
  ValueChanged<int>? get onScaleChanged => widget.onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const smallBtnConstraints = BoxConstraints(minWidth: 28, minHeight: 28);

    final sliderControl = Semantics(
      label: translate('Custom scale slider'),
      value: '$scaleValue%',
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: colorScheme.primary,
          thumbColor: colorScheme.primary,
          overlayColor: colorScheme.primary.withOpacity(0.1),
          showValueIndicator: ShowValueIndicator.never,
          thumbShape: _RectValueThumbShape(
            min: CustomScaleControls.minPercent.toDouble(),
            max: CustomScaleControls.maxPercent.toDouble(),
            width: 52,
            height: 24,
            radius: 4,
            displayValueForNormalized: (t) => mapPosToPercent(t),
          ),
        ),
        child: Slider(
          value: scalePos,
          min: 0.0,
          max: 1.0,
          // Use a wide range of divisions (calculated as (CustomScaleControls.maxPercent - CustomScaleControls.minPercent)) to provide ~1% precision increments.
          // This allows users to set precise scale values. Lower values would require more fine-tuning via the +/- buttons, which is undesirable for big ranges.
          divisions:
              (CustomScaleControls.maxPercent - CustomScaleControls.minPercent)
                  .round(),
          onChanged: onSliderChanged,
        ),
      ),
    );

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(children: [
          Tooltip(
            message: translate('Decrease'),
            child: IconButton(
              iconSize: 16,
              padding: EdgeInsets.all(1),
              constraints: smallBtnConstraints,
              icon: const Icon(Icons.remove),
              onPressed: () => nudgeScale(-1),
            ),
          ),
          Expanded(child: sliderControl),
          Tooltip(
            message: translate('Increase'),
            child: IconButton(
              iconSize: 16,
              padding: EdgeInsets.all(1),
              constraints: smallBtnConstraints,
              icon: const Icon(Icons.add),
              onPressed: () => nudgeScale(1),
            ),
          ),
        ]),
      ),
      Divider(),
    ]);
  }
}

// Lightweight rectangular thumb that paints the current percentage.
// Stateless and uses only SliderTheme colors; avoids allocations beyond a TextPainter per frame.
class _RectValueThumbShape extends SliderComponentShape {
  final double min;
  final double max;
  final double width;
  final double height;
  final double radius;
  final String unit;
  // Optional mapper to compute display value from normalized position [0,1]
  // If null, falls back to linear interpolation between min and max.
  final int Function(double normalized)? displayValueForNormalized;

  const _RectValueThumbShape({
    required this.min,
    required this.max,
    required this.width,
    required this.height,
    required this.radius,
    this.displayValueForNormalized,
    this.unit = '%',
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(width, height);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Resolve color based on enabled/disabled animation, with safe fallbacks.
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    );
    final Color? evaluatedColor = colorTween.evaluate(enableAnimation);
    final Color? thumbColor = sliderTheme.thumbColor;
    final Color fillColor = evaluatedColor ?? thumbColor ?? Colors.blueAccent;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      Radius.circular(radius),
    );
    final Paint paint = Paint()..color = fillColor;
    canvas.drawRRect(rrect, paint);

    // Compute displayed value from normalized slider value.
    final int displayValue = displayValueForNormalized != null
        ? displayValueForNormalized!(value)
        : (min + value * (max - min)).round();
    final TextSpan span = TextSpan(
      text: '$displayValue$unit',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
    final TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: textDirection,
    );
    tp.layout(maxWidth: width - 4);
    tp.paint(
        canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }
}

class _ResolutionsMenu extends StatefulWidget {
  final String id;
  final FFI ffi;
  final ScreenAdjustor screenAdjustor;

  _ResolutionsMenu({
    Key? key,
    required this.id,
    required this.ffi,
    required this.screenAdjustor,
  }) : super(key: key);

  @override
  State<_ResolutionsMenu> createState() => _ResolutionsMenuState();
}

const double _kCustomResolutionEditingWidth = 42;
const _kCustomResolutionValue = 'custom';

class _ResolutionsMenuState extends State<_ResolutionsMenu> {
  String _groupValue = '';
  Resolution? _localResolution;

  late final TextEditingController _customWidth =
      TextEditingController(text: rect?.width.toInt().toString() ?? '');
  late final TextEditingController _customHeight =
      TextEditingController(text: rect?.height.toInt().toString() ?? '');

  FFI get ffi => widget.ffi;
  PeerInfo get pi => widget.ffi.ffiModel.pi;
  FfiModel get ffiModel => widget.ffi.ffiModel;
  Rect? get rect => scaledRect();
  List<Resolution> get resolutions => pi.resolutions;
  bool get isWayland => bind.mainCurrentIsWayland();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getLocalResolutionWayland();
    });
  }

  Rect? scaledRect() {
    final scale = pi.scaleOfDisplay(pi.currentDisplay);
    final rect = ffiModel.rect;
    if (rect == null) {
      return null;
    }
    return Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width / scale,
      rect.height / scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVirtualDisplay = ffiModel.isVirtualDisplayResolution;
    final visible = ffiModel.keyboard &&
        (isVirtualDisplay || resolutions.length > 1) &&
        pi.currentDisplay != kAllDisplayValue;
    if (!visible) return Offstage();
    final showOriginalBtn =
        ffiModel.isOriginalResolutionSet && !ffiModel.isOriginalResolution;
    final showFitLocalBtn = !_isRemoteResolutionFitLocal();
    _setGroupValue();
    return _SubmenuButton(
      ffi: widget.ffi,
      menuChildren: <Widget>[
            _OriginalResolutionMenuButton(context, showOriginalBtn),
            _FitLocalResolutionMenuButton(context, showFitLocalBtn),
            _customResolutionMenuButton(context, isVirtualDisplay),
            _menuDivider(showOriginalBtn, showFitLocalBtn, isVirtualDisplay),
          ] +
          _supportedResolutionMenuButtons(),
      child: Text(translate("Resolution")),
    );
  }

  _setGroupValue() {
    if (pi.currentDisplay == kAllDisplayValue) {
      return;
    }
    final lastGroupValue =
        stateGlobal.getLastResolutionGroupValue(widget.id, pi.currentDisplay);
    if (lastGroupValue == _kCustomResolutionValue) {
      _groupValue = _kCustomResolutionValue;
    } else {
      _groupValue =
          '${(rect?.width ?? 0).toInt()}x${(rect?.height ?? 0).toInt()}';
    }
  }

  _menuDivider(
      bool showOriginalBtn, bool showFitLocalBtn, bool isVirtualDisplay) {
    return Offstage(
      offstage: !(showOriginalBtn || showFitLocalBtn || isVirtualDisplay),
      child: Divider(),
    );
  }

  Future<void> _getLocalResolutionWayland() async {
    if (!isWayland) return _getLocalResolution();
    final window = await window_size.getWindowInfo();
    final screen = window.screen;
    if (screen != null) {
      setState(() {
        _localResolution = Resolution(
          screen.frame.width.toInt(),
          screen.frame.height.toInt(),
        );
      });
    }
  }

  _getLocalResolution() {
    _localResolution = null;
    final String mainDisplay = bind.mainGetMainDisplay();
    if (mainDisplay.isNotEmpty) {
      try {
        final display = json.decode(mainDisplay);
        if (display['w'] != null && display['h'] != null) {
          _localResolution = Resolution(display['w'], display['h']);
          if (isWeb) {
            if (display['scaleFactor'] != null) {
              _localResolution = Resolution(
                (display['w'] / display['scaleFactor']).toInt(),
                (display['h'] / display['scaleFactor']).toInt(),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Failed to decode $mainDisplay, $e');
      }
    }
  }

  // This widget has been unmounted, so the State no longer has a context
  _onChanged(String? value) async {
    if (pi.currentDisplay == kAllDisplayValue) {
      return;
    }
    stateGlobal.setLastResolutionGroupValue(
        widget.id, pi.currentDisplay, value);
    if (value == null) return;

    int? w;
    int? h;
    if (value == _kCustomResolutionValue) {
      w = int.tryParse(_customWidth.text);
      h = int.tryParse(_customHeight.text);
    } else {
      final list = value.split('x');
      if (list.length == 2) {
        w = int.tryParse(list[0]);
        h = int.tryParse(list[1]);
      }
    }

    if (w != null && h != null) {
      if (w != rect?.width.toInt() || h != rect?.height.toInt()) {
        await _changeResolution(w, h);
      }
    }
  }

  _changeResolution(int w, int h) async {
    if (pi.currentDisplay == kAllDisplayValue) {
      return;
    }
    await bind.sessionChangeResolution(
      sessionId: ffi.sessionId,
      display: pi.currentDisplay,
      width: w,
      height: h,
    );
    Future.delayed(Duration(seconds: 3), () async {
      final rect = ffiModel.rect;
      if (rect == null) {
        return;
      }
      if (w == rect.width.toInt() && h == rect.height.toInt()) {
        if (await widget.screenAdjustor.isWindowCanBeAdjusted()) {
          widget.screenAdjustor.doAdjustWindow(context);
        }
      }
    });
  }

  Widget _OriginalResolutionMenuButton(
      BuildContext context, bool showOriginalBtn) {
    final display = pi.tryGetDisplayIfNotAllDisplay();
    if (display == null) {
      return Offstage();
    }
    if (!resolutions.any((e) =>
        e.width == display.originalWidth &&
        e.height == display.originalHeight)) {
      return Offstage();
    }
    return Offstage(
      offstage: !showOriginalBtn,
      child: MenuButton(
        onPressed: () =>
            _changeResolution(display.originalWidth, display.originalHeight),
        ffi: widget.ffi,
        child: Text(
            '${translate('resolution_original_tip')} ${display.originalWidth}x${display.originalHeight}'),
      ),
    );
  }

  Widget _FitLocalResolutionMenuButton(
      BuildContext context, bool showFitLocalBtn) {
    return Offstage(
      offstage: !showFitLocalBtn,
      child: MenuButton(
        onPressed: () {
          final resolution = _getBestFitResolution();
          if (resolution != null) {
            _changeResolution(resolution.width, resolution.height);
          }
        },
        ffi: widget.ffi,
        child: Text(
            '${translate('resolution_fit_local_tip')} ${_localResolution?.width ?? 0}x${_localResolution?.height ?? 0}'),
      ),
    );
  }

  Widget _customResolutionMenuButton(BuildContext context, isVirtualDisplay) {
    return Offstage(
      offstage: !isVirtualDisplay,
      child: RdoMenuButton(
        value: _kCustomResolutionValue,
        groupValue: _groupValue,
        onChanged: (String? value) => _onChanged(value),
        ffi: widget.ffi,
        child: Row(
          children: [
            Text('${translate('resolution_custom_tip')} '),
            SizedBox(
              width: _kCustomResolutionEditingWidth,
              child: _resolutionInput(_customWidth),
            ),
            Text(' x '),
            SizedBox(
              width: _kCustomResolutionEditingWidth,
              child: _resolutionInput(_customHeight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resolutionInput(TextEditingController controller) {
    return TextField(
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.fromLTRB(3, 3, 3, 3),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
      ],
      controller: controller,
    ).workaroundFreezeLinuxMint();
  }

  List<Widget> _supportedResolutionMenuButtons() => resolutions
      .map((e) => RdoMenuButton(
          value: '${e.width}x${e.height}',
          groupValue: _groupValue,
          onChanged: (String? value) => _onChanged(value),
          ffi: widget.ffi,
          child: Text('${e.width}x${e.height}')))
      .toList();

  Resolution? _getBestFitResolution() {
    if (_localResolution == null) {
      return null;
    }

    if (ffiModel.isVirtualDisplayResolution) {
      return _localResolution!;
    }

    for (final r in resolutions) {
      if (r.width == _localResolution!.width &&
          r.height == _localResolution!.height) {
        return r;
      }
    }

    return null;
  }

  bool _isRemoteResolutionFitLocal() {
    if (_localResolution == null) {
      return true;
    }
    final bestFitResolution = _getBestFitResolution();
    if (bestFitResolution == null) {
      return true;
    }
    return bestFitResolution.width == rect?.width.toInt() &&
        bestFitResolution.height == rect?.height.toInt();
  }
}

class _KeyboardMenu extends StatelessWidget {
  final String id;
  final FFI ffi;
  _KeyboardMenu({
    Key? key,
    required this.id,
    required this.ffi,
  }) : super(key: key);

  PeerInfo get pi => ffi.ffiModel.pi;

  @override
  Widget build(BuildContext context) {
    var ffiModel = Provider.of<FfiModel>(context);
    if (!ffiModel.keyboard) return Offstage();
    toolbarToggles() {
      final toggles = toolbarKeyboardToggles(ffi)
          .map((e) => CkbMenuButton(
              value: e.value,
              onChanged: e.onChanged,
              child: e.child,
              ffi: ffi) as Widget)
          .toList();
      if (toggles.isNotEmpty) {
        toggles.add(Divider());
      }
      return toggles;
    }

    return _IconSubmenuButton(
        tooltip: 'Keyboard Settings',
        svg: "assets/keyboard_mouse.svg",
        ffi: ffi,
        color: _ToolbarTheme.labelButtonColor,
        hoverColor: _ToolbarTheme.labelButtonHover,
        label: '快捷键',
        menuChildrenGetter: (_) => [
              keyboardMode(),
              localKeyboardType(),
              inputSource(),
              Divider(),
              viewMode(),
              if ([kPeerPlatformWindows, kPeerPlatformMacOS, kPeerPlatformLinux]
                  .contains(pi.platform))
                showMyCursor(),
              Divider(),
              ...toolbarToggles(),
              ...mouseSpeed(),
              ...mobileActions(),
            ]);
  }

  mouseSpeed() {
    final speedWidgets = [];
    final sessionId = ffi.sessionId;
    if (isDesktop) {
      if (ffi.ffiModel.keyboard) {
        final enabled = !ffi.ffiModel.viewOnly;
        final trackpad = MenuButton(
          child: Text(translate('Trackpad speed')).paddingOnly(left: 26.0),
          onPressed: enabled ? () => trackpadSpeedDialog(sessionId, ffi) : null,
          ffi: ffi,
        );
        speedWidgets.add(trackpad);
      }
    }
    return speedWidgets;
  }

  keyboardMode() {
    return futureBuilder(future: () async {
      return await bind.sessionGetKeyboardMode(sessionId: ffi.sessionId) ??
          kKeyLegacyMode;
    }(), hasData: (data) {
      final groupValue = data as String;
      List<InputModeMenu> modes = [
        InputModeMenu(key: kKeyLegacyMode, menu: 'Legacy mode'),
        InputModeMenu(key: kKeyMapMode, menu: 'Map mode'),
        InputModeMenu(key: kKeyTranslateMode, menu: 'Translate mode'),
      ];
      List<RdoMenuButton> list = [];
      final enabled = !ffi.ffiModel.viewOnly;
      onChanged(String? value) async {
        if (value == null) return;
        await bind.sessionSetKeyboardMode(
            sessionId: ffi.sessionId, value: value);
        await ffi.inputModel.updateKeyboardMode();
      }

      // If use flutter to grab keys, we can only use one mode.
      // Map mode and Legacy mode, at least one of them is supported.
      String? modeOnly;
      // Keep both map and legacy mode on web at the moment.
      // TODO: Remove legacy mode after web supports translate mode on web.
      if (isInputSourceFlutter && isDesktop) {
        if (bind.sessionIsKeyboardModeSupported(
            sessionId: ffi.sessionId, mode: kKeyMapMode)) {
          modeOnly = kKeyMapMode;
        } else if (bind.sessionIsKeyboardModeSupported(
            sessionId: ffi.sessionId, mode: kKeyLegacyMode)) {
          modeOnly = kKeyLegacyMode;
        }
      }

      for (InputModeMenu mode in modes) {
        if (modeOnly != null && mode.key != modeOnly) {
          continue;
        } else if (!bind.sessionIsKeyboardModeSupported(
            sessionId: ffi.sessionId, mode: mode.key)) {
          continue;
        }

        if (pi.isWayland) {
          // Legacy mode is hidden on desktop control side because dead keys
          // don't work properly on Wayland. When the control side is mobile,
          // Legacy mode is used automatically (mobile always sends Legacy events).
          if (mode.key == kKeyLegacyMode) {
            continue;
          }
          // Translate mode requires server >= 1.4.6.
          if (mode.key == kKeyTranslateMode &&
              versionCmp(pi.version, '1.4.6') < 0) {
            continue;
          }
        }

        var text = translate(mode.menu);
        if (mode.key == kKeyTranslateMode) {
          text = '$text beta';
        }
        list.add(RdoMenuButton<String>(
          child: Text(text),
          value: mode.key,
          groupValue: groupValue,
          onChanged: enabled ? onChanged : null,
          ffi: ffi,
        ));
      }
      return Column(children: list);
    });
  }

  localKeyboardType() {
    final localPlatform = getLocalPlatformForKBLayoutType(pi.platform);
    final visible = localPlatform != '';
    if (!visible) return Offstage();
    final enabled = !ffi.ffiModel.viewOnly;
    return Column(
      children: [
        Divider(),
        MenuButton(
          child: Text(
              '${translate('Local keyboard type')}: ${KBLayoutType.value}'),
          trailingIcon: const Icon(Icons.settings),
          ffi: ffi,
          onPressed: enabled
              ? () => showKBLayoutTypeChooser(localPlatform, ffi.dialogManager)
              : null,
        )
      ],
    );
  }

  inputSource() {
    final supportedInputSource = bind.mainSupportedInputSource();
    if (supportedInputSource.isEmpty) return Offstage();
    late final List<dynamic> supportedInputSourceList;
    try {
      supportedInputSourceList = jsonDecode(supportedInputSource);
    } catch (e) {
      debugPrint('Failed to decode $supportedInputSource, $e');
      return;
    }
    if (supportedInputSourceList.length < 2) return Offstage();
    final inputSource = stateGlobal.getInputSource();
    final enabled = !ffi.ffiModel.viewOnly;
    final children = <Widget>[Divider()];
    children.addAll(supportedInputSourceList.map((e) {
      final d = e as List<dynamic>;
      return RdoMenuButton<String>(
        child: Text(translate(d[1] as String)),
        value: d[0] as String,
        groupValue: inputSource,
        onChanged: enabled
            ? (v) async {
                if (v != null) {
                  await stateGlobal.setInputSource(ffi.sessionId, v);
                  await ffi.ffiModel.checkDesktopKeyboardMode();
                  await ffi.inputModel.updateKeyboardMode();
                }
              }
            : null,
        ffi: ffi,
      );
    }));
    return Column(children: children);
  }

  viewMode() {
    final ffiModel = ffi.ffiModel;
    final enabled = versionCmp(pi.version, '1.2.0') >= 0 && ffiModel.keyboard;
    return CkbMenuButton(
        value: ffiModel.viewOnly,
        onChanged: enabled
            ? (value) async {
                if (value == null) return;
                await bind.sessionToggleOption(
                    sessionId: ffi.sessionId, value: kOptionToggleViewOnly);
                final viewOnly = await bind.sessionGetToggleOption(
                    sessionId: ffi.sessionId, arg: kOptionToggleViewOnly);
                ffiModel.setViewOnly(id, viewOnly ?? value);
                final showMyCursor = await bind.sessionGetToggleOption(
                    sessionId: ffi.sessionId, arg: kOptionToggleShowMyCursor);
                ffiModel.setShowMyCursor(showMyCursor ?? value);
              }
            : null,
        ffi: ffi,
        child: Text(translate('View Mode')));
  }

  showMyCursor() {
    final ffiModel = ffi.ffiModel;
    return CkbMenuButton(
            value: ffiModel.showMyCursor,
            onChanged: (value) async {
              if (value == null) return;
              await bind.sessionToggleOption(
                  sessionId: ffi.sessionId, value: kOptionToggleShowMyCursor);
              final showMyCursor = await bind.sessionGetToggleOption(
                      sessionId: ffi.sessionId,
                      arg: kOptionToggleShowMyCursor) ??
                  value;
              ffiModel.setShowMyCursor(showMyCursor);

              // Also set view only if showMyCursor is enabled and viewOnly is not enabled.
              if (showMyCursor && !ffiModel.viewOnly) {
                await bind.sessionToggleOption(
                    sessionId: ffi.sessionId, value: kOptionToggleViewOnly);
                final viewOnly = await bind.sessionGetToggleOption(
                    sessionId: ffi.sessionId, arg: kOptionToggleViewOnly);
                ffiModel.setViewOnly(id, viewOnly ?? value);
              }
            },
            ffi: ffi,
            child: Text(translate('Show my cursor')))
        .paddingOnly(left: 26.0);
  }

  mobileActions() {
    if (pi.platform != kPeerPlatformAndroid) return [];
    final enabled = versionCmp(pi.version, '1.2.7') >= 0;
    if (!enabled) return [];
    return [
      Divider(),
      MenuButton(
          child: Text(translate('Back')),
          onPressed: () => ffi.inputModel.onMobileBack(),
          ffi: ffi),
      MenuButton(
          child: Text(translate('Home')),
          onPressed: () => ffi.inputModel.onMobileHome(),
          ffi: ffi),
      MenuButton(
          child: Text(translate('Apps')),
          onPressed: () => ffi.inputModel.onMobileApps(),
          ffi: ffi),
      MenuButton(
          child: Text(translate('Volume up')),
          onPressed: () => ffi.inputModel.onMobileVolumeUp(),
          ffi: ffi),
      MenuButton(
          child: Text(translate('Volume down')),
          onPressed: () => ffi.inputModel.onMobileVolumeDown(),
          ffi: ffi),
      MenuButton(
          child: Text(translate('Power')),
          onPressed: () => ffi.inputModel.onMobilePower(),
          ffi: ffi),
    ];
  }
}

class _ChatMenu extends StatefulWidget {
  final String id;
  final FFI ffi;
  _ChatMenu({
    Key? key,
    required this.id,
    required this.ffi,
  }) : super(key: key);

  @override
  State<_ChatMenu> createState() => _ChatMenuState();
}

class _ChatMenuState extends State<_ChatMenu> {
  // Using in StatelessWidget got `Looking up a deactivated widget's ancestor is unsafe`.
  final chatButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (isWeb) {
      return buildTextChatButton();
    } else {
      return _IconSubmenuButton(
          tooltip: 'Chat',
          key: chatButtonKey,
          svg: 'assets/chat.svg',
          ffi: widget.ffi,
          color: _ToolbarTheme.labelButtonColor,
          hoverColor: _ToolbarTheme.labelButtonHover,
          label: '聊天',
          menuChildrenGetter: (_) => [textChat(), voiceCall()]);
    }
  }

  buildTextChatButton() {
    return _IconMenuButton(
      assetName: 'assets/message_24dp_5F6368.svg',
      tooltip: 'Text chat',
      key: chatButtonKey,
      onPressed: _textChatOnPressed,
      color: _ToolbarTheme.labelButtonColor,
      hoverColor: _ToolbarTheme.hoverBlueColor,
    );
  }

  textChat() {
    return MenuButton(
        child: Text(translate('Text chat')),
        ffi: widget.ffi,
        onPressed: _textChatOnPressed);
  }

  _textChatOnPressed() {
    RenderBox? renderBox =
        chatButtonKey.currentContext?.findRenderObject() as RenderBox?;
    Offset? initPos;
    if (renderBox != null) {
      final pos = renderBox.localToGlobal(Offset.zero);
      initPos = Offset(pos.dx, pos.dy + _ToolbarTheme.dividerHeight);
    }
    widget.ffi.chatModel
        .changeCurrentKey(MessageKey(widget.ffi.id, ChatModel.clientModeID));
    widget.ffi.chatModel.toggleChatOverlay(chatInitPos: initPos);
  }

  voiceCall() {
    return MenuButton(
      child: Text(translate('Voice call')),
      ffi: widget.ffi,
      onPressed: () =>
          bind.sessionRequestVoiceCall(sessionId: widget.ffi.sessionId),
    );
  }
}

class _VoiceCallMenu extends StatelessWidget {
  final String id;
  final FFI ffi;
  _VoiceCallMenu({
    Key? key,
    required this.id,
    required this.ffi,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    menuChildrenGetter(_IconSubmenuButtonState state) {
      final audioInput = AudioInput(
        builder: (devices, currentDevice, setDevice) {
          return Column(
            children: devices
                .map((d) => RdoMenuButton<String>(
                      child: Container(
                        child: Text(
                          d,
                          overflow: TextOverflow.ellipsis,
                        ),
                        constraints: BoxConstraints(maxWidth: 250),
                      ),
                      value: d,
                      groupValue: currentDevice,
                      onChanged: (v) {
                        if (v != null) setDevice(v);
                      },
                      ffi: ffi,
                    ))
                .toList(),
          );
        },
        isCm: false,
        isVoiceCall: true,
      );
      return [
        audioInput,
        Divider(),
        MenuButton(
          child: Text(translate('End call')),
          onPressed: () => bind.sessionCloseVoiceCall(sessionId: ffi.sessionId),
          ffi: ffi,
        ),
      ];
    }

    return Obx(
      () {
        switch (ffi.chatModel.voiceCallStatus.value) {
          case VoiceCallStatus.waitingForResponse:
            return buildCallWaiting(context);
          case VoiceCallStatus.connected:
            return _IconSubmenuButton(
              tooltip: 'Voice call',
              svg: 'assets/voice_call.svg',
              color: _ToolbarTheme.labelButtonColor,
              hoverColor: _ToolbarTheme.labelButtonHover,
              label: '语音',
              menuChildrenGetter: menuChildrenGetter,
              ffi: ffi,
            );
          default:
            return Offstage();
        }
      },
    );
  }

  Widget buildCallWaiting(BuildContext context) {
    return _IconMenuButton(
      assetName: "assets/call_wait.svg",
      tooltip: "Waiting",
      onPressed: () => bind.sessionCloseVoiceCall(sessionId: ffi.sessionId),
      color: _ToolbarTheme.redColor,
      hoverColor: _ToolbarTheme.hoverRedColor,
    );
  }
}

class _RecordMenu extends StatelessWidget {
  const _RecordMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var ffi = Provider.of<FfiModel>(context);
    var recordingModel = Provider.of<RecordingModel>(context);
    final visible =
        (recordingModel.start || ffi.permissions['recording'] != false);
    if (!visible) return Offstage();
    return _IconMenuButton(
      assetName: 'assets/rec.svg',
      tooltip: recordingModel.start
          ? 'Stop session recording'
          : 'Start session recording',
      onPressed: () => recordingModel.toggle(),
      color: recordingModel.start
          ? _ToolbarTheme.redColor
          : _ToolbarTheme.labelButtonColor,
      hoverColor: recordingModel.start
          ? _ToolbarTheme.hoverRedColor
          : _ToolbarTheme.labelButtonHover,
      label: '录制',
    );
  }
}

class _CloseMenu extends StatelessWidget {
  final String id;
  final FFI ffi;
  const _CloseMenu({Key? key, required this.id, required this.ffi})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _IconMenuButton(
      assetName: 'assets/close.svg',
      tooltip: 'Close',
      onPressed: () async {
        if (await showConnEndAuditDialogCloseCanceled(ffi: ffi)) {
          return;
        }
        closeConnection(id: id);
      },
      color: _ToolbarTheme.redColor,
      hoverColor: _ToolbarTheme.hoverRedColor,
      label: '关闭',
    );
  }
}

class _TerminalMenu extends StatelessWidget {
  final String id;
  final FFI ffi;
  const _TerminalMenu({Key? key, required this.id, required this.ffi})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _IconSubmenuButton(
      tooltip: 'Terminal',
      icon: Icon(Icons.terminal, color: Colors.white, size: 20),
      color: _ToolbarTheme.labelButtonColor,
      hoverColor: _ToolbarTheme.labelButtonHover,
      label: '终端',
      ffi: ffi,
      menuChildrenGetter: (_) => [
        MenuButton(
          child: Text(translate('Open Terminal')),
          onPressed: () {
            connect(context, id, isTerminal: true);
          },
          ffi: ffi,
        ),
      ],
    );
  }
}

class _FileMenu extends StatelessWidget {
  final String id;
  final FFI ffi;
  const _FileMenu({Key? key, required this.id, required this.ffi})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _IconSubmenuButton(
      tooltip: 'File Transfer',
      svg: "assets/file_transfer.svg",
      color: _ToolbarTheme.labelButtonColor,
      hoverColor: _ToolbarTheme.labelButtonHover,
      label: '文件',
      ffi: ffi,
      menuChildrenGetter: (_) => [
        MenuButton(
          child: Text(translate('Open File Transfer')),
          onPressed: () {
            connect(context, id, isFileTransfer: true);
          },
          ffi: ffi,
        ),
      ],
    );
  }
}

class _ClipboardMenu extends StatelessWidget {
  final String id;
  final FFI ffi;
  const _ClipboardMenu({Key? key, required this.id, required this.ffi})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sessionId = ffi.sessionId;
    return _IconSubmenuButton(
      tooltip: 'Clipboard',
      icon: Icon(Icons.content_paste, color: Colors.white, size: 20),
      color: _ToolbarTheme.labelButtonColor,
      hoverColor: _ToolbarTheme.labelButtonHover,
      label: '剪贴板',
      ffi: ffi,
      menuChildrenGetter: (_) => [
        CkbMenuButton(
          value: bind.sessionGetToggleOptionSync(
              sessionId: sessionId, arg: kOptionEnableFileCopyPaste),
          onChanged: (v) {
            if (v == null) return;
            bind.sessionToggleOption(
                sessionId: sessionId, value: kOptionEnableFileCopyPaste);
          },
          child: Text(translate('Enable file copy and paste')),
          ffi: ffi,
        ),
        CkbMenuButton(
          value: bind.sessionGetToggleOptionSync(
              sessionId: sessionId, arg: kOptionDisableClipboard),
          onChanged: (v) {
            if (v == null) return;
            bind.sessionToggleOption(
                sessionId: sessionId, value: kOptionDisableClipboard);
          },
          child: Text(translate('Disable clipboard')),
          ffi: ffi,
        ),
      ],
    );
  }
}

class _SystemMenu extends StatelessWidget {
  final String id;
  final FFI ffi;
  const _SystemMenu({Key? key, required this.id, required this.ffi})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sessionId = ffi.sessionId;
    return _IconSubmenuButton(
      tooltip: 'System',
      icon: Icon(Icons.computer, color: Colors.white, size: 20),
      color: _ToolbarTheme.labelButtonColor,
      hoverColor: _ToolbarTheme.labelButtonHover,
      label: '系统',
      ffi: ffi,
      menuChildrenGetter: (_) => [
        MenuButton(
          child: Text(translate('Insert Lock')),
          onPressed: () => bind.sessionLockScreen(sessionId: sessionId),
          ffi: ffi,
        ),
        MenuButton(
          child: Text(translate('Insert Ctrl + Alt + Del')),
          onPressed: () => bind.sessionCtrlAltDel(sessionId: sessionId),
          ffi: ffi,
        ),
        MenuButton(
          child: Text(translate('Restart Remote Device')),
          onPressed: () => showRestartRemoteDevice(
              ffi.ffiModel.pi, id, ffi.sessionId, ffi.dialogManager),
          ffi: ffi,
        ),
      ],
    );
  }
}

class _ScreenshotButton extends StatelessWidget {
  final String id;
  final FFI ffi;
  const _ScreenshotButton({Key? key, required this.id, required this.ffi})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _IconMenuButton(
      assetName: "assets/screen.svg",
      tooltip: 'Take Screenshot',
      onPressed: () {
        if (isDesktop && !isWeb) {
          final pi = ffi.ffiModel.pi;
          if (pi.currentDisplay == kAllDisplayValue) {
            msgBox(
                ffi.sessionId,
                'custom-nook-nocancel-hasclose-info',
                'Take screenshot',
                'screenshot-merged-screen-not-supported-tip',
                '',
                ffi.dialogManager);
          } else {
            bind.sessionTakeScreenshot(
                sessionId: ffi.sessionId, display: pi.currentDisplay);
            ffi.ffiModel.timerScreenshot =
                Timer(const Duration(seconds: 30), () {
              ffi.ffiModel.timerScreenshot = null;
            });
          }
        }
      },
      color: _ToolbarTheme.labelButtonColor,
      hoverColor: _ToolbarTheme.labelButtonHover,
      label: '截屏',
    );
  }
}

class _FullscreenButton extends StatelessWidget {
  final Function(bool) setFullscreen;
  const _FullscreenButton(
      {Key? key, required this.setFullscreen})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => _IconMenuButton(
          assetName: stateGlobal.fullscreen.isTrue
              ? "assets/fullscreen_exit.svg"
              : "assets/fullscreen.svg",
          tooltip: 'Fullscreen',
          onPressed: () =>
              setFullscreen(!stateGlobal.fullscreen.isTrue),
          color: _ToolbarTheme.labelButtonColor,
          hoverColor: _ToolbarTheme.labelButtonHover,
          label: stateGlobal.fullscreen.isTrue ? '退出全屏' : '全屏',
        ));
  }
}

class _IconMenuButton extends StatefulWidget {
  final String? assetName;
  final Widget? icon;
  final String tooltip;
  final Color color;
  final Color hoverColor;
  final VoidCallback? onPressed;
  final double? hMargin;
  final double? vMargin;
  final bool topLevel;
  final double? width;
  final String? label;
  const _IconMenuButton({
    Key? key,
    this.assetName,
    this.icon,
    required this.tooltip,
    required this.color,
    required this.hoverColor,
    required this.onPressed,
    this.hMargin,
    this.vMargin,
    this.topLevel = true,
    this.width,
    this.label,
  }) : super(key: key);

  @override
  State<_IconMenuButton> createState() => _IconMenuButtonState();
}

class _IconMenuButtonState extends State<_IconMenuButton> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    assert(widget.assetName != null || widget.icon != null);
    final icon = widget.icon ??
        SvgPicture.asset(
          widget.assetName!,
          colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
          width: widget.label == null ? _ToolbarTheme.buttonSize : _ToolbarTheme.labeledIconSize,
          height: widget.label == null ? _ToolbarTheme.buttonSize : _ToolbarTheme.labeledIconSize,
        );
    final inner = widget.label == null
        ? icon
        : Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 2),
              Text(widget.label!,
                  style: const TextStyle(
                      fontSize: _ToolbarTheme.labeledFontSize,
                      color: Colors.white,
                      fontWeight: FontWeight.normal)),
            ],
          );
    var button = SizedBox(
      width: widget.width ??
          (widget.label == null
              ? _ToolbarTheme.buttonSize
              : _ToolbarTheme.labeledButtonWidth),
      height: widget.label == null
          ? _ToolbarTheme.buttonSize
          : _ToolbarTheme.labeledButtonHeight,
      child: MenuItemButton(
          style: ButtonStyle(
              backgroundColor: MaterialStatePropertyAll(Colors.transparent),
              padding: MaterialStatePropertyAll(EdgeInsets.zero),
              overlayColor: MaterialStatePropertyAll(Colors.transparent)),
          onHover: (value) => setState(() {
                hover = value;
              }),
          onPressed: widget.onPressed,
          child: Tooltip(
            message: translate(widget.tooltip),
            child: Material(
                type: MaterialType.transparency,
                child: Ink(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(_ToolbarTheme.iconRadius),
                      color: hover ? widget.hoverColor : widget.color,
                    ),
                    child: inner)),
          )),
    ).marginSymmetric(
        horizontal: widget.hMargin ?? _ToolbarTheme.buttonHMargin,
        vertical: widget.vMargin ?? _ToolbarTheme.buttonVMargin);
    button = Tooltip(
      message: widget.tooltip,
      child: button,
    );
    if (widget.topLevel) {
      return MenuBar(children: [button]);
    } else {
      return button;
    }
  }
}

class _IconSubmenuButton extends StatefulWidget {
  final String tooltip;
  final String? svg;
  final Widget? icon;
  final Color color;
  final Color hoverColor;
  final List<Widget> Function(_IconSubmenuButtonState state) menuChildrenGetter;
  final MenuStyle? menuStyle;
  final FFI? ffi;
  final double? width;
  final String? label;

  _IconSubmenuButton({
    Key? key,
    this.svg,
    this.icon,
    required this.tooltip,
    required this.color,
    required this.hoverColor,
    required this.menuChildrenGetter,
    this.ffi,
    this.menuStyle,
    this.width,
    this.label,
  }) : super(key: key);

  @override
  State<_IconSubmenuButton> createState() => _IconSubmenuButtonState();
}

class _IconSubmenuButtonState extends State<_IconSubmenuButton> {
  bool hover = false;

  @override // discard @protected
  void setState(VoidCallback fn) {
    super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.svg != null || widget.icon != null);
    final icon = widget.icon ??
        SvgPicture.asset(
          widget.svg!,
          colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
          width: widget.label == null ? _ToolbarTheme.buttonSize : _ToolbarTheme.labeledIconSize,
          height: widget.label == null ? _ToolbarTheme.buttonSize : _ToolbarTheme.labeledIconSize,
        );
    final inner = widget.label == null
        ? icon
        : Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 2),
              Text(widget.label!,
                  style: const TextStyle(
                      fontSize: _ToolbarTheme.labeledFontSize,
                      color: Colors.white,
                      fontWeight: FontWeight.normal)),
            ],
          );
    final button = SizedBox(
        width: widget.width ??
            (widget.label == null
                ? _ToolbarTheme.buttonSize
                : _ToolbarTheme.labeledButtonWidth),
        height: widget.label == null
            ? _ToolbarTheme.buttonSize
            : _ToolbarTheme.labeledButtonHeight,
        child: SubmenuButton(
            menuStyle:
                widget.menuStyle ?? _ToolbarTheme.defaultMenuStyle(context),
            style: _ToolbarTheme.defaultMenuButtonStyle,
            onHover: (value) => setState(() {
                  hover = value;
                }),
            child: Tooltip(
                message: translate(widget.tooltip),
                child: Material(
                    type: MaterialType.transparency,
                    child: Ink(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(_ToolbarTheme.iconRadius),
                          color: hover ? widget.hoverColor : widget.color,
                        ),
                        child: inner))),
            menuChildren: widget
                .menuChildrenGetter(this)
                .map((e) => _buildPointerTrackWidget(e, widget.ffi))
                .toList()));
    return MenuBar(children: [
      button.marginSymmetric(
          horizontal: _ToolbarTheme.buttonHMargin,
          vertical: _ToolbarTheme.buttonVMargin)
    ]);
  }
}

class _SubmenuButton extends StatelessWidget {
  final List<Widget> menuChildren;
  final Widget? child;
  final FFI ffi;
  const _SubmenuButton({
    Key? key,
    required this.menuChildren,
    required this.child,
    required this.ffi,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SubmenuButton(
      key: key,
      child: child,
      menuChildren:
          menuChildren.map((e) => _buildPointerTrackWidget(e, ffi)).toList(),
      menuStyle: _ToolbarTheme.defaultMenuStyle(context),
    );
  }
}

class MenuButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? trailingIcon;
  final Widget? child;
  final FFI? ffi;
  MenuButton(
      {Key? key,
      this.onPressed,
      this.trailingIcon,
      required this.child,
      this.ffi})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
        key: key,
        onPressed: onPressed != null
            ? () {
                if (ffi != null) {
                  _menuDismissCallback(ffi!);
                }
                onPressed?.call();
              }
            : null,
        trailingIcon: trailingIcon,
        child: child);
  }
}

class CkbMenuButton extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final Widget? child;
  final FFI? ffi;
  const CkbMenuButton(
      {Key? key,
      required this.value,
      required this.onChanged,
      required this.child,
      this.ffi})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CheckboxMenuButton(
      key: key,
      value: value,
      child: child,
      onChanged: onChanged != null
          ? (bool? value) {
              if (ffi != null) {
                _menuDismissCallback(ffi!);
              }
              onChanged?.call(value);
            }
          : null,
    );
  }
}

class RdoMenuButton<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget? child;
  final FFI? ffi;
  // When true, submenu will be dismissed on activate; when false, it stays open.
  final bool closeOnActivate;
  const RdoMenuButton({
    Key? key,
    required this.value,
    required this.groupValue,
    required this.child,
    this.ffi,
    this.onChanged,
    this.closeOnActivate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RadioMenuButton(
      value: value,
      groupValue: groupValue,
      child: child,
      closeOnActivate: closeOnActivate,
      onChanged: onChanged != null
          ? (T? value) {
              if (ffi != null && closeOnActivate) {
                _menuDismissCallback(ffi!);
              }
              onChanged?.call(value);
            }
          : null,
    );
  }
}

class _DraggableShowHide extends StatefulWidget {
  final String id;
  final SessionID sessionId;
  final RxDouble fractionX;
  final RxBool dragging;
  final ToolbarState toolbarState;
  final BorderRadius borderRadius;

  final Function(bool) setFullscreen;
  final Function() setMinimize;

  const _DraggableShowHide({
    Key? key,
    required this.id,
    required this.sessionId,
    required this.fractionX,
    required this.dragging,
    required this.toolbarState,
    required this.setFullscreen,
    required this.setMinimize,
    required this.borderRadius,
  }) : super(key: key);

  @override
  State<_DraggableShowHide> createState() => _DraggableShowHideState();
}

class _DraggableShowHideState extends State<_DraggableShowHide> {
  Offset position = Offset.zero;
  Size size = Size.zero;
  double left = 0.0;
  double right = 1.0;

  RxBool get collapse => widget.toolbarState.collapse;

  @override
  initState() {
    super.initState();

    final confLeft = double.tryParse(
        bind.mainGetLocalOption(key: kOptionRemoteMenubarDragLeft));
    if (confLeft == null) {
      bind.mainSetLocalOption(
          key: kOptionRemoteMenubarDragLeft, value: left.toString());
    } else {
      left = confLeft;
    }
    final confRight = double.tryParse(
        bind.mainGetLocalOption(key: kOptionRemoteMenubarDragRight));
    if (confRight == null) {
      bind.mainSetLocalOption(
          key: kOptionRemoteMenubarDragRight, value: right.toString());
    } else {
      right = confRight;
    }
  }

  Widget _buildDraggable(BuildContext context) {
    return Draggable(
      axis: Axis.horizontal,
      child: Icon(
        Icons.drag_indicator,
        size: 20,
        color: MyTheme.color(context).drag_indicator,
      ),
      feedback: widget,
      onDragStarted: (() {
        final RenderObject? renderObj = context.findRenderObject();
        if (renderObj != null) {
          final RenderBox renderBox = renderObj as RenderBox;
          size = renderBox.size;
          position = renderBox.localToGlobal(Offset.zero);
        }
        widget.dragging.value = true;
      }),
      onDragEnd: (details) {
        final mediaSize = MediaQueryData.fromView(View.of(context)).size;
        widget.fractionX.value +=
            (details.offset.dx - position.dx) / (mediaSize.width - size.width);
        if (widget.fractionX.value < left) {
          widget.fractionX.value = left;
        }
        if (widget.fractionX.value > right) {
          widget.fractionX.value = right;
        }
        bind.sessionPeerOption(
          sessionId: widget.sessionId,
          name: 'remote-menubar-drag-x',
          value: widget.fractionX.value.toString(),
        );
        widget.dragging.value = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ButtonStyle(
      minimumSize: MaterialStateProperty.all(const Size(0, 0)),
      padding: MaterialStateProperty.all(EdgeInsets.zero),
    );
    final isFullscreen = stateGlobal.fullscreen;
    const double iconSize = 20;

    buttonWrapper(VoidCallback? onPressed, Widget child,
        {Color hoverColor = _ToolbarTheme.blueColor}) {
      final bgColor = buttonStyle.backgroundColor?.resolve({});
      return TextButton(
        onPressed: onPressed,
        child: child,
        style: buttonStyle.copyWith(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.hovered)) {
              return (bgColor ?? hoverColor).withOpacity(0.15);
            }
            return bgColor;
          }),
        ),
      );
    }

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDraggable(context),
        Obx(() => buttonWrapper(
              () {
                widget.setFullscreen(!isFullscreen.value);
              },
              Tooltip(
                message: translate(
                    isFullscreen.isTrue ? 'Exit Fullscreen' : 'Fullscreen'),
                child: Icon(
                  isFullscreen.isTrue
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  size: iconSize,
                ),
              ),
            )),
        if (!isMacOS && !isWebDesktop)
          Obx(() => Offstage(
                offstage: isFullscreen.isFalse,
                child: buttonWrapper(
                  widget.setMinimize,
                  Tooltip(
                    message: translate('Minimize'),
                    child: Icon(
                      Icons.remove,
                      size: iconSize,
                    ),
                  ),
                ),
              )),
        buttonWrapper(
          () => setState(() {
            widget.toolbarState.switchCollapse(widget.sessionId);
          }),
          Obx((() => Tooltip(
                message: translate(
                    collapse.isFalse ? 'Hide Toolbar' : 'Show Toolbar'),
                child: Icon(
                  collapse.isFalse ? Icons.expand_less : Icons.expand_more,
                  size: iconSize,
                ),
              ))),
        ),
        if (isWebDesktop)
          Obx(() {
            if (collapse.isFalse) {
              return Offstage();
            } else {
              return buttonWrapper(
                () => closeConnection(id: widget.id),
                Tooltip(
                  message: translate('Close'),
                  child: Icon(
                    Icons.close,
                    size: iconSize,
                    color: _ToolbarTheme.redColor,
                  ),
                ),
                hoverColor: _ToolbarTheme.redColor,
              ).paddingOnly(left: iconSize / 2);
            }
          })
      ],
    );
    return TextButtonTheme(
      data: TextButtonThemeData(style: buttonStyle),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .menuBarTheme
              .style
              ?.backgroundColor
              ?.resolve(MaterialState.values.toSet()),
          border: Border.all(
            color: _ToolbarTheme.borderColor(context),
            width: 1,
          ),
          borderRadius: widget.borderRadius,
        ),
        child: SizedBox(
          height: 20,
          child: child,
        ),
      ),
    );
  }
}
