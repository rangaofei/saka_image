import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class MyImageProvider extends ImageProvider<MyImageProvider> {
  const MyImageProvider(this.url, {this.scale = 1.0, this.headers})
      : assert(url != null),
        assert(scale != null);

  /// The URL from which the image will be fetched.
  final String url;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  /// The HTTP headers that will be used with [HttpClient.get] to fetch image from network.
  final Map<String, String> headers;

  @override
  Future<MyImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<MyImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(MyImageProvider key) {
    return MultiFrameImageStreamCompleter(
        codec: _loadAsync(key),
        scale: key.scale,
        informationCollector: (StringBuffer information) {
          information.writeln('Image provider: $this');
          information.write('Image key: $key');
        });
  }

  static final HttpClient _httpClient = HttpClient();

  Future<ui.Codec> _loadAsync(MyImageProvider key) async {
    assert(key == this);

    final Uri resolved = Uri.base.resolve(key.url);
    print("-----${resolved.host}");
    try {
      final HttpClientRequest request = await _httpClient.getUrl(resolved);
      headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok)
        throw Exception(
            'HTTP request failed, statusCode: ${response?.statusCode}, $resolved');

      final Uint8List bytes =
          await consolidateHttpClientResponseBytes(response);
      if (bytes.lengthInBytes == 0)
        throw Exception('NetworkImage is an empty file: $resolved');

      return await PaintingBinding.instance.instantiateImageCodec(bytes);
    } catch (e) {
      print("----$e");
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final MyImageProvider typedOther = other;
    return url == typedOther.url && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}
