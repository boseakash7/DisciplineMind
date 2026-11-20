import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared motion language for the app.
///
/// Everything that moves should pull its duration and curve from here rather
/// than inventing its own, so the app feels like one product instead of a set
/// of screens that each animate slightly differently.
///
/// Three rules this encodes:
/// 1. Motion is short. Anything over ~300ms starts to feel slow on a phone.
/// 2. Things enter decelerating ([emphasised]) and leave quickly ([exit]).
/// 3. Motion is never required to understand the UI — with the OS
///    "reduce motion" setting on, every helper here degrades to no animation.
abstract final class AppMotion {
  /// Button press / small state flips.
  static const Duration fast = Duration(milliseconds: 120);

  /// Default for most transitions: dialogs, sheets, reveals.
  static const Duration normal = Duration(milliseconds: 240);

  /// Larger surfaces, or entrances that stagger.
  static const Duration slow = Duration(milliseconds: 380);

  /// Bottom sheet entrance. Longer than [normal] because a sheet travels the
  /// height of itself rather than fading in place.
  static const Duration sheetIn = Duration(milliseconds: 320);

  /// Bottom sheet dismissal. Shorter than the entrance so closing feels
  /// immediate rather than reluctant.
  static const Duration sheetOut = Duration(milliseconds: 220);

  /// Entering: decelerate into place.
  static const Curve emphasised = Curves.easeOutCubic;

  /// Leaving: get out of the way without lingering.
  static const Curve exit = Curves.easeInCubic;

  /// Opacity-only changes.
  static const Curve fade = Curves.easeOut;

  /// How far a dialog rises as it fades in, in logical pixels.
  static const double dialogRise = 12;

  /// Scale a surface starts at before settling to 1.0.
  static const double dialogScale = 0.96;

  /// Scale a pressed control shrinks to. Deliberately subtle: the user should
  /// feel the press, not watch an animation.
  static const double pressScale = 0.97;

  /// True when the OS asks for reduced motion. Honour this everywhere.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// [duration], or zero when the user has asked for reduced motion.
  static Duration duration(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}

// ---------------------------------------------------------------- pressable

/// Wraps any widget so it scales down while pressed.
///
/// The press is tracked with a [Listener], not a `GestureDetector`, so it does
/// not enter the gesture arena. That means it composes with whatever the child
/// already does: an existing `InkWell` keeps its ripple and still receives the
/// tap, and this only adds the squeeze on top.
///
/// Pass [onTap] only when the child has no tap handling of its own.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = AppMotion.pressScale,
    this.haptics = true,
    this.enabled = true,
  });

  final Widget child;

  /// Only set this when the child does not already handle taps.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Scale at full press. Lower means a more pronounced squeeze.
  final double scale;

  /// Light impact on press down. Turn off for controls that fire rapidly.
  final bool haptics;

  /// When false the child renders normally and does not animate.
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  // Created eagerly. A lazy `late final` would be constructed by the first
  // read, and for a button that is never pressed that read is dispose() -
  // building a Ticker against a deactivated element.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
      reverseDuration: AppMotion.fast,
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    if (!widget.enabled) return;
    if (widget.haptics) HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _release() {
    if (!_controller.isDismissed) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = widget.child;

    // Own the tap only when asked to; otherwise the child keeps handling it.
    if (widget.onTap != null || widget.onLongPress != null) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        onLongPress: widget.enabled ? widget.onLongPress : null,
        child: result,
      );
    }

    if (!widget.enabled || AppMotion.reduced(context)) return result;

    return Listener(
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: 1 - ((1 - widget.scale) * _controller.value),
          alignment: Alignment.center,
          child: child,
        ),
        child: result,
      ),
    );
  }
}

// ------------------------------------------------------------------ reveals

