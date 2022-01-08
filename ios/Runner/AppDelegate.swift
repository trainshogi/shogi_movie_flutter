import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let batteryChannel = FlutterMethodChannel(name: "com.nkkuma.dev/piece_detect",
                                              binaryMessenger: controller.binaryMessenger)
    batteryChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
//         Note: this method is invoked on the UI thread.
//        guard call.method == "initial_piece_detect" else {
//          result(FlutterMethodNotImplemented)
//          return
//        }
      
      let parameters = call.arguments as! Dictionary<String, Any>
      switch call.method {
        case "initial_piece_detect":
            self.initial_piece_detect(result: result, parameters: parameters)
        default:
            result(FlutterMethodNotImplemented)
            return
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
  private func initial_piece_detect(result: FlutterResult, parameters: Dictionary<String, Any>) {
    let device = UIDevice.current
    device.isBatteryMonitoringEnabled = true
        
    let srcPath = parameters["srcPath"] as! String
    let dirName = parameters["dirName"] as! String
    let points = parameters["points"] as! String
    
    let grayImg = OpenCVManager.gray(UIImage(contentsOfFile: srcPath))!
    let filename = "grayImg.png" as String
    let grayImgPath = fileInDocumentsDirectory(filename: filename)
    saveImage(image: grayImg, path: grayImgPath)
    
    let dictionay1: Dictionary<String, Any> = ["imgPath": grayImgPath, "sfen": "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL"]
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: dictionay1, options: [])
      let jsonStr = String(bytes: jsonData, encoding: .utf8)!
      result(jsonStr)
    } catch let error {
      print(error)
    }
  }
  
  //画像保存
  // DocumentディレクトリのfileURLを取得
  func getDocumentsURL() -> NSURL {
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as NSURL
    return documentsURL
  }
  // ディレクトリのパスにファイル名をつなげてファイルのフルパスを作る
  func fileInDocumentsDirectory(filename: String) -> String {
    let fileURL = getDocumentsURL().appendingPathComponent(filename)
    return fileURL!.path
  }
  //画像を保存するメソッド
  func saveImage (image: UIImage, path: String ) -> Bool {
    let jpgImageData = image.jpegData(compressionQuality:0.5)
    do {
        try jpgImageData!.write(to: URL(fileURLWithPath: path), options: .atomic)
    } catch {
        print(error)
        return false
    }
    return true
  }
}
