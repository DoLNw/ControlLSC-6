//
//  ViewController.swift
//  CameraCapture1
//
//  Created by JiaCheng on 2018/10/22.
//  Copyright © 2018 JiaCheng. All rights reserved.
//

import UIKit
import AVFoundation
import CoreBluetooth

let SCREEN_WIDTH = UIScreen.main.bounds.size.width
let SCREEN_HEIGHT = UIScreen.main.bounds.size.height
//scanTableViewController的长度只要给下面的改值就好
let SEGUED_HEIGHT = UIScreen.main.bounds.size.height/2+100

class ViewController: UIViewController {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendBtn: UIButton!
    
    var sendIndex = -1;
    var startIndex = -1;
    var endIndex = -1;
    @IBOutlet weak var textAction1: UITextField!
    @IBOutlet weak var textAction2: UITextField!
    @IBOutlet weak var sendBtn4: UIButton!
    @IBAction func send4Action(_ sender: UIButton) {
        guard self.characteristic != nil, let startIndexTemp=Int(self.textAction1.text!, radix: 16), let endIndexTemp=Int(self.textAction2.text!, radix: 16) else {
            showErrorAlertWithTitle("Error", message: "Please ensure the input is valid")
            return
        }
        startIndex = startIndexTemp
        endIndex = endIndexTemp
        sendIndex = startIndex
        
        let preDatas = ["55", "55", "05", "06", "\(startIndex)", "01", "00"]
        for preData in preDatas {
            let dec = Int(preData, radix: 16)!
            let data = String(UnicodeScalar(dec)!).data(using: .utf8)!
            peripheral.writeValue(data, for: self.characteristic, type: .withoutResponse)
        }
    }
    
    @IBOutlet weak var sendTraulBtn: UIButton!
    
    @IBOutlet weak var sendBtn3: UIButton!
    @IBOutlet weak var send3Text: UITextField!
    @IBOutlet weak var send3Text2: UITextField!
    @IBOutlet weak var send3Text3: UITextField!
    @IBAction func send3Action(_ sender: UIButton) {
        guard self.characteristic != nil, let dec1=Int(self.send3Text.text!, radix: 16), let data1=UnicodeScalar(dec1), let dec2 = Int(self.send3Text2.text!, radix: 16), let data2 = UnicodeScalar(dec2), let dec3 = Int(self.send3Text3.text!, radix: 16), let data3 = UnicodeScalar(dec3) else {
            showErrorAlertWithTitle("Error", message: "Please ensure the input is valid")
            return
        }
        
        let preDatas = ["55", "55", "05", "06"]
        for preData in preDatas {
            let dec = Int(preData, radix: 16)!
            let data = String(UnicodeScalar(dec)!).data(using: .utf8)!
            peripheral.writeValue(data, for: self.characteristic, type: .withoutResponse)
        }
        
        peripheral.writeValue(String(data1).data(using: .utf8)!, for: self.characteristic, type: .withoutResponse)
        peripheral.writeValue(String(data2).data(using: .utf8)!, for: self.characteristic, type: .withoutResponse)
        peripheral.writeValue(String(data3).data(using: .utf8)!, for: self.characteristic, type: .withoutResponse)
    }
    
    var receiveStr = "" {
        didSet {
            DispatchQueue.main.sync { [unowned self] in
                self.receiveTextView.text = self.receiveStr
                self.receiveTextView.scrollRangeToVisible(NSRange(location: self.receiveTextView.text.lengthOfBytes(using: .utf8), length: 1))
            }
        }
    }
    
    @IBOutlet weak var receiveTextView: UITextView!
    @IBOutlet weak var instructionsTextView: UITextView!
    
