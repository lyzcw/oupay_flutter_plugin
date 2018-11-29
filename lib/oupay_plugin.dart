import 'dart:async';

import 'package:flutter/services.dart';
import 'package:oupay_plugin/pay_result.dart';
import 'package:oupay_plugin/alipay_result.dart';

//微信支付结果
enum WechatPayResult { success, fail, cancel }

class OupayPlugin {
  String code;

  static const MethodChannel _channel = const MethodChannel('oupay_plugin');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// 根据参数调起支付宝或微信支付接口
  /// payInfo 服务端返回的预支付订单字符串
  /// IOS用到：urlScheme iOS 支付需要用到，用Xcode打开项目ios部分，点击项目名称，点击“Info”选项卡，
  /// 在“URL Types”选项中，点击“+”，在“URL Schemes”中输你的urlScheme，该参数涉及到支付完成能否正确跳回商户app
  /// 支付宝支付用到：isSandbox android支付需要，是否是沙箱环境，默认非沙箱
  static Future<PayResult> ouPay(String payInfo, {String urlScheme, bool isSandbox = false}) async {
    // 获取支付渠道，然后删除
    PayResult payResult;
    int pos1 = payInfo.indexOf("&")+1;
    int pos2 = payInfo.indexOf("\"")+1;
    var payChannel = payInfo.substring(pos2, pos1 -2 );
    payInfo = payInfo.replaceRange(0, pos1, "");
    final Map<String, dynamic> params = <String, dynamic>{
      'payInfo': payInfo,
    };
    print("正式支付参数：" + params.toString() );
    print("支付渠道：" + payChannel.toString());
    params.remove("channelId");
    if( payChannel == "12"){ //支付宝支付

      try {
        var res = await _channel.invokeMethod('aliPay', <String, dynamic>{
          'payInfo': payInfo,
          'isSandbox': isSandbox,
          'urlScheme': urlScheme
        });
        print("支付宝支付返回码：" + res.toString());
        payResult = new PayResult(result: res['result'],resultStatus: res['resultStatus'], memo: res['memo']);
      } on PlatformException catch (e) {
        print(e);
        payResult =  null;
      }

    }if( payChannel == "13"){ //微信支付
      print("微信支付请求参数：" + params.toString());
      int payResulti = await _channel.invokeMethod('wechatPay', params );
      print("微信支付返回码：" + payResult.toString());
      payResult =  _convertOUPayResult( payResulti);

    }

    return payResult;
  }

  // 调起支付宝支付接口
  static Future<dynamic> aliPay(String payInfo,
      {String urlScheme, bool isSandbox = false}) async {
    try {
      var res = await _channel.invokeMethod('aliPay', <String, dynamic>{
        'payInfo': payInfo,
        'isSandbox': isSandbox,
        'urlScheme': urlScheme
      });
      print("支付宝支付返回码：" + res.toString());
      return new AlipayResult(result: res['result'],resultStatus: res['resultStatus'], memo: res['memo']);
    } on PlatformException catch (e) {
      print(e);
      return null;
    }

  }


  // 调起微信支付接口
  static Future<WechatPayResult> wechatPay( String payInfo ) async {
    final Map<String, dynamic> params = <String, dynamic>{
      'payInfo': payInfo,
    };
    print("微信支付请求参数：" + params.toString());
    int payResult = await _channel.invokeMethod('wechatPay', params );
    print("微信支付返回码：" + payResult.toString());
    return _convertWechatPayResult(payResult);
  }
  // 将微信支付同步响应结果翻译等价为支付宝格式的，即开联通用的支付结果
  static PayResult _convertOUPayResult(int payResult ) {

    switch (payResult) {
      case 0:
        return new PayResult( result: '9000 ', resultStatus: '',  memo: '订单支付成功');
      case -1:
        return new PayResult( result: '4000 ', resultStatus: '',  memo: '订单支付失败');
      case -2:
        return new PayResult( result: '6001 ', resultStatus: '',  memo: '用户中途取消');
      default:
        return null;
    }
  }

  static WechatPayResult _convertWechatPayResult(int payResult) {
    switch (payResult) {
      case 0:
        return WechatPayResult.success;
      case -1:
        return WechatPayResult.fail;
      case -2:
        return WechatPayResult.cancel;
      default:
        return null;
    }
  }

}

//支付参数
//参考微信文档 https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=9_12&index=2
class WechatPayInfo {
  String appid;
  String partnerid;
  String prepayid;
  String package;
  String noncestr;
  String timestamp;
  String sign;

  WechatPayInfo(
      {this.appid,
        this.partnerid,
        this.prepayid,
        this.package,
        this.noncestr,
        this.timestamp,
        this.sign});

  factory WechatPayInfo.fromJson(Map<String, dynamic> json) {
    return WechatPayInfo(
      appid: json['appid'],
      partnerid: json['partnerid'],
      prepayid: json['prepayid'],
      package: json['package'],
      noncestr: json['noncestr'],
      timestamp: json['timestamp'],
      sign: json['sign'],
    );
  }
}
