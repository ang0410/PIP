//
//  RGAESEncryptDecrypt.swift
//  Rgbee
//
//  Created by an chieh huang on 2020/1/10.
//  Copyright © 2020 An Chieh Huang. All rights reserved.
//

import Foundation
import CryptoSwift

class RGAESEncryptDecrypt {
    
    static let share = RGAESEncryptDecrypt()

    func aesDecrypt(productId: Int, data: Data) -> UIImage? {
        var result: Data!
        let key = generateKey(productId)
        
        // 用AES方式將Data解密
        guard let aesDec = try? AES(key: key, blockMode: ECB(), padding: .pkcs7) else {return nil}
        guard let dec = try? aesDec.decrypt(data.bytes) else {return nil}
        
        // 用UTF8的編碼方式將解完密的Data轉回字串
        result = Data(bytes: dec, count: dec.count)
        return UIImage(data: result)
    }
    
    func generateKey(_ productid: Int) -> [UInt8] {

        let nLong: CLong = 7393913*productid+productid*productid+920
        
        var skey = "\(nLong)"
        for _ in 0..<16-String(nLong).count {
            skey.insert("0", at: skey.index(skey.startIndex, offsetBy: 0))
        }

        var key = [UInt8](repeating: UInt8(), count: 16)
        
        let skeyArray = skey.map({$0})
        for index in 0..<key.count {
            guard let skeyUInt8 = UInt8(String(skeyArray[index])) else {continue}
            key[index] = skeyUInt8
        }
        return key
    }
}
