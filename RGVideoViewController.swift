//
//  RGVideoViewController.swift
//  Rgbee
//
//  Created by an chieh huang on 2019/11/11.
//  Copyright © 2019 An Chieh Huang. All rights reserved.
//

import Foundation
import AVKit

class RGVideoViewController: RGBaseViewController {
    
    @IBOutlet weak var closeButton: UIButton! {
        didSet {
            let image = UIImage(named: "icon-arrow_back-white-24")?.withRenderingMode(.alwaysTemplate)
            closeButton.tintColor = .white
            closeButton.setImage(image, for: .normal)
        }
    }
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var totalLengthLabel: UILabel! {
        didSet {
            totalLengthLabel.textColor = .white
        }
    }
    @IBOutlet weak var currentLengthLabel: UILabel! {
        didSet {
            currentLengthLabel.textColor = .white
        }
    }
    @IBOutlet weak var progressSlider: UISlider! {
        didSet {
            progressSlider.tintColor = .white
        }
    }
    @IBOutlet weak var playPauseButton: UIButton! {
        didSet {
            playPauseButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            playPauseButton.layer.cornerRadius = playPauseButton.frame.width/2
            playPauseButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
            playPauseButton.tintColor = .white
        }
    }
    @IBOutlet weak var speakerButton: UIButton! {
        didSet {
            speakerButton.tintColor = .white
            speakerButton.setImage(UIImage(named: "icon-volume_up-white-24"), for: .normal)
        }
    }
    @IBOutlet weak var operationView: UIView! {
        didSet {
            operationView.backgroundColor = .clear
        }
    }
    @IBOutlet weak var sliderBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bottomOperactionView: UIView!
    @IBOutlet weak var blackView: UIView!
    
    var operationTimer: Timer!
    var touchView: UIView!
    
    private var playerItem: AVPlayerItem!
    var player: AVPlayer!
    private var playerLayer: AVPlayerLayer! {
        didSet {
            playerLayer.videoGravity = .resizeAspect
        }
    }

    var viewModel: RGVideoViewModel!

