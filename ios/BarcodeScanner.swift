import Foundation
import UIKit

@available(iOS 10, *)
@objc(BarcodeScanner) class BarcodeScanner : CDVPlugin {
    
    var scannerController:BarcodeScannerController? = nil
    
    @objc(scan:)
    func scan(command: CDVInvokedUrlCommand) {
        let params:NSDictionary = command.arguments[0] as! NSDictionary;
        let camera:String = params.object(forKey: "camera") as? String ?? "";
        let flash:String = params.object(forKey: "flash") as? String ?? "";
        let orientation:String = params.object(forKey: "orientation") as? String ?? "";
        let drawSight:Bool = params.object(forKey: "drawSight") as? Bool ?? true;
        
        let scannerController:BarcodeScannerController = BarcodeScannerController(
            orientation:orientation,
            showguide:drawSight,
            camera:camera,
            flash:flash,
            callback:command.callbackId,
            parent:self)
        scannerController.modalTransitionStyle = UIModalTransitionStyle.coverVertical;
        scannerController.modalPresentationStyle = UIModalPresentationStyle.fullScreen;
        self.viewController?.present(scannerController, animated:true, completion:nil)
    }
}
