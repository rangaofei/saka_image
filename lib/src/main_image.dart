import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:saka_image/src/image_provider.dart';
import 'package:saka_image/src/image_type.dart';
import 'package:saka_image/src/log.dart';

import 'image_stream.dart';

class SakaImage extends StatefulWidget {
  final SakaImageProvider _image;
  final double width;
  final double height;
  final Color color;
  final FilterQuality filterQuality;
  final BlendMode colorBlendMode;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final Rect centerSlice;
  final bool matchTextDirection;
  final bool gaplessPlayback;
  final String semanticLabel;
  final bool excludeFromSemantics;

  SakaImage.urlWithPlaceHolder(
    String url, {
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.semanticLabel,
    this.excludeFromSemantics = true,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.low,
    errPlaceHolder,
    prePlaceHolder,
    preDuration,
  }) : _image = SakaNetworkImage(url,
            prePlaceHolderPath: prePlaceHolder,
            errPlaceHolderPath: errPlaceHolder,
            duration: preDuration);

  SakaImage.assetImage(
    String url, {
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.semanticLabel,
    this.excludeFromSemantics = true,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.low,
    timeScale,
  }) : _image = SakaAssetImage(url, timeScale: timeScale??1.0);

  const SakaImage(
    this._image, {
    Key key,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.low,
  })  : assert(_image != null),
        assert(alignment != null),
        assert(repeat != null),
        assert(filterQuality != null),
        assert(matchTextDirection != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SakaImageState();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ImageProvider>('image', _image));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties
        .add(DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(EnumProperty<BlendMode>('colorBlendMode', colorBlendMode,
        defaultValue: null));
    properties.add(EnumProperty<BoxFit>('fit', fit, defaultValue: null));
    properties.add(DiagnosticsProperty<AlignmentGeometry>(
        'alignment', alignment,
        defaultValue: null));
    properties.add(EnumProperty<ImageRepeat>('repeat', repeat,
        defaultValue: ImageRepeat.noRepeat));
    properties.add(DiagnosticsProperty<Rect>('centerSlice', centerSlice,
        defaultValue: null));
    properties.add(FlagProperty('matchTextDirection',
        value: matchTextDirection, ifTrue: 'match text direction'));
    properties.add(
        StringProperty('semanticLabel', semanticLabel, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>(
        'this.excludeFromSemantics', excludeFromSemantics));
    properties.add(EnumProperty<FilterQuality>('filterQuality', filterQuality));
  }
}

class _SakaImageState extends State<SakaImage> {
  SakaImageStream _imageStream;
  ImageInfo _imageInfo;
  bool _isListeningToStream = false;
  bool _invertColors;

  @override
  void didChangeDependencies() {
    _invertColors = MediaQuery.of(context, nullOk: true)?.invertColors ??
        SemanticsBinding.instance.accessibilityFeatures.invertColors;
    _resolveImage();

    if (TickerMode.of(context))
      _listenToStream();
    else
      _stopListeningToStream();

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(SakaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._image != oldWidget._image) _resolveImage();
  }

  @override
  void reassemble() {
    _resolveImage();
    super.reassemble();
  }

  void _resolveImage() {
    final SakaImageStream newStream = widget._image.resolveStream(
        createLocalImageConfiguration(context,
            size: widget.width != null && widget.height != null
                ? Size(widget.width, widget.height)
                : null));
    assert(newStream != null);
    _updateSourceStream(newStream);
  }

  void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
    if (imageInfo.image.height == imageInfo.image.width &&
        imageInfo.image.width == 1) {
      return;
    }
    setState(() {
      _imageInfo = imageInfo;
    });
  }

  void handleImageTypeChanged(ImageType type) {
    SakaLog.log("this type is $type");
  }

  void _updateSourceStream(SakaImageStream newStream) {
    if (_imageStream?.key == newStream?.key) {
      SakaLog.log("_updateSourceStream and is the same key");
      return;
    }

    if (_isListeningToStream) _imageStream.removeListener(_handleImageChanged);

    if (!widget.gaplessPlayback)
      setState(() {
        _imageInfo = null;
      });

    _imageStream = newStream;
    if (_isListeningToStream)
      _imageStream.addListener(
        _handleImageChanged,
        onChange: handleImageTypeChanged,
      );
  }

  void _listenToStream() {
    if (_isListeningToStream) return;
    _imageStream.addListener(_handleImageChanged,
        onChange: handleImageTypeChanged);
    _isListeningToStream = true;
  }

  void _stopListeningToStream() {
    if (!_isListeningToStream) return;
    _imageStream.removeListener(_handleImageChanged);
    _isListeningToStream = false;
  }

  @override
  void dispose() {
    assert(_imageStream != null);
    _stopListeningToStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RawImage image = RawImage(
      image: _imageInfo?.image,
      width: widget.width,
      height: widget.height,
      scale: _imageInfo?.scale ?? 1.0,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      centerSlice: widget.centerSlice,
      matchTextDirection: widget.matchTextDirection,
      invertColors: _invertColors,
      filterQuality: widget.filterQuality,
    );
    if (widget.excludeFromSemantics) return image;
    return Semantics(
      container: widget.semanticLabel != null,
      image: true,
      label: widget.semanticLabel == null ? '' : widget.semanticLabel,
      child: image,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description
        .add(DiagnosticsProperty<SakaImageStream>('stream', _imageStream));
    description.add(DiagnosticsProperty<ImageInfo>('pixels', _imageInfo));
  }
}