    deinit {
        playerItem = nil
        playerLayer = nil
        player?.currentItem?.cancelPendingSeeks()
        player?.currentItem?.asset.cancelLoading()
        player = nil
        
        operationTimer?.invalidate()
        operationTimer = nil
        NotificationCenter.default.removeObserver(self)
   
        RGAppLockOrientation.lockOrientation(.portrait)
        guard !RGConfig.sharedConfig.deviceIsPad else {return}
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        removeCurrentVideoView()
        RGAppLockOrientation.lockOrientation(.all)
        initVideoView()
        updatePlayerUI()
        addPeriodicTimeObserver()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sliderTapped(_:)))
        progressSlider.addGestureRecognizer(tapGesture)
        
        let tapView = UITapGestureRecognizer(target: self, action: #selector(showOperationView(_:)))
        view.addGestureRecognizer(tapView)

        pauseResume(isPaused: false)
        
        progressSlider.setThumbImage(getSliderThumberImage(size: CGSize(width: 14, height: 14), backgroundColor: .white), for: .normal)
        progressSlider.setThumbImage(getSliderThumberImage(size: CGSize(width: 14, height: 14), backgroundColor: .white), for: .highlighted)
        
        screenCaptureChanged()
        setOperationViewOrigin()
        
        NotificationCenter.default.addObserver(self, selector: #selector(detectScreenShoot), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenCaptureChanged), name: UIScreen.capturedDidChangeNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let currentTime = CMTimeGetSeconds(player.currentTime())
        RGAPI.sharedAPI.syncReadingProgress(documentId: viewModel.documentId, type: "VIDEO", position: 0, sequence: Int(currentTime), completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
    }
    
    override func didRotateAction(notification: Notification) {
        
        if UIScreen.main.isCaptured {
            DispatchQueue.main.async {[weak self] in
                guard let self = self else {return}
                RGWatermarkView.share.addWatermarkLabel(targetView: self.videoView)
            }
        }
        
        setOperationViewOrigin()
        
        guard viewModel?.isPIPView == false else {return}
        DispatchQueue.main.async {[weak self] in
            guard let self = self else {return}
            self.view.frame.size.width = UIScreen.main.bounds.width
            self.view.frame.size.height = UIScreen.main.bounds.height
            self.view.layer.cornerRadius = 0
            self.view.frame.origin = CGPoint(x: 0, y: 0)
        }
    }
    
    private func setOperationViewOrigin() {
        let orientation = UIDevice.current.orientation
        if orientation == .landscapeLeft || orientation == .landscapeRight {
            sliderBottomConstraint.constant = 10
            bottomOperactionView.isHidden = true
        } else {
            let videoHeight = viewModel?.videoHeight ?? 0
            sliderBottomConstraint.constant = view.frame.height/2 - videoHeight/2 - progressSlider.frame.height
            bottomOperactionView.isHidden = false
        }
    }
    
    @objc func detectScreenShoot() {
        
        let count = RGUserDefaults.share.getIntUserDefaults(RGSaveKeyItem().screenShootCount)
        if count+1 >= 3 {
            RGUserDefaults.share.setIntUserDefaults(RGSaveKeyItem().screenShootCount, value: 0)

            RGWatermarkView.share.addWatermarkLabel(targetView: videoView)
            
            let controller = UIAlertController(title: NSLocalizedString("copyrightProtection"), message: NSLocalizedString("toProtectRightsOfYou"), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("OK"), style: .default)
            controller.addAction(okAction)
            RGTopViewController.shareDefault.topViewController().present(controller, animated: true, completion: nil)
            return
        }
        
        RGUserDefaults.share.setIntUserDefaults(RGSaveKeyItem().screenShootCount, value: count+1)
    }
    
    @objc func screenCaptureChanged() {

        if UIScreen.main.isCaptured {
            RGWatermarkView.share.addWatermarkLabel(targetView: videoView)
            
            let controller = UIAlertController(title: NSLocalizedString("copyrightProtection"), message: NSLocalizedString("toProtectRightsOfYou"), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("OK"), style: .default)
            controller.addAction(okAction)
            RGTopViewController.shareDefault.topViewController().present(controller, animated: true, completion: nil)
            
        } else {
            RGWatermarkView.share.removeWatermarkLabel()
        }
    }
    
    fileprivate func getSliderThumberImage(size: CGSize, backgroundColor: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(backgroundColor.cgColor)
        context?.setStrokeColor(UIColor.clear.cgColor)
        let bounds = CGRect(origin: .zero, size: size)
        context?.addEllipse(in: bounds)
        context?.drawPath(using: .fill)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private func addPeriodicTimeObserver() {
        player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 60), queue: DispatchQueue.main, using: {[weak self] (_) in
            
            guard let self = self else {return}
            guard self.player.currentItem?.status == .readyToPlay else {return}
            
            let currentTime = CMTimeGetSeconds(self.player.currentTime())
            self.progressSlider.value = Float(currentTime)
            self.currentLengthLabel.text = self.viewModel?.formatConversion(time: currentTime)
            self.resetCurrentTime()
        })
    }
    
    @objc func sliderTapped(_ gesture: UIGestureRecognizer) {

        guard let slider = gesture.view as? UISlider else {return}

        let point = gesture.location(in: slider)
        let percentage = point.x / (slider.bounds.size.width)
        let delta = Float(percentage) * Float(slider.maximumValue - slider.minimumValue)
        let value = slider.minimumValue + delta
        slider.setValue(Float(value), animated: true)

        changeCurrentTime(progressSlider)
    }
    
    @objc func showOperationView(_ gesture: UIGestureRecognizer) {
        
        if Int(operationView.alpha) == 0 {
            operationView.alpha = 1
            playPauseButton.alpha = 1
            pauseResume(isPaused: false)
            return
        }
        operationView.alpha = 0
        playPauseButton.alpha = 0
    }
    
    @objc private func hiddenOperationViewAnimation() {
        UIView.animate(withDuration: 0.3, animations: {[weak self] in
            guard let self = self else {return}
            self.operationView.alpha = 0
            self.playPauseButton.alpha = 0
        })
    }
    
    func pauseResume(isPaused: Bool) {
        if isPaused {
            operationTimer?.invalidate()
        } else {
            operationTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(hiddenOperationViewAnimation), userInfo: nil, repeats: false)
        }
    }
    
    private func resetCurrentTime() {
        guard totalLengthLabel.text == currentLengthLabel.text else {return}
        playPauseButton.setImage(UIImage(named: "icon_video_btnplay-48"), for: .normal)
        player?.pause()
        let targetSeconds = Int64(viewModel.startTime)
        player?.seek(to: CMTimeMake(value: targetSeconds, timescale: 1))
        progressSlider.value = viewModel.startTime
        operationView.alpha = 1
    }
    
    private func initVideoView() {
        guard let url = viewModel?.videoURL else {return}

        let asset = AVAsset(url: url)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)

        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.view.bounds

        videoView.layer.addSublayer(playerLayer)

        player.play()
    }
    
    func updatePlayerUI() {

        let duration = viewModel.isPreview ? viewModel.endTime : playerItem.asset.duration
        let seconds = CMTimeGetSeconds(duration)

        totalLengthLabel.text = viewModel?.formatConversion(time: seconds)
        progressSlider.minimumValue = viewModel.startTime
        progressSlider.maximumValue = Float(seconds)
        
        // 這裡看個人需求，如果想要拖動後才更新進度，那就設為 false；如果想要直接更新就設為 true，預設為 true。
        progressSlider.isContinuous = true
        playPauseButton.setImage(UIImage(named: "icon_video_btnstop-48"), for: .normal)
        
        let targetSeconds = viewModel.currentTime != 0 ? Int64(viewModel.currentTime) : Int64(viewModel.startTime)
        let targetTime = CMTimeMake(value: targetSeconds, timescale: 1)
        player.seek(to: targetTime)
    }
    
    @IBAction func changeCurrentTime(_ sender: UISlider) {
        let seconds = Int64(progressSlider.value)
        let targetTime = CMTimeMake(value: seconds, timescale: 1)
        
        // 將當前設置時間設為播放時間
        player.seek(to: targetTime)
    }
    
    @IBAction func sliderTouchDown(_ sender: UISlider) {
        setPauseButton()
        player.pause()
    }
    
    @IBAction func sliderTouchUp(_ sender: UISlider) {
        setPlayButton()
        player.play()
    }
    
    @IBAction func closeAction(sender: UIButton) {
        player.pause()
        
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            guard let self = self else { return }
            self.view.frame.origin.y = self.view.frame.height
        }) {[weak self](_) in
            guard let self = self else { return }
            self.releasePlayer()
        }
        //self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func playAndPause(_ sender: UIButton) {
        (player?.rate == 0) ? setPlayButton() : setPauseButton()
    }
    
    private func setPauseButton() {
        playPauseButton.setImage(UIImage(named: "icon_video_btnplay-48"), for: .normal)
        pauseResume(isPaused: true)
        player?.pause()
    }
    
    private func setPlayButton() {
        playPauseButton.setImage(UIImage(named: "icon_video_btnstop-48"), for: .normal)
        pauseResume(isPaused: false)
        player?.play()
    }
    
    @IBAction func speakerAction(sender: UIButton) {
        player.isMuted = !player.isMuted
        player.volume = player.isMuted ? 0 : 1
        let speakerImage = player.isMuted ? "icon-volume_off-white-24" : "icon-volume_up-white-24"
        speakerButton.setImage(UIImage(named: speakerImage), for: .normal)
    }
    
    @IBAction func pIPAction(sender: UIButton) {
        showPIPView()
    }
    
    @IBAction func subtitleAction(sender: UIButton) {
        guard let alertController = UIStoryboard.alertViewStoryboard().instantiateViewController(withIdentifier: "AlertView") as? RGAlertViewController else {return}
        alertController.delegate = self
        alertController.viewModel = RGAlertViewModel(alert: self.viewModel.subTitleAlertArray)
        alertController.modalPresentationStyle = .overFullScreen
        RGTopViewController.shareDefault.topNavigationController()?.present(alertController, animated: false, completion: nil)
    }
    
    @IBAction func settingAction(sender: UIButton) {
        guard let alertController = UIStoryboard.alertViewStoryboard().instantiateViewController(withIdentifier: "AlertView") as? RGAlertViewController else {return}
        alertController.delegate = self
        alertController.viewModel = RGAlertViewModel(alert: self.viewModel.qualityAlertArray)
        alertController.modalPresentationStyle = .overFullScreen
        RGTopViewController.shareDefault.topNavigationController()?.present(alertController, animated: false, completion: nil)
    }
    
    @IBAction func compactAction(sender: UIButton) {
        print("compact")
    }
    
    @IBAction func favoriteAction(sender: UIButton) {
        print("favorite")
    }
}

extension RGVideoViewController: RGAlertViewDelegate {
    func didSelectedItem(index: Int) {

    }
}
