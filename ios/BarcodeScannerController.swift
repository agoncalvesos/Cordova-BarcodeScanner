
import UIKit
import AVFoundation

class BarcodeScannerController : UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet var messageLabel:UILabel!
    @IBOutlet weak var cancelImageButton: UIButton!
    @IBOutlet weak var flashImageButton: UIButton!
    var showGuide:String = ""
    var pluginOrientation:String = ""
    var originalOrientation:UIInterfaceOrientation?
    var callbackId:String?
    var parentPlugin:CDVPlugin?
    var captureSession:AVCaptureSession?
    var qrCodeFrameView:UIView?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var cancelButton:UIButton?
    var flashButton:UIButton?
    var lineMidLeft:UILabel?
    var lineMidRight:UILabel?
    var lineBottomLeft:UILabel?
    var lineTopLeft:UILabel?
    var lineBottomRight:UILabel?
    var lineTopRight:UILabel?
    var metadataObjectTypes = [
        AVMetadataObject.ObjectType.qr,
        AVMetadataObject.ObjectType.dataMatrix,
        AVMetadataObject.ObjectType.upce,
        AVMetadataObject.ObjectType.code128,
        AVMetadataObject.ObjectType.code39,
        AVMetadataObject.ObjectType.ean8,
        AVMetadataObject.ObjectType.ean13,
        AVMetadataObject.ObjectType.itf14,
        AVMetadataObject.ObjectType.code93,
        AVMetadataObject.ObjectType.interleaved2of5
    ]
    var captureDevice:AVCaptureDevice!;
    var devicePosition:AVCaptureDevice.Position = .back;
    var torchMode:AVCaptureDevice.TorchMode = .auto; //flash
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    convenience init(orientation:String, showguide:String, camera:String, flash:String, callback:String, parent:CDVPlugin) {
        self.init(nibName:nil, bundle:nil)
        
        pluginOrientation = orientation
        showGuide = showguide
        callbackId = callback
        parentPlugin = parent
        
        //process orientation
        switch(UIDevice.current.orientation) {
        case .landscapeLeft:
            originalOrientation = UIInterfaceOrientation.landscapeLeft
            break;
        case .landscapeRight:
            originalOrientation = UIInterfaceOrientation.landscapeRight
            break;
        case .portraitUpsideDown:
            originalOrientation = UIInterfaceOrientation.portraitUpsideDown
            break;
        default:
            originalOrientation = UIInterfaceOrientation.portrait
            break;
        }
        
        switch(pluginOrientation) {
        case "landscapeRight":
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            break;
        case "landscapeLeft":
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
            break;
        case "portraitUpsideDown":
            UIDevice.current.setValue(UIInterfaceOrientation.portraitUpsideDown.rawValue, forKey: "orientation")
            break;
        default:
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
        
        //process device position (front or rear camera)
        if (camera == "front"){
            devicePosition = .front
        }
        
        //process flash
        if (flash == "on"){
            torchMode = .on
        } else if (flash == "off"){
            torchMode = .off;
        }
    }
    
    override func viewDidLoad(){
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter.
        //No camera available to scan the barcode.
        if #available(iOS 10.2, *) {
            if let device = AVCaptureDevice.default(.builtInDualCamera,
                                                    for: .video, position: devicePosition) {
                captureDevice = device;
            } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                           for: .video, position: devicePosition) {
                captureDevice = device;
            } else {
                fatalError("No camera available to scan the barcode.")
            }
            
        } else {
            if let device = AVCaptureDevice.default(for: .video) {
                captureDevice = device;
            } else{
                fatalError("No camera available to scan the barcode.")
            }
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = metadataObjectTypes;
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            switch(pluginOrientation) {
            case "landscapeRight":
                videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
                break;
            case "landscapeLeft":
                videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
                break;
            case "portraitUpsideDown":
                videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
                break;
            default:
                videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            }
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resize
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubview(toFront:qrCodeFrameView)
            }
            
            if(showGuide == "on" || showGuide == "auto") {
                lineMidLeft = UILabel(frame: CGRect(
                    x:view.bounds.size.width / 7,
                    y:(view.bounds.size.height / 2) - (view.bounds.size.height / 8),
                    width:2,
                    height: view.bounds.size.height / 4)
                )
                if let lineMidLeft = lineMidLeft {
                    lineMidLeft.backgroundColor = .white
                    view.addSubview(lineMidLeft)
                    view.bringSubview(toFront: lineMidLeft)
                }
                
                lineMidRight = UILabel(frame: CGRect(
                    x:view.bounds.size.width - (view.bounds.size.width / 7),
                    y:(view.bounds.size.height / 2) - (view.bounds.size.height / 8),
                    width:2,
                    height: view.bounds.size.height / 4)
                )
                if let lineMidRight = lineMidRight {
                    lineMidRight.backgroundColor = .white
                    view.addSubview(lineMidRight)
                    view.bringSubview(toFront: lineMidRight)
                }
                
                lineBottomLeft = UILabel(frame: CGRect(
                    x:view.bounds.size.width - (view.bounds.size.width / 7) - (view.bounds.size.width / 12) + 2,
                    y:(view.bounds.size.height / 2) - (view.bounds.size.height / 8),
                    width: view.bounds.size.width / 12,
                    height: 2)
                )
                if let lineBottomLeft = lineBottomLeft {
                    lineBottomLeft.backgroundColor = .white
                    view.addSubview(lineBottomLeft)
                    view.bringSubview(toFront:lineBottomLeft)
                }
                
                lineTopLeft = UILabel(frame: CGRect(
                    x:view.bounds.size.width - (view.bounds.size.width / 7) - (view.bounds.size.width / 12) + 2,
                    y:(view.bounds.size.height / 2) + (view.bounds.size.height / 8) - 2,
                    width: view.bounds.size.width / 12,
                    height: 2)
                )
                if let lineTopLeft = lineTopLeft {
                    lineTopLeft.backgroundColor = .white
                    view.addSubview(lineTopLeft)
                    view.bringSubview(toFront:lineTopLeft)
                }
                
                lineBottomRight = UILabel(frame: CGRect(
                    x:view.bounds.size.width / 7,
                    y:(view.bounds.size.height / 2) - (view.bounds.size.height / 8),
                    width: view.bounds.size.width / 12,
                    height: 2)
                )
                if let lineBottomRight = lineBottomRight {
                    lineBottomRight.backgroundColor = .white
                    view.addSubview(lineBottomRight)
                    view.bringSubview(toFront:lineBottomRight)
                }
                
                lineTopRight = UILabel(frame: CGRect(
                    x:view.bounds.size.width / 7,
                    y:(view.bounds.size.height / 2) + (view.bounds.size.height / 8) - 2,
                    width: view.bounds.size.width / 12,
                    height: 2)
                )
                if let lineTopRight = lineTopRight {
                    lineTopRight.backgroundColor = .white
                    view.addSubview(lineTopRight)
                    view.bringSubview(toFront:lineTopRight)
                }
                
                messageLabel = UILabel(frame: CGRect(x:0, y:0, width:view.bounds.size.width, height:40))
                messageLabel.textAlignment = .center
                messageLabel.text = "Scanning..."
                messageLabel.textColor = .white
                view.addSubview(messageLabel)
                view.bringSubview(toFront:messageLabel)
            }
            
            cancelButton = UIButton(frame: CGRect(x:view.bounds.size.width - 51, y:5, width:48, height:48))
            if let cancelButton = cancelButton {
                cancelButton.setImage(UIImage(named: "ios7-close-empty-white.png"), for: .normal)
                cancelButton.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
                view.addSubview(cancelButton)
                view.bringSubview(toFront:cancelButton)
            }
            
            flashButton = UIButton(frame: CGRect(x:view.bounds.size.width - 51, y:view.bounds.size.height - 51, width:48, height:48))
            if let flashButton = flashButton {
                flashButton.setImage(UIImage(named: "ios7-bolt-outline-white.png"), for: .normal)
                flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
                view.addSubview(flashButton)
                view.bringSubview(toFront:flashButton)
            }
            
            // Start video capture.
            captureSession?.startRunning()
            
            //set torch mode (flash)
            setFlash(torchMode: torchMode)
            
        } catch {
            print(error)
        }
    }
    
    @objc func cancelButtonAction(sender: UIButton!) {
        // Prepare a failed result for cordova
        parentPlugin?.commandDelegate!.send(CDVPluginResult(status:CDVCommandStatus_ERROR, messageAs: "Barcode scan cancelled."), callbackId: callbackId);
        cleanupScreen()
    }
    
    @objc func toggleFlash() {
        if captureDevice.hasTorch {
            let torchOn = !captureDevice.isTorchActive
            setFlash(torchMode: torchOn ? .on : .off)
        }
    }
    
    func setFlash(torchMode:AVCaptureDevice.TorchMode){
        if captureDevice.hasTorch {
            do {
                try captureDevice.lockForConfiguration()
                if (torchMode == .on){
                    try captureDevice.setTorchModeOn(level: 1.0)
                }
                captureDevice.torchMode = torchMode
                captureDevice.unlockForConfiguration()
                
                if(torchMode == .on) {
                    flashButton?.setImage(UIImage(named: "ios7-bolt-white.png"), for: .normal)
                } else {
                    flashButton?.setImage(UIImage(named: "ios7-bolt-outline-white.png"), for: .normal)
                }
            } catch {
                print("Error toggling flash.")
            }
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if (metadataObjectTypes.contains(metadataObj.type)){
            // If the found metadata is equal to any of the metadata types that we want (qr, ean...) then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            //Get the barcode value and type
            //var barcodeReturn = [AnyHashable: Any]();
            //barcodeReturn["data"] = metadataObj.stringValue;
            //barcodeReturn["format"] = metadataObj.type;
            
            //Prepare the result and make the callback
            parentPlugin?.commandDelegate!.send(CDVPluginResult(status:CDVCommandStatus_OK, messageAs: metadataObj.stringValue), callbackId: callbackId)
            
            cleanupScreen()
        }
    }
    
    func cleanupScreen() {
        
        if let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch {
            do {
                try device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            } catch {
                print("Error turning off flash.")
            }
        }
        
        videoPreviewLayer?.removeFromSuperlayer()
        qrCodeFrameView?.removeFromSuperview()
        messageLabel?.removeFromSuperview()
        cancelButton?.removeFromSuperview()
        flashButton?.removeFromSuperview()
        lineMidLeft?.removeFromSuperview()
        lineMidRight?.removeFromSuperview()
        lineBottomLeft?.removeFromSuperview()
        lineTopLeft?.removeFromSuperview()
        lineBottomRight?.removeFromSuperview()
        lineTopRight?.removeFromSuperview()
        captureSession?.stopRunning()
        
        lineMidLeft = nil
        lineMidRight = nil
        lineBottomLeft = nil
        lineTopLeft = nil
        lineBottomRight = nil
        lineTopRight = nil
        flashButton = nil
        cancelButton = nil
        videoPreviewLayer = nil
        qrCodeFrameView = nil
        messageLabel = nil
        captureSession = nil
        
        UIDevice.current.setValue(originalOrientation?.rawValue, forKey: "orientation")
        
        self.dismiss(animated: true, completion: nil)
    }
}
