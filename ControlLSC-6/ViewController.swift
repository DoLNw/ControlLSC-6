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
    //MARK: - IBOutlet
    @IBOutlet weak var servoIDText1: UITextField!
    @IBOutlet weak var positionText1: UITextField!
    @IBOutlet weak var timeText1: UITextField!
    @IBOutlet weak var moveServoBtn1: UIButton!
    @IBAction func moveServo1(_ sender: UIButton) {
        guard let servoId = UInt8(servoIDText1.text!), let position = Int(positionText1.text!), let time = Int(timeText1.text!) else {
            showErrorAlertWithTitle("Unexpected Arguments", message: nil)
            return
        }
        
        guard self.characteristic != nil else { return }
        if let uint8s = LSC.moveServo(servoID: servoId, position: position, time: time) {
            self.peripheral.writeValue(Data(bytes: uint8s), for: self.characteristic, type: .withoutResponse)
        } else { showErrorAlertWithTitle("Unexpected", message: nil) }
    }
    
    @IBOutlet weak var numText2: UITextField!
    @IBOutlet weak var timeText2: UITextField!
    @IBOutlet weak var argsText2: UITextField!
    @IBOutlet weak var moveServosBtn2: UIButton!
    @IBAction func moveServos2(_ sender: UIButton) {
        guard self.characteristic != nil else { return }
        guard let num = UInt8(numText2.text!), let time = Int(timeText2.text!), let args = argsText2.text?.split(separator: " ") else {
            showErrorAlertWithTitle("Unexpected Arguments", message: nil)
            return
        }
        
        var tempArgs = [Int]()
        for arg in args {
            if let tempArg = Int(arg) { tempArgs.append(tempArg) }
            else { return }
        }
        
        if let uint8s = LSC.moveServos(num: num, time: time, tempArgs) {
            self.peripheral.writeValue(Data(bytes: uint8s), for: self.characteristic, type: .withoutResponse)
        } else { showErrorAlertWithTitle("Unexpected", message: nil) }
    }
    
    @IBOutlet weak var numberOfActionText3: UITextField!
    @IBOutlet weak var timeText3: UITextField!
    @IBOutlet weak var runActionGroupBtn3: UIButton!
    @IBAction func runActionGroup3(_ sender: UIButton) {
        guard self.characteristic != nil else { return }
        guard let numberOfAction = UInt8(numberOfActionText3.text!), let times = Int(timeText3.text!) else {
            showErrorAlertWithTitle("Unexpected Arguments", message: nil)
            return
        }
        
        if let uint8s = LSC.runActionGroup(numberOfAction: numberOfAction, times: times) {
            self.peripheral.writeValue(Data(bytes: uint8s), for: self.characteristic, type: .withoutResponse)
        } else { showErrorAlertWithTitle("Unexpected", message: nil) }
    }
    
    @IBOutlet weak var stopActionGroupBtn4: UIButton!
    @IBAction func stopActionGroup4(_ sender: UIButton) {
        guard self.characteristic != nil else { return }
        if let uint8s = LSC.stopActionGroup() {
            self.peripheral.writeValue(Data(bytes: uint8s), for: self.characteristic, type: .withoutResponse)
        } else { showErrorAlertWithTitle("Unexpected", message: nil) }
    }
    
    @IBOutlet weak var numberOfActionText5: UITextField!
    @IBOutlet weak var speedText5: UITextField!
    @IBOutlet weak var setActionGroupSpeedBtn5: UIButton!
    @IBAction func setActionGroupSpeed5(_ sender: UIButton) {
        guard self.characteristic != nil else { return }
        guard let numberOfAction = UInt8(numberOfActionText5.text!), let speed = Int(speedText5.text!) else {
            showErrorAlertWithTitle("Unexpected Arguments", message: nil)
            return
        }
        
        if let uint8s = LSC.setActionGroupSpeed(numberOfAction: numberOfAction, speed: speed) {
            self.peripheral.writeValue(Data(bytes: uint8s), for: self.characteristic, type: .withoutResponse)
        } else { showErrorAlertWithTitle("Unexpected", message: nil) }
    }
    
    @IBOutlet weak var speedText6: UITextField!
    @IBOutlet weak var setAccActionGroupSpeedBtn6: UIButton!
    @IBAction func setAllActionGroupSpeed6(_ sender: UIButton) {
        guard self.characteristic != nil else { return }
        guard let speed = Int(speedText6.text!) else {
            showErrorAlertWithTitle("Unexpected Arguments", message: nil)
            return
        }
        
        if let uint8s = LSC.setAllActionGroupSpeed(speed: speed) {
            self.peripheral.writeValue(Data(bytes: uint8s), for: self.characteristic, type: .withoutResponse)
        } else { showErrorAlertWithTitle("Unexpected", message: nil) }
    }
    
    @IBOutlet weak var getBatteryVoltageBtn7: UIButton!
    @IBAction func getBatteryVoltage7(_ sender: UIButton) {
        guard self.characteristic != nil else { return }
        if let uint8s = LSC.getBatteryVoltage() {
            self.peripheral.writeValue(Data(bytes: uint8s), for: self.characteristic, type: .withoutResponse)
        } else { showErrorAlertWithTitle("Unexpected", message: nil) }
    }
    
    
    @IBOutlet weak var instructiosTextView: UITextView!
    @IBOutlet weak var receiveTextView: UITextView!
    
    var receiveStr = "" {
        didSet {
            DispatchQueue.main.sync { [unowned self] in
                self.receiveTextView.text = self.receiveStr
                self.receiveTextView.scrollRangeToVisible(NSRange(location: self.receiveTextView.text.lengthOfBytes(using: .utf8), length: 1))
            }
        }
    }
    
    
    //MARK: - Property
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
    
    
    //MARK: - Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "UnConnected"
        
        ViewController.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
        self.blueDisplay()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        
        self.instructiosTextView.text = """
        作用   帧头 长度指令 参数
        舵机  55 55 08 03 01 E8 03 01 D0 07
        舵机  55 55 0B 03 02 20 03 02 B0 04 03 B0 04(舵机2、3号都到1200位置)
        动组  55 55 05 06 08 01 00
        动组  55 55 05 06 02 00 00
        停止  55 55 02 07
        速度  55 55 05 0B 08 32 00(注意只控制动作组的百分比50)
        速度  55 55 05 0B FF 2C 01(百分比300)
        电压  55 55 02 0F
        """
        
        timeText1.delegate = self
        positionText1.delegate = self
        servoIDText1.delegate = self
        argsText2.delegate = self
        timeText2.delegate = self
        numText2.delegate = self
        timeText3.delegate = self
        numberOfActionText3.delegate = self
        speedText5.delegate = self
        numberOfActionText5.delegate = self
        speedText6.delegate = self
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
            //动作组开始执行，动作组自然结束执行，动作组被其他方式停止，还有获取电压时才会有返回
            let valueData = characteristic.value!
            let data = NSData(data: valueData)
            
            let valueStr = data.description.replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "").replacingOccurrences(of: " ", with: "").uppercased()
            
            // 注意：动作组刚执行时：返回的事55550506~~~,然后动作组结束返回55550508～～～。还有暂停的时候会返回5555020755550207（不知为何返回的都是两遍）。然后还有读取电压会返回接近于5555040F8718的数字，直接控制单个舵机，和改变动作组速度貌似不会有返回数据。
            
            if valueStr.hasPrefix("5555040F") {
//                let start = value.index(value.startIndex, offsetBy: 8)
//                let end = value.index(value.startIndex, offsetBy: 9)
//                value[start...end]
//                let uint8s = characteristic.value!.withUnsafeBytes{[UInt8](UnsafeBufferPointer(start: $0,  count: characteristic.value!.count))}
                
                let bytes = [UInt8](valueData)
                receiveStr += "BatteryVolt: \(Int(bytes[5])*256+Int(bytes[4]))mv\n"
            } else {
                receiveStr += "\(valueStr)\n"
            }
            
        }

    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Notidied")
    }
    
}