    @IBAction func sendAction(_ sender: UIButton) {
        guard self.characteristic != nil && self.textField.text != "" else {
            showErrorAlertWithTitle("Error", message: "Please ensure the input is valid")
            return
        }
        self.textField.resignFirstResponder()
        
        
        //注意：理一理从手机发到单片机的原理：我从这里发一个数字5，不过是要打包成string的，即String（5）.data(using: .utf8)，之后单片机收到的是字符‘5’（也可换算成16进制ascii码），所以若对方要收到0x55这一ascii，那么也就是说我要发送的字符是ascii为0x55即可，那么我也可以把U发过去就好了。但是你要知道一个无符号16进制最大能到FF，但是我这个ascii第一位是预留的他只是用了后7位位0x7F，导致发送的消息超过0x7E以后就出现了错误.
        //所以经过分析我发现首先我不是转成ascii而是unicode，但是我找到了直接byte转成data的方法，注意byte就是UInt8.
        
        //以下是对textfield中输入的每两个用空格分隔的16进制先转成10进制，再转成相应的ascii码，然后转成data发送出去。
        let text = self.textField.text?.split(separator: " ")
        for hexStr in text! {
            if let data = convertToUInts8Data(string: String(hexStr)) {
                peripheral.writeValue(data, for: self.characteristic, type: .withoutResponse)
                continue
            }
            
            showErrorAlertWithTitle("Error", message: "Please ensure the input is valid")
            return
        }
    }
    
    @IBAction func sendTrail(_ sender: UIButton) {
        guard self.characteristic != nil else { return }
        let data = String("\r\n").data(using: .utf8)!
        peripheral.writeValue(data, for: self.characteristic, type: .withoutResponse)
    }
    
    static var peripherals = [String]()
    static var peripheralIDs = [CBPeripheral]()
    //由于扩展中不能写存储属性，所以只能写在这里了
    static var isBlueOn = false
    static var isFirstPer = false
    static var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    private var characteristic: CBCharacteristic!
    var disConnectBtn: UIButton!
    var ConnectBtn: UIButton!
    var activityView: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "UnConnected"
        
        ViewController.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
        self.blueDisplay()
        
        sendBtn.layer.cornerRadius = 5
        sendBtn.clipsToBounds = true
        sendBtn.isHidden = true
        sendTraulBtn.layer.cornerRadius = 5
        sendTraulBtn.clipsToBounds = true
        sendTraulBtn.isHidden = true
        sendBtn3.layer.cornerRadius = 5
        sendBtn3.clipsToBounds = true
        sendBtn3.isHidden = true
        sendBtn4.layer.cornerRadius = 5
        sendBtn4.clipsToBounds = true
        sendBtn4.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        
        textField.delegate = self
        send3Text.delegate = self
        send3Text2.delegate = self
        send3Text3.delegate = self
        textAction1.delegate = self
        textAction2.delegate = self
        
        
        self.instructionsTextView.text = """
        作用   帧头 长度指令 参数
        舵机  55 55 08 03 01 E8 03 01 D0 07
        舵机  55 55 0B 03 02 20 03 02 B0 04 09 FC 08
        动组  55 55 05 06 08 01 00
        动组  55 55 05 06 02 00 00
        停止  55 55 02 07
        速度  55 55 05 0B 08 32 00
        速度  55 55 05 0B FF 2C 01
        电压  55 55 02 0F
        """
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.peripheral == nil {
            ConnectBtn.isHidden = false
            disConnectBtn.isHidden = true
            activityView.stopAnimating()
            activityView.isHidden = true
            allBtnisHidden(true)
        } else {
            ConnectBtn.isHidden = true
            disConnectBtn.isHidden = false
            activityView.stopAnimating()
            activityView.isHidden = true
            allBtnisHidden(false)
        }
    }
    
}

