import UIKit
import Flutter
import opencv2

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let pieceDetectChannel = FlutterMethodChannel(name: "com.nkkuma.dev/piece_detect",
                                              binaryMessenger: controller.binaryMessenger)
    
    pieceDetectChannel.setMethodCallHandler({
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
  
  // static variables
  let fileController = FileController()
    
  private func initial_piece_detect(result: FlutterResult, parameters: Dictionary<String, Any>) {
    let device = UIDevice.current
    device.isBatteryMonitoringEnabled = true
        
    let srcPath = parameters["srcPath"] as! String
    let dirName = parameters["dirName"] as! String
    let points = parameters["points"] as! String
    
    let grayImg = convertColor(srcImage: UIImage(contentsOfFile: srcPath)!) // OpenCVManager.gray(UIImage(contentsOfFile: srcPath))!
    let filename = "grayImg.png" as String
    let grayImgPath = fileInDocumentsDirectory(filename: filename)
    fileController.saveImage(image: grayImg, path: grayImgPath)
    
    let dictionay1: Dictionary<String, Any> = ["imgPath": grayImgPath, "sfen": "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL"]
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: dictionay1, options: [])
      let jsonStr = String(bytes: jsonData, encoding: .utf8)!
      result(jsonStr)
    } catch let error {
      print(error)
    }
  }
  
  func convertColor(srcImage: UIImage) -> UIImage {
      let srcMat = Mat(uiImage: srcImage)
      let dstMat = Mat()
      Imgproc.cvtColor(src: srcMat, dst: dstMat, code: .COLOR_RGB2GRAY)
      return dstMat.toUIImage()
  }
  
  //????????????
  // Document?????????????????????fileURL?????????
  func getDocumentsURL() -> NSURL {
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as NSURL
    return documentsURL
  }
  // ????????????????????????????????????????????????????????????????????????????????????????????????
  func fileInDocumentsDirectory(filename: String) -> String {
    let fileURL = getDocumentsURL().appendingPathComponent(filename)
    return fileURL!.path
  }
}
