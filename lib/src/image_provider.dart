import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui show Codec;
import 'dart:ui' show hashValues;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:saka_image/src/image_stream.dart';
import 'package:saka_image/src/constant.dart';
import 'package:saka_image/src/image_type.dart';
import 'package:saka_image/src/log.dart';

abstract class SakaBaseImageProvider<T>
    extends ImageProvider<SakaBaseImageProvider> {
  final double scale;

  SakaBaseImageProvider({this.scale = 1.0});

  SakaImageStream resolveStream(ImageConfiguration configuration) {
    assert(configuration != null);
    final SakaImageStream stream = SakaImageStream();
    SakaBaseImageProvider obtainedKey;
    obtainKey(configuration).then<void>((SakaBaseImageProvider key) {
      obtainedKey = key;
      stream.setCompleter(PaintingBinding.instance.imageCache
          .putIfAbsent(key, () => load(key)));
    }).catchError((dynamic exception, StackTrace stack) async {
      FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context: 'while resolving an image',
          silent: true,
          // could be a network error or whatnot
          informationCollector: (StringBuffer information) {
            information.writeln('Image provider: $this');
            information.writeln('Image configuration: $configuration');
            if (obtainedKey != null)
              information.writeln('Image key: $obtainedKey');
          }));
      return null;
    });
    return stream;
  }

  @override
  Future<SakaBaseImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<SakaBaseImageProvider>(this);
  }
}

class SakaSpeedImage extends SakaBaseImageProvider<SakaSpeedImage> {
  final String imagePath;
  final double timeScale;

  SakaSpeedImage(this.imagePath, {scale, this.timeScale})
      : assert(imagePath != null),
        assert(scale != 0),
        assert(timeScale != 0),
        super(scale: scale);

  @override
  ImageStreamCompleter load(SakaBaseImageProvider key) {
    return SakaImageStreamCompleter(
        codec: _loadAsync(key),
        timeScale: timeScale,
        scale: key.scale,
        informationCollector: (StringBuffer information) {
          information.writeln('Image provider: $this');
          information.write('Image key: $key');
        });
  }

  Future<ComposeImageInfo> _loadAsync(SakaSpeedImage key) async {
    assert(key == this);
    var byteData = await rootBundle.load(imagePath);
    var imgList = byteData.buffer.asUint8List();
    return ComposeImageInfo(
        await PaintingBinding.instance.instantiateImageCodec(imgList),
        ImageType.CORRECT_IMAGE);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final SakaSpeedImage typedOther = other;
    return imagePath == typedOther.imagePath &&
        scale == typedOther.scale &&
        timeScale == typedOther.timeScale;
  }

  @override
  int get hashCode => hashValues(imagePath, scale, timeScale);

  @override
  String toString() =>
      '$runtimeType("$imagePath", scale: $scale,timeScale: $timeScale)';
}

abstract class SakaBaseComposeImage
    extends SakaBaseImageProvider<SakaBaseComposeImage> {
  final String url;
  final String prePlaceHolderPath;
  final double scale;
  Duration duration;
  Duration outDuration;
  Duration inDuration;
  DateTime _preLoadDuration;

  SakaBaseComposeImage(this.url,
      {this.prePlaceHolderPath,
      this.duration,
      this.scale = 1.0,
      this.outDuration = Duration.zero,
      this.inDuration = Duration.zero})
      : assert(url != null),
        assert(scale != null);

  @override
  ImageStreamCompleter load(SakaBaseImageProvider key) {
    return SakaComposeImageStreamCompleter(
        prePlaceHolderCodec: _loadPreAsync(key),
        codec: _loadAsync(key),
        scale: key.scale,
        inDuration: inDuration,
        outDuration: outDuration,
        informationCollector: (StringBuffer information) {
          information.writeln('Image provider: $this');
          information.write('Image key: $key');
        });
  }

  Future<ui.Codec> _getDelayResult(DateTime startTime, Uint8List data) async {
    ui.Codec result =
        await PaintingBinding.instance.instantiateImageCodec(data);
    var stopTime = DateTime.now();
    SakaLog.log(
        "loading used time :${stopTime.difference(startTime).toString()}");
    duration = duration - stopTime.difference(_preLoadDuration);
    SakaLog.log("duration=${duration.toString()}");
    return Future.delayed(
      (duration ?? Duration(seconds: 0)),
      () => result,
    );
  }

  @protected
  Future<ComposeImageInfo> _loadPreAsync(SakaNetworkImage key);

  @protected
  Future<ComposeImageInfo> _loadAsync(SakaNetworkImage key);
}