//MARK: - BlueToothDelegate
extension ViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    func startBlueTooth() {
        guard ViewController.isBlueOn else { return }
//        centralManager.scanForPeripherals(withServices: nil, options: nil)
        //过了一会儿没连上怎么办？
//        DispatchQueue.main.asyncAfter(deadline: .now()+5) { [unowned self] in
//            if self.peripheral == nil {
//                self.activityView.stopAnimating()
//                self.activityView.isHidden = true
//                self.ConnectBtn.isHidden = false
//            }
//            let ac = UIAlertController(title: "Not Found", message: "Please check if the peripheral is OK!", preferredStyle: .alert)
//            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//            self.present(ac, animated: true)
//        }
        let scanTableController = storyboard?.instantiateViewController(withIdentifier: "ScanTableController") as! ScanTableViewController
        self.navigationController?.pushViewController(scanTableController, animated: true)
//        self.navigationController?.modalTransitionStyle = .coverVertical
//        self.navigationController?.present(scanTableController, animated: true)
        ConnectBtn.isHidden = true
        activityView.isHidden = false
        activityView.startAnimating()
//        ConnectBtn.removeFromSuperview()
//        blurView.contentView.addSubview(disConnectBtn)
    }
    @objc func blueBtnMethod(_ sender: UIButton) {
        if sender.currentTitle == "ScanPer" {
            startBlueTooth()
        } else if sender.currentTitle == "Discont" {
            guard self.peripheral != nil else { return }
            ViewController.centralManager.cancelPeripheralConnection(self.peripheral)
        }
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            ViewController.isBlueOn = true
            DispatchQueue.main.sync {
                ConnectBtn.isHidden = false
                self.title = "UnConnected"
            }
        default:
            ViewController.isBlueOn = false
            DispatchQueue.main.sync {
                if (self.navigationController?.viewControllers.count)! > 1 {
                    self.navigationController?.popViewController(animated: true)
                }
                self.disConnectBtn.isHidden = true
                self.ConnectBtn.isHidden = true
                allBtnisHidden(true)
                self.title = ""
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+0.25) { [unowned self] in
                //貌似转场没结束，直接按钮隐身是没用的，所以只能after动画结束了难受
                self.disConnectBtn.isHidden = true
                self.ConnectBtn.isHidden = true
            }
            if self.peripheral != nil {
                centralManager(ViewController.centralManager, didDisconnectPeripheral: self.peripheral, error: nil)
            }
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripheral.name != nil else { return }
        
        if ViewController.isFirstPer {
            ViewController.isFirstPer = false
            ViewController.peripherals = []
            ViewController.peripheralIDs = []
            ViewController.peripherals.append(peripheral.name ?? "Unknown")
            ViewController.peripheralIDs.append(peripheral)
        } else {
            for per in ViewController.peripheralIDs {
                if per == peripheral { return }
            }
            ViewController.peripherals.append(peripheral.name ?? "Unknown")
            ViewController.peripheralIDs.append(peripheral)
        }
//        guard peripheral.identifier == UUID(uuidString: "32631FF3-E023-3448-0F0C-2A7437257A72") else {
//            return
//        }
//        self.peripheral = peripheral
//        ViewController.centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect: ")
        self.title = peripheral.name
        DispatchQueue.main.async { [unowned self] in
            self.activityView.stopAnimating()
            self.activityView.isHidden = true
            self.disConnectBtn.isHidden = false
            self.allBtnisHidden(false)
        }
        
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
        self.peripheral = peripheral
        ViewController.centralManager.stopScan()
        self.peripheral.delegate = self
        self.peripheral.discoverServices(nil)
        
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect: ")
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral: ")
        self.peripheral = nil
        self.characteristic = nil
        DispatchQueue.main.async { [unowned self] in
            self.allBtnisHidden(true)
            if ViewController.isBlueOn {
                self.disConnectBtn.isHidden = true
                self.activityView.isHidden = true
                self.activityView.stopAnimating()
                self.ConnectBtn.isHidden = false
                self.title = "UnConnected"
            } else {
                self.disConnectBtn.isHidden = true
                self.activityView.isHidden = true
                self.activityView.stopAnimating()
                self.ConnectBtn.isHidden = true
                self.title = ""
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard self.peripheral == peripheral else { return }
        
        print((peripheral.services?.first)!)
        peripheral.discoverCharacteristics(nil, for: (peripheral.services?.first)!)
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard self.peripheral == peripheral else { return }
        //此处last还是first有讲究吗？我记得之前一直设置订阅订阅不上去的，怎么解决的？
        self.characteristic = service.characteristics?.first
        print(self.characteristic!)
        
        if (self.characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue) != 0 {
            peripheral.setNotifyValue(true, for: self.characteristic)
        } else {
            print("cannot notify")
        }
        if (self.characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) != 0 {
            peripheral.readValue(for: self.characteristic)
        } else {
            print("cannot read")
        }
        
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Updated")
        if let error = error {
            print(error.localizedDescription)
        } else {
            let data = NSData(data: characteristic.value!)
            let value = data.description.replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "").replacingOccurrences(of: " ", with: "").uppercased()
            receiveStr += "\(value)\n"
            
            guard startIndex != -1 else { return }
            if value.hasPrefix("55550508") {
                sendIndex += 1;
                if sendIndex <= endIndex {
                    let preDatas = ["55", "55", "05", "06", "\(sendIndex)", "01", "00"]
                    for preData in preDatas {
                        let dec = Int(preData, radix: 16)!
                        let data = String(UnicodeScalar(dec)!).data(using: .utf8)!
                        peripheral.writeValue(data, for: self.characteristic, type: .withoutResponse)
                    }
                }
                
                if sendIndex == endIndex {
                    sendIndex = -1
                    startIndex = -1
                    endIndex = -1
                }
            }
            
        }

    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Notidied")
    }
    
}


