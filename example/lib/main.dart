import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oupay_plugin/oupay_plugin.dart';
import 'package:oupay_plugin/pay_result.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _payTips="支付订单";
  String _payInfo = "";
  PayResult _payResult;

  final myController = new TextEditingController();
  var bodyJson = '';
  // 到支付网关预下单
  void _loadPreOrder( String channel ){
    var _channelName = "";

    if(channel == "12"){
      _channelName = "支付宝";
      bodyJson = '{"orderId":"20181129031212538"}';
    }else if(channel == "13"){
      _channelName = "微信";
      bodyJson = '{"orderId":"20181129073950094"}';
    }
    _payInfo = "";
    _payResult = null;

    DateTime now = new DateTime.now();
    var formatter = new DateFormat('yyyyMMddHHmmss');
    String orderId =  formatter.format(now);

//    var bodyJson = '''{"subject": "商品A",
//      "body":"adkl在",
//      "amount":1,
//      "merchantId":"merchant1",
//      "orderId":"''' + orderId + '''",
//      "channelId":"''' + channel + '''",
//      "transactionType":"APP",
//      "orderTime":"''' + orderId + '''"}''';
    Map headerMap = new Map<String, String >();
    headerMap ["Content-Type"] = "application/json;charset=utf-8";
    headerMap ["access-token"] = "Vg2EXWcB6DPmWyyAXDg7";

    // 开联支付预下单接口 .post("http://10.1.239.38:15877/oupay/v1/order/1001",
    http
        .post("http://10.1.230.36:15836/v1/200010",
        headers: headerMap,
        body:  bodyJson )
        .then((http.Response response) {
      print( "预下单接口响应码：" + response.statusCode.toString());
      if (response.statusCode == 200) {
        print(response.body);
        var map = json.decode(response.body);
        String flag = map["retCode"];
        if (flag == "0000") {
          var result = map["data"];
          setState(() {
            _payInfo = result["signature"];//["payInfo"];
            myController.text = _payInfo;
          });
          return;
        }
      }
      throw new Exception("创建$_channelName订单失败");
    }).catchError((e) {
      setState(() {
        _payInfo = e.toString();
        myController.text = _payInfo;
      });
    });

    // 第三方支付预下单接口：
//    if(channel == "12") {
//      http
//          .post("http://120.79.190.42:8071/pay/test_pay/create",
//          body: json.encode({"fee": 1, "title": "test pay"}))
//          .then((http.Response response) {
//        if (response.statusCode == 200) {
//          print(response.body);
//          var map = json.decode(response.body);
//          int flag = map["flag"];
//          if (flag == 0) {
//            var result = map["result"];
//            setState(() {
//              _payInfo = result["credential"]["payInfo"];
//              _payInfo = _channelId + _payInfo;
//              myController.text = _payInfo;
//            });
//            return;
//          }
//        }
//        throw new Exception("创建订单失败");
//      }).catchError((e) {
//        setState(() {
//          _payInfo = e.toString();
//          myController.text = _payInfo;
//        });
//      });
//    }else if(channel == "13"){
//      setState(() {
//        _payInfo = '{"appId":"wxf9909bde17439ac2","partnerId":"1518469211","prepayId":"wx120649521695951d501636f91748325073","packageValue":"Sign=WXPay","nonceStr":"1541976592","timeStamp":"1541976592","sign":"E760C99A1A981B9A7D8F17B08EF60FCC"}';
//        _payInfo = _channelId + _payInfo;
//        myController.text = _payInfo;
//      });
//    }


    setState(() {
      _payTips = '$_channelName支付订单';
    });
  }

  @override
  initState() {
    super.initState();
    //注册微信app id
    registerWechat();

  }

  registerWechat() async {
    bool result = await OupayPlugin.registerWechat('wx8b9e82276293d56b');
    print(result);
  }

  onChanged(String value) {
    _payInfo = value;
  }

  _callOUPay( String channel ) async {
    _payResult = null;
    var _channelName = "";
    if(channel == "12"){
      _channelName = "支付宝";
    }else if(channel == "13"){
      _channelName = "微信";
    }
    print("开始：$_channelName");

    dynamic payResult;
    try {
      print("The pay info is : " + _payInfo);
      payResult = await OupayPlugin.ouPay( _payInfo, urlScheme: 'oupaycafa://', isSandbox: true);
      print("$_channelName支付返回结果 : " + payResult.toString());
    } on Exception catch (e) {
      payResult = null;
      print("$_channelName支付异常：" + e.toString());
    }

    if (!mounted) return;

    setState(() {
      _payResult = payResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('OUPay聚合支付插件测试程序'),
        ),
        body: new SingleChildScrollView(
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new Text("$_payTips"),
                new TextField(
                    maxLines: 15, onChanged: onChanged, controller: myController),
                // 支付宝支付
                new Row(
                  //MainAxisAlignment.spaceEvenly平均分配子空间  他会在每个子项之间,之前,之后平均分配空闲空间 当然也可以使用Expanded来实现
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    new Column(
                      children: [
                        new RaisedButton(onPressed: (){
                          _loadPreOrder("12");
                        }, child: new Text("支付宝下单")),
                      ],
                    ),
                    new Column(
                      children: [
                        new RaisedButton( onPressed:(){ this._callOUPay("12");}, child: new Text("调用支付宝")),

                      ],
                    ),
                  ],
                ),
                // 微信支付
                new Row(
                  //MainAxisAlignment.spaceEvenly平均分配子空间  他会在每个子项之间,之前,之后平均分配空闲空间 当然也可以使用Expanded来实现
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    new Column(
                      children: [
                        new RaisedButton(onPressed: (){
                          _loadPreOrder("13");
                        }, child: new Text("微信下单")),
                      ],
                    ),
                    new Column(
                      children: [
                        new RaisedButton(onPressed:(){ this._callOUPay("13");}, child: new Text("调用微信")),

                      ],
                    ),
                  ],
                ),
                new Text(_payResult == null ? "" : _payResult.toString()),

              ],
            ),
        ),
      ),
    );
  }
}