class SakaAssetImage extends SakaBaseComposeImage {
  SakaAssetImage({
    @required String url,
    String prePlaceHolderPath,
    Duration duration,
    double scale = 1.0,
  })  : assert(url != null),
        assert(scale != null),
        super(url,
            prePlaceHolderPath: prePlaceHolderPath,
            duration: duration,
            scale: scale);

  @override
  Future<ComposeImageInfo> _loadAsync(SakaNetworkImage key) async {
    assert(key == this);
    var startTime = DateTime.now();

    final ByteData bytes = await rootBundle.load(url);
    final Uint8List data = bytes.buffer.asUint8List();
    return ComposeImageInfo(
        await _getDelayResult(startTime, data), ImageType.CORRECT_IMAGE);
  }

  @override
  Future<ComposeImageInfo> _loadPreAsync(SakaNetworkImage key) async {
    assert(key == this);
    if (prePlaceHolderPath == null) {
      return null;
    }

    var byteData = await rootBundle.load(prePlaceHolderPath);
    var imgList = byteData.buffer.asUint8List();
    ui.Codec result =
        await PaintingBinding.instance.instantiateImageCodec(imgList);
    _preLoadDuration = DateTime.now();
    return ComposeImageInfo(result, ImageType.PRE_PLACE_HOLDER);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final SakaNetworkImage typedOther = other;
    return url == typedOther.url && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}

class SakaNetworkImage extends SakaBaseComposeImage {
  // must be an assets path
  final String errPlaceHolderPath;
  final Map<String, String> headers;

  SakaNetworkImage({
    @required String url,
    String prePlaceHolderPath,
    this.errPlaceHolderPath,
    Duration duration,
    double scale = 1.0,
    this.headers,
  })  : assert(url != null),
        assert(scale != null),
        super(url,
            prePlaceHolderPath: prePlaceHolderPath,
            duration: duration,
            scale: scale);

  static final HttpClient _httpClient = HttpClient();

  @override
  Future<ComposeImageInfo> _loadAsync(SakaNetworkImage key) async {
    assert(key == this);
    var startTime = DateTime.now();
    final Uri resolved = Uri.base.resolve(key.url);
    try {
      final HttpClientRequest request = await _httpClient.getUrl(resolved);
      headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        SakaLog.log("http url error");
        return ComposeImageInfo(
            await _getErrorImage(startTime), ImageType.ERR_PLACE_HOLDER);
      }
      final Uint8List bytes =
          await consolidateHttpClientResponseBytes(response);
      if (bytes.lengthInBytes == 0) {
        SakaLog.log("url get bytes is not correct");
        return ComposeImageInfo(
            await _getErrorImage(
              startTime,
            ),
            ImageType.ERR_PLACE_HOLDER);
      }
      return ComposeImageInfo(
          await _getDelayResult(startTime, bytes), ImageType.CORRECT_IMAGE);
    } catch (e) {
      SakaLog.log(e.toString());
      return ComposeImageInfo(
          await _getErrorImage(startTime), ImageType.ERR_PLACE_HOLDER);
    }
  }

  @override
  Future<ComposeImageInfo> _loadPreAsync(SakaNetworkImage key) async {
    assert(key == this);
    if (prePlaceHolderPath == null) {
      return null;
    }

    var byteData = await rootBundle.load(prePlaceHolderPath);
    var imgList = byteData.buffer.asUint8List();
    ui.Codec result =
        await PaintingBinding.instance.instantiateImageCodec(imgList);
    _preLoadDuration = DateTime.now();
    return ComposeImageInfo(result, ImageType.PRE_PLACE_HOLDER);
  }

  Future<ui.Codec> _getErrorImage(DateTime startTime) async {
    if (errPlaceHolderPath == null) {
      return _getDelayResult(startTime, Uint8List.fromList(Constant.emptyPng));
    }
    try {
      var byteData = await rootBundle.load(errPlaceHolderPath);
      var imgList = byteData.buffer.asUint8List();
      return _getDelayResult(startTime, imgList);
    } catch (e) {
      SakaLog.log("$errPlaceHolderPath::${e.toString()}");
      return _getDelayResult(startTime, Uint8List.fromList(Constant.emptyPng));
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final SakaNetworkImage typedOther = other;
    return url == typedOther.url && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}
