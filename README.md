# saka_image

A flutter image widget,can use placeholder before loading net_image,
also can show an error image if there is something wrong with the image url

## Getting Started

just like use Image.network

just three

```dart
SakaImage.urlWithPlaceHolder(
  "http://img.rangaofei.cn/01b18.jpg",
  prePlaceHolder: "images/test.gif",
  errPlaceHolder: "images/error.jpeg",
  preDuration: Duration(seconds: 10),
);
 ```

prePlaceHolder is used before the net image

errPlaceHolder is user when the url not correct

preDuration is the prePlaceHolder show duration at least

*** the placeholder must be an assets url ***