//MARK: - Extral Display
extension ViewController {    
    func blueDisplay() {
        let visualEffect = UIBlurEffect(style: .dark)
        
        let blurView = UIVisualEffectView(effect: visualEffect)
//        self.blurView = blurView
        blurView.frame = CGRect(x: self.view.bounds.width-120, y: self.view.bounds.height-125, width: 100, height: 100)
        blurView.alpha = 0.7
        blurView.layer.cornerRadius = 10
        blurView.clipsToBounds = true
        
        ConnectBtn = UIButton(type: .custom)
        ConnectBtn.addTarget(self, action: #selector(blueBtnMethod(_:)), for: .touchUpInside)
        ConnectBtn.frame = CGRect(x: 10, y: 10, width: 80, height: 80)
//        blueBtn.tintColor = UIColor.white
//        blueBtn.titleLabel?.text = "OK"
        ConnectBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        ConnectBtn.titleLabel?.textAlignment = .center
        ConnectBtn.isHidden = false
        ConnectBtn.setTitle("Not OK", for: .normal)
        ConnectBtn.setTitle("ScanPer", for: .highlighted)
        ConnectBtn.setTitleColor(UIColor.white, for: .normal)
        ConnectBtn.setTitleColor(UIColor.red, for: .highlighted)
        blurView.contentView.addSubview(ConnectBtn) //必须添加到contentView
        
        disConnectBtn = UIButton(type: .custom)
        disConnectBtn.addTarget(self, action: #selector(blueBtnMethod(_:)), for: .touchUpInside)
        disConnectBtn.frame = CGRect(x: 10, y: 10, width: 80, height: 80)
        //        blueBtn.tintColor = UIColor.white
        //        blueBtn.titleLabel?.text = "OK"
        disConnectBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        disConnectBtn.titleLabel?.textAlignment = .center
        disConnectBtn.isHidden = true
        disConnectBtn.setTitle("Conted", for: .normal)
        disConnectBtn.setTitle("Discont", for: .highlighted)
        disConnectBtn.setTitleColor(UIColor.red, for: .normal)
        disConnectBtn.setTitleColor(UIColor.red, for: .highlighted)
        blurView.contentView.addSubview(disConnectBtn) //必须添加到contentView
        
        activityView = UIActivityIndicatorView(style: .white)
        activityView.frame = CGRect(x: 10, y: 10, width: 80, height: 80)
        activityView.isHidden = true
        blurView.contentView.addSubview(activityView)
        
        self.view.addSubview(blurView)
    }
}

extension ViewController: UITextFieldDelegate, UIGestureRecognizerDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.textField {
            sendAction(sendBtn)
            return true
        } else if textField == self.send3Text {
            send3Text2.becomeFirstResponder()
        } else if textField == self.send3Text2 {
            send3Text3.becomeFirstResponder()
        } else if textField == self.send3Text3 {
            send3Action(sendBtn3)
        } else if textField == self.textAction1 {
            textAction2.becomeFirstResponder()
        } else if textField == self.textAction2 {
            send4Action(sendBtn4)
        }
        return false
    }
    
    @objc func tapAction(_ gestureRecognizer: UITapGestureRecognizer) {
        self.textField.resignFirstResponder()
//        //下面是前一个按下变到后一个类似于tab键
//        self.textField.becomeFirstResponder()
    }
}

extension ViewController {
    func allBtnisHidden(_ ye: Bool) {
        self.sendBtn.isHidden = ye
        self.sendTraulBtn.isHidden = ye
        self.sendBtn3.isHidden = ye
        self.sendBtn4.isHidden = ye
    }
    
    func showErrorAlertWithTitle(_ title: String?, message: String?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(ac, animated: true)
    }
    
    func convertToUInts8Data(string: String) -> Data? {
        if let byte = UInt8(string) {
            return Data(bytes: [byte])
        }
        return nil
    }
    
}

