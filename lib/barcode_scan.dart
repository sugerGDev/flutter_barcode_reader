import 'dart:async';

import 'package:flutter/services.dart';



typedef void hand_barcode_scanner_callback(Object event);

/// Barcode scanner plugin
/// Simply call `var barcode = await BarcodeScanner.scan()` to scan a barcode
class BarcodeScanner {
  /// If the user has not granted the access to the camera this code is thrown.
  static const CameraAccessDenied = 'PERMISSION_NOT_GRANTED';

  /// If the user cancel the scan an exception with this code is thrown.
  static const UserCanceled = 'USER_CANCELED';

  /// The method channel
  static const MethodChannel _channel =
      const MethodChannel('de.mintware.barcode_scan');

  /// Starts the camera for scanning the barcode, shows a preview window and
  /// returns the barcode if one was scanned.
  /// Can throw an exception.
  /// See also [CameraAccessDenied] and [UserCanceled]
  /**
   [IN] KEY：button_key   VALUE:int(0 无， 1 手动， 2，历史， 3， 显示全部)
      返回事件ID
   */


  /**
   * 在原来的基础上增加
      [OUT] 处理个推Nav-返回的消息
   * CODE: input_key           // 是否显点击输入按钮
   * CODE: history_key         // 是否是点击历史按钮
   */
  static Future<String> scan(Map<String,int> param) async{
    return await _channel.invokeMethod('scan',param);
  }

}
