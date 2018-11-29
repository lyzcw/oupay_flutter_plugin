package com.opun.oupayplugin;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.Log;

import com.alipay.sdk.app.EnvUtils;
import com.alipay.sdk.app.PayTask;

import com.tencent.mm.opensdk.modelpay.PayReq;
import com.tencent.mm.opensdk.openapi.IWXAPI;
import com.tencent.mm.opensdk.openapi.WXAPIFactory;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import org.json.JSONObject;

import java.util.Map;

/** OupayPlugin */
public class OupayPlugin implements MethodCallHandler {
  private final Activity activity;

  private static final String TAG = "OupayPlugin>>";
  public static final String filterName = "wxCallback";
  private IWXAPI wxApi;
  private Registrar registrar;
  private static Result result;
  private static final int THUMB_SIZE = 150;

  //微信支付回调
  private static BroadcastReceiver wxpayCallbackReceiver = new BroadcastReceiver() {
    @Override
    public void onReceive(Context context, Intent intent) {
      Integer errCode = intent.getIntExtra("errCode",-3);
      Log.e(TAG,errCode.toString());
      result.success(errCode);
    }
  };

  private OupayPlugin(Registrar registrar){
    this.activity = registrar.activity();
    this.registrar = registrar;
  }

   /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "oupay_plugin");
    channel.setMethodCallHandler( new OupayPlugin( registrar ));
    registrar.context().registerReceiver(wxpayCallbackReceiver,new IntentFilter(filterName));

  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    OupayPlugin.result = result;
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if (call.method.equals("aliPay")) {
//      String payInfo = call.argument("payInfo");
//      aliPay( registrar.activity(), payInfo, result );
      String payInfo = call.argument("payInfo");
      boolean isSandbox = call.argument("isSandbox");
      this.aliPay( payInfo,isSandbox, result);

    } else if (call.method.equals("wechatPay")) {
      this.wechatPay(call);
    } else {
      result.notImplemented();
    }

  }

  //调起支付宝支付
  public void aliPay(final String payInfo,boolean isSandbox, final MethodChannel.Result callback){
    //沙箱环境
    if(isSandbox){
      EnvUtils.setEnv(EnvUtils.EnvEnum.SANDBOX);
    }

    final Activity activity = this.activity;
    Runnable payRunnable = new Runnable() {
      @Override
      public void run() {
        try {
          Log.d(TAG, "支付宝app订单：" + payInfo);
          PayTask alipay = new PayTask(activity);
          Map<String, String> result = alipay.payV2(payInfo, true);
          callback.success(result);
        } catch (Exception e) {
          callback.error("支付宝PAY_ERROR",e.getMessage(),null);
        }
      }
    };

    Thread payThread = new Thread(payRunnable);
    payThread.start();
  }

//  public static void aliPay(final Activity currentActivity, final String payInfo, final Result callback){
//    Runnable payRunnable = new Runnable() {
//      @Override
//      public void run() {
//        try {
//          Log.d(TAG, "支付宝app订单：" + payInfo);
//          PayTask alipay = new PayTask(currentActivity);
//          Map<String, String> result = alipay.payV2(payInfo, true);
//
//          callback.success(result);
//        } catch (Exception e) {
//          callback.error(e.getMessage(),"支付宝支付发生错误",e);
//        }
//      }
//    };
//
//    Thread payThread = new Thread(payRunnable);
//    payThread.start();
//  }

  //调起微信支付
  private void wechatPay(MethodCall call){
    PayReq req = new PayReq();
    String payInfo = call.argument("payInfo");
    Log.d(TAG, "微信支付参数：" + payInfo);
    try {
      JSONObject paramsJson = new JSONObject(payInfo);
      req.appId = call.argument("appid");
      req.partnerId = call.argument("partnerid");
      req.prepayId= call.argument("prepayid");
      req.packageValue = call.argument("package");
      req.nonceStr= call.argument("noncestr");
      req.timeStamp= call.argument("timestamp");
      req.sign= call.argument("sign");

      req.appId = paramsJson.getString("appId");
      req.partnerId = paramsJson.getString("partnerId");
      req.prepayId = paramsJson.getString("prepayId");
      req.packageValue = paramsJson.getString("packageValue");
      req.nonceStr = paramsJson.getString("nonceStr");
      req.timeStamp = paramsJson.getString("timeStamp");
      req.sign = paramsJson.getString("sign");

      Log.d(TAG, "微信app订单：" + req.toString() );

      wxApi = WXAPIFactory.createWXAPI(registrar.context(), req.appId);

      wxApi.sendReq(req);

    }catch ( Exception e ){
      e.printStackTrace();
      Log.d(TAG,"微信支付发生异常",e);
    }
  }

}