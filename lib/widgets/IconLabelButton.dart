import 'dart:math' as math;

import 'package:flutter/material.dart';

const double _kMinButtonSize = kMinInteractiveDimension;

class IconLabelButton extends IconButton {
  /// Creates an icon button.
  ///
  /// Icon buttons are commonly used in the [AppBar.actions] field, but they can
  /// be used in many other places as well.
  ///
  /// Requires one of its ancestors to be a [Material] widget.
  ///
  /// The [iconSize], [padding], [autofocus], and [alignment] arguments must not
  /// be null (though they each have default values).
  ///
  /// The [icon] argument must be specified, and is typically either an [Icon]
  /// or an [ImageIcon].
  const IconLabelButton({
    Key key,
    this.iconSize = 24.0,
    this.padding = const EdgeInsets.all(8.0),
    this.alignment = Alignment.center,
    @required this.icon,
    @required this.label,
    this.labelSize = 16.0,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    @required this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
  })  : assert(iconSize != null),
        assert(padding != null),
        assert(alignment != null),
        assert(autofocus != null),
        assert(icon != null),
        super(key: key, icon: icon, onPressed: onPressed);

  /// The size of the icon inside the button.
  ///
  /// This property must not be null. It defaults to 24.0.
  ///
  /// The size given here is passed down to the widget in the [icon] property
  /// via an [IconTheme]. Setting the size here instead of in, for example, the
  /// [Icon.size] property allows the [IconButton] to size the splash area to
  /// fit the [Icon]. If you were to set the size of the [Icon] using
  /// [Icon.size] instead, then the [IconButton] would default to 24.0 and then
  /// the [Icon] itself would likely get clipped.
  final double iconSize;

  /// The padding around the button's icon. The entire padded icon will react
  /// to input gestures.
  ///
  /// This property must not be null. It defaults to 8.0 padding on all sides.
  final EdgeInsetsGeometry padding;

  /// Defines how the icon is positioned within the IconButton.
  ///
  /// This property must not be null. It defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// The icon to display inside the button.
  ///
  /// The [Icon.size] and [Icon.color] of the icon is configured automatically
  /// based on the [iconSize] and [color] properties of _this_ widget using an
  /// [IconTheme] and therefore should not be explicitly given in the icon
  /// widget.
  ///
  /// This property must not be null.
  ///
  /// See [Icon], [ImageIcon].
  final Widget icon;

  final String label;

  final double labelSize;

  /// The color for the button's icon when it has the input focus.
  ///
  /// Defaults to [ThemeData.focusColor] of the ambient theme.
  final Color focusColor;

  /// The color for the button's icon when a pointer is hovering over it.
  ///
  /// Defaults to [ThemeData.hoverColor] of the ambient theme.
  final Color hoverColor;

  /// The color to use for the icon inside the button, if the icon is enabled.
  /// Defaults to leaving this up to the [icon] widget.
  ///
  /// The icon is enabled if [onPressed] is not null.
  ///
  /// See also [disabledColor].
  ///
  /// ```dart
  /// IconButton(
  ///   color: Colors.blue,
  ///   onPressed: _handleTap,
  ///   icon: Icons.widgets,
  /// )
  /// ```
  final Color color;

  /// The primary color of the button when the button is in the down (pressed) state.
  /// The splash is represented as a circular overlay that appears above the
  /// [highlightColor] overlay. The splash overlay has a center point that matches
  /// the hit point of the user touch event. The splash overlay will expand to
  /// fill the button area if the touch is held for long enough time. If the splash
  /// color has transparency then the highlight and button color will show through.
  ///
  /// Defaults to the Theme's splash color, [ThemeData.splashColor].
  final Color splashColor;

  /// The secondary color of the button when the button is in the down (pressed)
  /// state. The highlight color is represented as a solid color that is overlaid over the
  /// button color (if any). If the highlight color has transparency, the button color
  /// will show through. The highlight fades in quickly as the button is held down.
  ///
  /// Defaults to the Theme's highlight color, [ThemeData.highlightColor].
  final Color highlightColor;

  /// The color to use for the icon inside the button, if the icon is disabled.
  /// Defaults to the [ThemeData.disabledColor] of the current [Theme].
  ///
  /// The icon is disabled if [onPressed] is null.
  ///
  /// See also [color].
  final Color disabledColor;

  /// The callback that is called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback onPressed;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// Text that describes the action that will occur when the button is pressed.
  ///
  /// This text is displayed when the user long-presses on the button and is
  /// used for accessibility.
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    Color currentColor;
    if (onPressed != null)
      currentColor = color;
    else
      currentColor = disabledColor ?? Theme.of(context).disabledColor;

    Widget result = ConstrainedBox(
      constraints: const BoxConstraints(
          minWidth: _kMinButtonSize, minHeight: _kMinButtonSize),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: iconSize,
              width: iconSize,
              child: Align(
                alignment: alignment,
                child: IconTheme.merge(
                  data: IconThemeData(
                    size: iconSize,
                    color: currentColor,
                  ),
                  child: icon,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: currentColor,
                fontSize: labelSize,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
            ),
          ],
        ),
      ),
    );

    if (tooltip != null) {
      result = Tooltip(
        message: tooltip,
        child: result,
      );
    }

    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Focus(
        focusNode: focusNode,
        autofocus: autofocus,
        child: InkResponse(
          onTap: onPressed,
          child: result,
          focusColor: focusColor ?? Theme.of(context).focusColor,
          hoverColor: hoverColor ?? Theme.of(context).hoverColor,
          highlightColor: highlightColor ?? Theme.of(context).highlightColor,
          splashColor: splashColor ?? Theme.of(context).splashColor,
          radius: math.max(
            Material.defaultSplashRadius,
            (iconSize + math.min(padding.horizontal, padding.vertical)) * 0.7,
            // x 0.5 for diameter -> radius and + 40% overflow derived from other Material apps.
          ),
        ),
      ),
    );
  }
}