//MARK: - TextField and Gesture Delegate
extension ViewController: UITextFieldDelegate, UIGestureRecognizerDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == servoIDText1 { positionText1.becomeFirstResponder() }
        else if textField == positionText1 { timeText1.becomeFirstResponder() }
        else if textField == timeText1 { moveServo1(moveServoBtn1) }
        else if textField == numText2 { timeText2.becomeFirstResponder() }
        else if textField == timeText2 { argsText2.becomeFirstResponder() }
        else if textField == argsText2 { moveServos2(moveServosBtn2) }
        else if textField == numberOfActionText3{ timeText3.becomeFirstResponder() }
        else if textField == timeText3 { runActionGroup3(runActionGroupBtn3) }
        else if textField == numberOfActionText5{ speedText5.becomeFirstResponder() }
        else if textField == speedText5 { setActionGroupSpeed5(setActionGroupSpeedBtn5) }
        else if textField == speedText6 { setAllActionGroupSpeed6(setAccActionGroupSpeedBtn6) }
        else { return true }
        return false
    }
    
    @objc func tapAction(_ gestureRecognizer: UITapGestureRecognizer) {
        
//        self.textField.resignFirstResponder()
//        //下面是前一个按下变到后一个类似于tab键
//        self.textField.becomeFirstResponder()
    }
}


//MARK: - Extral Methods
extension ViewController {
    func allBtnisHidden(_ ye: Bool) {
        self.moveServoBtn1.isHidden = ye
        self.moveServosBtn2.isHidden = ye
        self.runActionGroupBtn3.isHidden = ye
        self.stopActionGroupBtn4.isHidden = ye
        self.setActionGroupSpeedBtn5.isHidden = ye
        self.setAccActionGroupSpeedBtn6.isHidden = ye
        self.getBatteryVoltageBtn7.isHidden = ye
    }
    
    func showErrorAlertWithTitle(_ title: String?, message: String?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(ac, animated: true)
    }
}


//MARK: - Extral Displays
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
