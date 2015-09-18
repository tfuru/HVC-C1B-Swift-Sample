//
//  ViewController.swift
//  HvcCSample
//
//  Created by 古川信行 on 2015/09/03.
//  Copyright (c) 2015年 古川信行. All rights reserved.
//

import UIKit

class ViewController: UIViewController,HVC_Delegate {
    
    //HVCを扱うクラス
    var hvc:HVC_BLE?
    
    var executeFlag:HVC_FUNCTION!
    
    //接続先デバイス名
    var connectDeviceName = "omron_hvc_F1:FD:6A:99:7D:AB"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //HVCを扱うクラス を初期化
        self.hvc = HVC_BLE()
        self.hvc?.delegateHVC = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func clickBtnSearch(sender: AnyObject) {
        //デバイス検索
        self.hvc?.deviceSearch();
        
        self.dispatchOnMainThread({ () -> () in
            //デバイス一覧を取得
            //omron_hvc_F1:FD:6A:99:7D:AB
            let deviseList:NSArray! = self.hvc?.getDevices()
            //println("deviseList:\(deviseList)")
            
            for d in deviseList {
                println("d:\(d)")
                let peripheral = d as? CBPeripheral
                if(peripheral != nil){
                    if peripheral!.name == self.connectDeviceName {
                        //接続
                        self.hvc?.connect(d as! CBPeripheral)
                    }
                }
            }
        }, delay: 10);
        
    }
    
    func onConnected() {
        println("onConnected")
        
        let param:HVC_PRM = HVC_PRM()
        param.face().setMinSize(60)
        param.face().setMaxSize(480)
        
        self.hvc?.setParam(param)
    }
    
    func onDisconnected(){
        println("onDisconnected")
    }
    
    func onPostGetDeviceName(value:NSData){
        println("onPostGetDeviceName value:\(value)")
    }
    
    func onPostSetParam(err:HVC_ERRORCODE,status:CUnsignedChar) {
        println("onPostSetParam")
        self.dispatchOnMainThread({ () -> () in
            // Set Execute Flag
            //顔検出,手認識,年齢,性別
            self.executeFlag = HVC_FUNCTION.ACTIV_FACE_DETECTION|HVC_FUNCTION.ACTIV_HAND_DETECTION|HVC_FUNCTION.ACTIV_AGE_ESTIMATION
            
            let res:HVC_RES = HVC_RES()
            
            self.hvc?.Execute(self.executeFlag, result: res)
        }, delay: 0)
    }
    
    func onPostExecute(result:HVC_RES,errcode:HVC_ERRORCODE,status:CUnsignedChar) {
        println("onPostExecute result:\(result)")
        
        if((errcode == HVC_ERRORCODE.NORMAL) && (status == 0)){
            //正常に何かを認識した
            // Face detection 顔認識した数
            println(" sizeFace:\( result.sizeFace() )")
            if(result.sizeFace() > 0){
                let fd:FaceResult = result.face(0);
                //年齢
                println(" age:\( fd.age().age() )")
            }
            
            // 手を認識した数
            println(" sizeHand:\( result.sizeHand() )")
            
            //再検索
            self.dispatchOnMainThread({ () -> () in
                // Set Execute Flag
                let res:HVC_RES = HVC_RES()
                self.hvc?.Execute(self.executeFlag, result: res)
            }, delay: 5)
        }
    }
    
    //ディレイ実行
    func dispatchOnMainThread(block: () -> (), delay: Double = 0) {
        if delay == 0 {
            dispatch_async(dispatch_get_main_queue()) {
                block()
            }
            return
        }
        
        let d = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(d, dispatch_get_main_queue()) {
            block()
        }
    }
}

