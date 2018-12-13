import 'package:flutter/material.dart';
import 'package:saka_image/saka_image.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ImageInfo info; //图片信息
  List<BlendMode> blendModes = BlendMode.values; //所有的混合模式转换为list
  double radius = 10.0;

  @override
  void initState() {
    super.initState();

    Future<Duration>.delayed(Duration(milliseconds: 2 * 1000), () {
      setState(() {
        radius = 20.0;
      });
      return Duration(milliseconds: 210);
    }).then((Duration d) {
      Future<Duration>.delayed(d, () {
        setState(() {
          radius = 40.0;
        });
        return Duration(milliseconds: 210);
      }).then((Duration d) {
        Future<Duration>.delayed(d, () {
          setState(() {
            radius = 30.0;
          });
        });
      });
      ;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Image.asset("images/yuan.png")
        .image
        .resolve(createLocalImageConfiguration(context))
        .addListener((ImageInfo image, bool synchronousCall) {
      setState(() {
        info = image; //刷新状态
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: getSakaImage());
  }

  Widget getAvatar() {
    return Center(
      child: CircleAvatar(
        child: Text("头像"),
        backgroundImage: AssetImage("images/yuan.png"),
        radius: radius,
      ),
    );
  }

  Widget getBoxImage() {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage("images/yuan.png"))),
    );
  }

  Widget getInkedImage() {
    return Ink.image(image: AssetImage("images/timg.jpeg"));
  }

  Widget getFadeInImage() {
    return FadeInImage(
      placeholder: AssetImage("images/timg.jpeg"),
      image: NetworkImage("http://img.rangaofei.cn/01b18.jpg"),
      fadeOutDuration: Duration(seconds: 2),
      fadeInDuration: Duration(seconds: 1),
    );
  }

  Widget getImageIcon() {
    return ImageIcon(AssetImage("images/timg.jpeg"));
  }

  Widget getBlendMode() {
    return GridView.builder(
      itemCount: blendModes.length - 1,
      padding: EdgeInsets.only(top: 10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
      ),
      itemBuilder: getItemBuilder,
    );
  }

  Widget getItemBuilder(BuildContext context, int index) {
    return Column(
      children: <Widget>[
        RawImage(
          image: info?.image,
          color: Colors.red,
          width: 40,
          height: 40,
          colorBlendMode: blendModes[index + 1],
          fit: BoxFit.cover,
        ),
        Container(
          padding: EdgeInsets.only(top: 10.0),
          child: Text(
            blendModes[index + 1].toString().split("\.")[1],
            style: TextStyle(
              color: Colors.black,
              fontSize: 15.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget getSakaImage() {
    return SakaImage.urlWithPlaceHolder(
      "http://wx3.sinaimg.cn/mw690/006ZrXHXgy1fvxfdb3h2fg30bq0fx1l3.gif",
      prePlaceHolder: "images/timg.jpeg",
      errPlaceHolder: "images/06bo8.jpg",
      preDuration: Duration(seconds: 10),
    );
  }

  Widget getSakaAssetImage() {
    return SakaImage.assetImage(
      "images/bbb.gif",
      timeScale: 2.0,
    );
  }
}
