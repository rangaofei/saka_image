import 'package:flutter/material.dart';
import 'package:saka_image/saka_image.dart';
import 'package:saka_image/src/image_stream.dart';
import 'package:saka_image/src/image_type.dart';
import 'package:saka_image/src/log.dart';

class SakaAnimateImage extends StatefulWidget {
  final SakaImageProvider image;
  final Duration outDuration;
  final Curve outCurve;
  final Duration inDuration;
  final Curve inCurve;
  final double width;
  final double height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final bool matchTextDirection;

  SakaAnimateImage({
    Key key,
    @required this.image,
    this.outDuration = const Duration(milliseconds: 300),
    this.outCurve = Curves.easeOut,
    this.inDuration = const Duration(milliseconds: 700),
    this.inCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
  })  : assert(image != null),
        assert(outDuration != null),
        assert(outCurve != null),
        assert(inDuration != null),
        assert(inCurve != null),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SakaAnimateState();
  }
}

enum ImagePhase {
  start,

  /// Waiting for the target image to load.
  waiting,

  /// Fading out previous image.
  animateOutStart,
  animateOuting,

  /// Fading in new image.
  animateInStart,
  animateIning,

  /// Fade-in complete.
  completed,
}

class _SakaAnimateState extends State<SakaAnimateImage>
    with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;
  ImageInfo _imageInfo;
  SakaImageStream _imageStream;
  bool _isListeningToStream = false;

  ImagePhase _phase = ImagePhase.start;

  ImagePhase get phase => _phase;

  @override
  void initState() {
    _controller = AnimationController(
      value: 1.0,
      vsync: this,
    );
    _controller.addListener(() {
      setState(() {
        // Trigger rebuild to update opacity value.
      });
    });
    _controller.addStatusListener((AnimationStatus status) {
      SakaLog.log("AnimationStatus$status");
      _updatePhase();
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _resolveImage();
    _listenToStream();
    super.didChangeDependencies();
  }

  @override
  void reassemble() {
    _resolveImage();
    super.reassemble();
  }

  @override
  void didUpdateWidget(SakaAnimateImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) _resolveImage();
  }

  void _resolveImage() {
    if (_phase == ImagePhase.start) _updatePhase();
    final SakaImageStream newStream = widget.image.resolveStream(
        createLocalImageConfiguration(context,
            size: widget.width != null && widget.height != null
                ? Size(widget.width, widget.height)
                : null));
    assert(newStream != null);
    _updateSourceStream(newStream);
  }

  void _updateSourceStream(SakaImageStream newStream) {
    if (_imageStream?.key == newStream?.key) {
      SakaLog.log("_updateSourceStream and is the same key");
      return;
    }

    if (_isListeningToStream) _imageStream.removeListener(_handleImageChanged);

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
    SakaLog.log("handleImageTypeChanged.type = ${type}");
    switch (type) {
      case ImageType.PRE_PLACE_HOLDER:
        _phase = ImagePhase.waiting;
        break;
      case ImageType.IN_DURATION:
        _phase = ImagePhase.animateInStart;
        break;
      case ImageType.CORRECT_IMAGE:
//        _phase = ImagePhase.animateOutStart;
        break;
      case ImageType.ERR_PLACE_HOLDER:
        _phase = ImagePhase.animateInStart;
        break;
      case ImageType.OUT_DURATION:
        _phase = ImagePhase.animateOutStart;
        break;
    }
    _updatePhase();
  }

  void _updatePhase() {
    setState(() {
      switch (_phase) {
        case ImagePhase.start:
          SakaLog.log("_phase start");
//          if (_imageInfo != null)
//            _phase = ImagePhase.completed;
//          else
//            _phase = ImagePhase.waiting;
          break;
        case ImagePhase.waiting:
          SakaLog.log("_phase waiting");
          break;
        case ImagePhase.animateOutStart:
          SakaLog.log("_phase fadeout");
          if (_imageInfo != null) {
            // Received image data. Begin placeholder fade-out.
            _controller.duration = widget.outDuration;
            _animation = CurvedAnimation(
              parent: _controller,
              curve: widget.outCurve,
            );
            SakaLog.log("reverse");
            _phase = ImagePhase.animateOuting;
            _controller.reverse(from: 1.0);
          }
          break;
        case ImagePhase.animateOuting:
          break;
        case ImagePhase.animateInStart:
          SakaLog.log("_phase fadein");
          if (_controller.status == AnimationStatus.dismissed) {
            // Done fading out placeholder. Begin target image fade-in.
            _controller.duration = widget.inDuration;
            _animation = CurvedAnimation(
              parent: _controller,
              curve: widget.inCurve,
            );
            SakaLog.log("forward");
            _phase = ImagePhase.animateIning;
            _controller.forward(from: 0.0);
          }
          if (_controller.status == AnimationStatus.completed) {
            // Done finding in new image.
            _phase = ImagePhase.completed;
          }
          break;
        case ImagePhase.animateIning:
          break;
        case ImagePhase.completed:
          // Nothing to do.
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ImageInfo imageInfo = _imageInfo;
    return RawImage(
      image: imageInfo?.image,
      width: widget.width,
      height: widget.height,
      scale: imageInfo?.scale ?? 1.0,
      color: Color.fromRGBO(255, 255, 255, _animation?.value ?? 1.0),
      colorBlendMode: BlendMode.modulate,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      matchTextDirection: widget.matchTextDirection,
    );
  }

  @override
  void dispose() {
    _stopListeningToStream();
    _controller.dispose();
    super.dispose();
  }
}
