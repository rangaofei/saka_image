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

abstract class SakaImageProvider<T> extends ImageProvider<SakaImageProvider> {
  final double scale;

  SakaImageProvider({this.scale = 1.0});

  SakaImageStream resolveStream(ImageConfiguration configuration) {
    assert(configuration != null);
    final SakaImageStream stream = SakaImageStream();
    SakaImageProvider obtainedKey;
    obtainKey(configuration).then<void>((SakaImageProvider key) {
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
  Future<SakaImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<SakaImageProvider>(this);
  }
}

class SakaAssetImage extends SakaImageProvider<SakaAssetImage> {
  final String imagePath;
  final double timeScale;

  SakaAssetImage(this.imagePath, {scale, this.timeScale})
      : assert(imagePath != null),
        assert(scale != 0),
        assert(timeScale != 0),
        super(scale: scale);

  @override
  ImageStreamCompleter load(SakaImageProvider key) {
    return SakaAssetImageStreamCompleter(
        codec: _loadAsync(key),
        timeScale: timeScale,
        scale: key.scale,
        informationCollector: (StringBuffer information) {
          information.writeln('Image provider: $this');
          information.write('Image key: $key');
        });
  }

  Future<ui.Codec> _loadAsync(SakaAssetImage key) async {
    assert(key == this);
    var byteData = await rootBundle.load(imagePath);
    var imgList = byteData.buffer.asUint8List();
    return PaintingBinding.instance.instantiateImageCodec(imgList);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final SakaAssetImage typedOther = other;
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

/// a simple load net image with headers.
/// if there is something wrong with the get url,it will never throw any exception.
/// if you have set the [errPlaceHolderPath] it will use the err image in the asset
/// if you  have not set the [errPlaceHolderPath], then it will show an transparent 1px png
class SakaNetworkImage extends SakaImageProvider<SakaNetworkImage> {
  final String url;
  final String prePlaceHolderPath;

  // must be an assets path
  final String errPlaceHolderPath;
  final double scale;
  final Map<String, String> headers;
  Duration duration;
  Duration outDuration;
  Duration inDuration;

  SakaNetworkImage(
    this.url, {
    this.prePlaceHolderPath,
    this.errPlaceHolderPath,
    this.duration,
    this.scale = 1.0,
    this.headers,
    this.outDuration = Duration.zero,
    this.inDuration = Duration.zero,
  })  : assert(url != null),
        assert(scale != null);

  @override
  ImageStreamCompleter load(SakaImageProvider key) {
    return SakaComposeFrameImageStreamCompleter(
        prePlaceHolderCodec: _loadPreAsync(key),
        codec: _loadAsync(key),
        scale: key.scale,
        inDuration: inDuration,
        outDuration: outDuration,
        inFuture: _loadInFuture(),
        informationCollector: (StringBuffer information) {
          information.writeln('Image provider: $this');
          information.write('Image key: $key');
        });
  }

  static final HttpClient _httpClient = HttpClient();

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
      var stopTime = DateTime.now();
      SakaLog.log(
          "loading used time :${stopTime.difference(startTime).toString()}");
      if (response.statusCode != HttpStatus.ok) {
        SakaLog.log("http url error");
        return ComposeImageInfo(
            await _getErrorImage(), ImageType.err_placeholder);
      }
      final Uint8List bytes =
          await consolidateHttpClientResponseBytes(response);
      if (bytes.lengthInBytes == 0) {
        SakaLog.log("url get bytes is not correct");
        return ComposeImageInfo(
            await _getErrorImage(), ImageType.err_placeholder);
      }
      return ComposeImageInfo(
          await _getDelayResult(bytes), ImageType.correct_image);
    } catch (e) {
      SakaLog.log(e.toString());
      return ComposeImageInfo(
          await _getErrorImage(), ImageType.err_placeholder);
    }
  }

  Future<ComposeImageInfo> _loadPreAsync(SakaNetworkImage key) async {
    assert(key == this);
    if (prePlaceHolderPath == null) {
      return null;
    }
    var byteData = await rootBundle.load(prePlaceHolderPath);
    var imgList = byteData.buffer.asUint8List();
    return ComposeImageInfo(
        await PaintingBinding.instance.instantiateImageCodec(imgList),
        ImageType.pre_placeholder);
  }

  Future<dynamic> _loadInFuture() {
    return Future.delayed(
      duration ?? Duration(seconds: 0),
      null,
    );
  }

  Future<ui.Codec> _getErrorImage() async {
    if (errPlaceHolderPath == null) {
      return _getDelayResult(Uint8List.fromList(Constant.emptyPng));
    }
    try {
      var byteData = await rootBundle.load(errPlaceHolderPath);
      var imgList = byteData.buffer.asUint8List();
      return _getDelayResult(imgList);
    } catch (e) {
      SakaLog.log("$errPlaceHolderPath::${e.toString()}");
      return _getDelayResult(Uint8List.fromList(Constant.emptyPng));
    }
  }

  Future<ui.Codec> _getDelayResult(Uint8List data) {
    print("outduration=${outDuration.toString()}");
    return Future.delayed(
      (duration ?? Duration(seconds: 0)) + outDuration,
      () => PaintingBinding.instance.instantiateImageCodec(data),
    );
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
