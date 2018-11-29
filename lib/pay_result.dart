import 'dart:async';

import 'package:flutter/services.dart';

class PayResult{

  ///
  final String memo;

  /// 支付后结果
  final String result;

  /// 支付状态，参考支付宝的文档https://docs.open.alipay.com/204/105695/
  /// 返回码，标识支付状态，含义如下：
  /// 9000——订单支付成功         上面的result有值
  /// 8000——正在处理中
  /// 4000——订单支付失败
  /// 5000——重复请求
  /// 6001——用户中途取消
  /// 6002——网络连接出错
  final String resultStatus;

  PayResult({
    this.memo,
    this.result,
    this.resultStatus
  });

  @override
  String toString() {
    return "{mono: $memo, resultStatus:$resultStatus, result:$result}";
  }

}
