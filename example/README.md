# example

this is just a simple Image that can use prePlaceHolder and errPlaceHolder.

## Getting Started

just use like Image:
```dart
SakaImage.urlWithPlaceHolder(
  "http://img.rangaofei.cn/01b18.jpg",
  errPlaceHolder: "images/error.jpeg",
  prePlaceHolder: "images/splash.jpg",
  preDuration: Duration(seconds: 5),
  fit: BoxFit.cover,
);
```