/// Fade + small rise, for a single element appearing in place.
///
/// Unlike a staggered list entrance this re-runs whenever [triggerKey]
/// changes, so it can announce a newly arrived message or a swapped state.
class AppFadeSlideIn extends StatefulWidget {
  const AppFadeSlideIn({
    super.key,
    required this.child,
    this.duration = AppMotion.normal,
    this.delay = Duration.zero,
    this.offsetY = 10,
    this.triggerKey,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;

  /// Distance in logical pixels the child rises from.
  final double offsetY;

  /// Change this to replay the animation.
  final Object? triggerKey;

  @override
  State<AppFadeSlideIn> createState() => _AppFadeSlideInState();
}

class _AppFadeSlideInState extends State<AppFadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _start();
  }

  @override
  void didUpdateWidget(covariant AppFadeSlideIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.triggerKey != widget.triggerKey) {
      _controller.value = 0;
      _start();
    }
  }

  void _start() {
    if (widget.delay == Duration.zero) {
      _controller.forward();
      return;
    }
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;

    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.emphasised,
    );
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - curved.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Cross-fades and resizes between states without a jump.
///
/// Use where a block's content swaps — a button turning into a confirmation
/// row, a value replacing a skeleton.
class AppSwitcher extends StatelessWidget {
  const AppSwitcher({
    super.key,
    required this.child,
    this.duration = AppMotion.normal,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final Duration duration;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.duration(context, duration),
      curve: AppMotion.emphasised,
      alignment: alignment,
      child: AnimatedSwitcher(
        duration: AppMotion.duration(context, duration),
        switchInCurve: AppMotion.emphasised,
        switchOutCurve: AppMotion.exit,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: alignment,
          children: <Widget>[...previousChildren, ?currentChild],
        ),
        child: child,
      ),
    );
  }
}

// ------------------------------------------------------------------ dialogs

/// Fade + subtle scale + rise. The standard way to present a dialog.
///
/// Replaces a plain `showDialog`, which pops in abruptly.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color barrierColor = Colors.black54,
  Duration duration = AppMotion.normal,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor,
    transitionDuration: AppMotion.duration(context, duration),
    pageBuilder: (dialogContext, animation, secondaryAnimation) =>
        builder(dialogContext),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        AppDialogTransition(animation: animation, child: child),
  );
}

/// The transition [showAppDialog] uses. Exposed so routes that build their own
/// `showGeneralDialog` can match it exactly.
class AppDialogTransition extends StatelessWidget {
  const AppDialogTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasised,
      reverseCurve: AppMotion.exit,
    );

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: AppMotion.fade,
        reverseCurve: AppMotion.exit,
      ),
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, inner) => Transform.translate(
          offset: Offset(0, AppMotion.dialogRise * (1 - curved.value)),
          child: Transform.scale(
            scale:
                AppMotion.dialogScale +
                ((1 - AppMotion.dialogScale) * curved.value),
            child: inner,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Bottom sheet that slides up with the app's motion language.
///
/// Flutter's default sheet uses a linear-ish `decelerate` over 250ms. A sheet
/// travels much further than a dialog, so it gets a slightly longer entrance
/// on [AppMotion.emphasised] to read as deliberate rather than snapped, and a
/// shorter exit so dismissing still feels immediate.
Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  // Matches showModalBottomSheet's own default, so swapping this in never
  // changes an existing sheet's height behaviour.
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = false,
  Color backgroundColor = Colors.transparent,
  Color barrierColor = Colors.black54,
  ShapeBorder? shape,
  double? elevation,
}) {
  final reduced = AppMotion.reduced(context);

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: backgroundColor,
    barrierColor: barrierColor,
    shape: shape,
    elevation: elevation,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: useSafeArea,
    sheetAnimationStyle: AnimationStyle(
      curve: reduced ? Curves.linear : AppMotion.emphasised,
      duration: reduced ? Duration.zero : AppMotion.sheetIn,
      reverseCurve: reduced ? Curves.linear : AppMotion.exit,
      reverseDuration: reduced ? Duration.zero : AppMotion.sheetOut,
    ),
    builder: builder,
  );
}
