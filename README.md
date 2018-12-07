# saka_image

A flutter image widget,can use placeholder before loading net_image,
also can show an error image if there is something wrong with the image url

## Getting Started

just like use Image.network

```dart
SakaImage.urlWithPlaceHolder(
  "http://img.rangaofei.cn/01b18.jpg",
  prePlaceHolder: "images/test.gif",
  errPlaceHolder: "images/error.jpeg",
  preDuration: Duration(seconds: 10),
);
 ```

prePlaceHolder is used before load the net image

errPlaceHolder is user when the url not correct

preDuration is the prePlaceHolder show duration at least

other property is just like Image
1. with no duration,when the net image get completed,
the pre placeholder will be placed immediately.

```dart
SakaImage.urlWithPlaceHolder(
  "http://img.rangaofei.cn/01b18.jp",
  errPlaceHolder: "images/error.jpeg",
  prePlaceHolder: "images/splash.jpg",
  fit: BoxFit.cover,
);

```
![](file_pic/nopretime.gif)

2. with duration,when the net image get completed before the duration,
the placeholder will not be placed until the duration.

![]()

> the placeholder must be an assets url
