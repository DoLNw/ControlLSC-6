//
//  LSC.swift
//  ControlLSC-6
//
//  Created by JiaCheng on 2018/11/27.
//  Copyright © 2018 JiaCheng. All rights reserved.
//
class LSC {
    static let frame_header_half: UInt8 = 0x55        //帧头
    static let CMD_SERVO_MOVE: UInt8 = 0x03           //舵机移动指令,数据长度 Length =控制舵机的个数×3+5
    static let CMD_ACTION_GROUP_RUN: UInt8 = 0x06     //运行动作组指令,数据长度 Length=5
    static let CMD_ACTION_GROUP_STOP: UInt8 = 0x07    //停止动作做指令,数据长度 Length=2
    static let CMD_ACTION_GROUP_SPEED: UInt8 = 0x0B   //设置动作组运行速度,数据长度 Length=5
    static let CMD_GET_BATTERY_VOLTAGE:UInt8 = 0x0F   //获取电池电压指令,数据长度 Length=2
    
    static func moveServo(servoID: UInt8, position: Int, time: Int) -> [UInt8]? {
        guard servoID<31 || time>0 else { return nil }
        
        var dataout = [frame_header_half, frame_header_half, 8, CMD_SERVO_MOVE]
        dataout += [1, UInt8(time%256), UInt8(time/256), servoID, UInt8(position%256), UInt8(position/256)]
        
        return dataout
    }
    
    //func moveServos(num: UInt8, time: Int, _ args: Int...)
    static func moveServos(num: UInt8, time: Int, _ args: [Int]) -> [UInt8]? {
        guard num>=1 || num<=32 || time>0 else { return nil }
        guard args.count == num*2 else { return nil }
        
        var dataout = [frame_header_half, frame_header_half, UInt8(num*3+5), CMD_SERVO_MOVE, num, UInt8(time%256), UInt8(time/256)]
        
        var temp = args
        for _ in 0..<num {
            dataout += [UInt8(temp.removeFirst()), UInt8(temp.first!%256), UInt8(temp.removeFirst()/256)]
        }
        
        return dataout
    }
    
    static func runActionGroup(numberOfAction: UInt8, times: Int) -> [UInt8]? {
        let dataout = [frame_header_half, frame_header_half, 5, CMD_ACTION_GROUP_RUN, numberOfAction, UInt8(times%256), UInt8(times/256)]
        
        return dataout
    }
    
    static func stopActionGroup() -> [UInt8]? {
        let dataout = [frame_header_half, frame_header_half, 2, CMD_ACTION_GROUP_STOP]
        
        return dataout
    }
    
    static func setActionGroupSpeed(numberOfAction: UInt8, speed: Int) -> [UInt8]? {
        let dataout = [frame_header_half, frame_header_half, 5, CMD_ACTION_GROUP_SPEED, numberOfAction, UInt8(speed%256), UInt8(speed/256)]
        
        return dataout
    }
    
    static func setAllActionGroupSpeed(speed: Int) -> [UInt8]? {
        return LSC.setActionGroupSpeed(numberOfAction: 0xFF, speed: speed)
    }
    
    static func getBatteryVoltage() -> [UInt8]? {
        let dataout = [frame_header_half, frame_header_half, 2, CMD_GET_BATTERY_VOLTAGE]
        
        return dataout
    }
    
    static func reset() -> [UInt8]? {
        return LSC.moveServos(num: 6, time: 1000, [1, 2400, 2, 1500, 3, 1000, 4, 1000, 5, 500, 6, 2000])
    }
    
    static func scratchHigh() -> [UInt8]? {
        return LSC.runActionGroup(numberOfAction: 0, times: 1)
    }
    
    static func scratchMiddle() -> [UInt8]? {
        return LSC.runActionGroup(numberOfAction: 4, times: 1)
    }
    
    static func scratchLow() -> [UInt8]? {
        return LSC.runActionGroup(numberOfAction: 1, times: 1)
    }
    
    static func putHigh() -> [UInt8]? {
        return LSC.runActionGroup(numberOfAction: 3, times: 1)
    }
    
    static func putLow() -> [UInt8]? {
        return LSC.runActionGroup(numberOfAction: 2, times: 1)
    }
    
    static func free() -> [UInt8]? {
        return nil
    }
    
    static func free_sww() -> [UInt8]? {
        return LSC.moveServo(servoID: 1, position: 1800, time: 1000)
    }
    
}

