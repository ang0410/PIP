//
//  RGVideoViewModel.swift
//  Rgbee
//
//  Created by an chieh huang on 2019/11/11.
//  Copyright © 2019 An Chieh Huang. All rights reserved.
//

import AVKit
import Foundation

class RGVideoViewModel {

    var isPIPView: Bool = false
    let videoHeight: CGFloat = 210
    let videoURL: URL!
    var totalTime: CGFloat = 0.0
    var documentId: Int = 0

    let subTitleAlertArray = [
        RGAlertItem(titeName: NSLocalizedString("langZHTW"), image: "", needDetectNetwork: true),
        RGAlertItem(titeName: NSLocalizedString("langZHCN"), image: "", needDetectNetwork: true),
        RGAlertItem(titeName: NSLocalizedString("langTH"), image: "", needDetectNetwork: true),
        RGAlertItem(titeName: NSLocalizedString("langEN"), image: "", needDetectNetwork: true),
        RGAlertItem(titeName: NSLocalizedString("langJA"), image: "", needDetectNetwork: true)
    ]
    
    let qualityAlertArray = [
        RGAlertItem(titeName: NSLocalizedString("auto") + "-480P", image: "", needDetectNetwork: true),
        RGAlertItem(titeName: NSLocalizedString("720P"), image: "", needDetectNetwork: true),
        RGAlertItem(titeName: NSLocalizedString("480P"), image: "", needDetectNetwork: true),
        RGAlertItem(titeName: NSLocalizedString("360P"), image: "", needDetectNetwork: true)
    ]
    
    var startTime: Float = 10
    var endTime = CMTime(seconds: 30, preferredTimescale: 1)
    var isPreview = false
    var currentTime = 0
    
    init(urlString: String, preview: Bool, documentId: Int, currentTime: Int, start: Float = 0, end: Float = 0) {
        videoURL = URL(string: urlString)
        isPreview = preview
        startTime = start
        endTime = CMTime(seconds: Double(end), preferredTimescale: 1)
        self.documentId = documentId
        self.currentTime = currentTime
    }
    
    func formatConversion(time: Float64) -> String {
        let songLength = Int(time)
        let minutes = Int(songLength / 60) // 求 Length 的商，為分鐘數
        let seconds = Int(songLength % 60) // 求 Length 的餘數，為秒數

        let fixMinutes = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        let fixSeconds = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        return "\(fixMinutes):\(fixSeconds)"
    }
}
