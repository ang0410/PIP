//
//  RGVideoViewController+PIP.swift
//  Rgbee
//
//  Created by an chieh huang on 2020/1/7.
//  Copyright © 2020 An Chieh Huang. All rights reserved.
//

import Foundation
import AVKit

extension RGVideoViewController {
    
    func showPIPView() {

        self.view.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin]
        
        self.setTouchEvent()

        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIView.AnimationOptions(), animations: {[weak self] in
            guard let self = self else {return}
            self.view.frame.size.width = (RGConfig.sharedConfig.deviceIsPad) ? 300 : 160
            self.view.frame.size.height = (RGConfig.sharedConfig.deviceIsPad) ? 200 : 90

            let marginWithScreen: CGFloat = 15
            let bottomHeight: CGFloat =
                (RGTopViewController.shareDefault.topNavigationController()?.navigationBar.isHidden == true) ? 0 : 44
            self.view.frame.origin.y = UIScreen.main.bounds.height - self.view.frame.height - marginWithScreen - bottomHeight
            self.view.frame.origin.x = UIScreen.main.bounds.width - self.view.frame.width - marginWithScreen

            self.view.layer.borderWidth = 2
            self.view.layer.borderColor = UIColor.white.cgColor

            }, completion: {[weak self](_) in
                guard let self = self else {return}
                self.operationView.isHidden = true
                self.playPauseButton.isHidden = true
                self.viewModel?.isPIPView = true
                
                if !RGConfig.sharedConfig.deviceIsPad {
                    RGAppLockOrientation.lockOrientation(.portrait)
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                }
        })
    }
    
    func addVideoView() {

        guard let parentViewController = RGTopViewController.shareDefault.topViewController() as? RGTabBarController else {return}
        
        releasePlayer()

        self.view.tag = 100
        parentViewController.coverTopViewController = self
        parentViewController.view.addSubview(self.view)
        self.didMove(toParent: parentViewController)
        
        self.view.autoresizingMask = [.flexibleHeight, .flexibleTopMargin, .flexibleBottomMargin]
        self.view.frame.size.width = UIScreen.main.bounds.width
        self.view.frame.size.height = UIScreen.main.bounds.height
        self.view.frame.origin.y = UIScreen.main.bounds.height
        self.view.frame.origin.x = UIScreen.main.bounds.origin.x
        self.view.layer.cornerRadius = 0
        self.view.clipsToBounds = true

        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIView.AnimationOptions(), animations: {[weak self] in
            guard let self = self else {return}
            self.view.frame.origin = CGPoint(x: 0, y: 0)
        }, completion: nil)
        
        parentViewController.navigationController?.view.bringSubviewToFront(view)
    }
    
    func releasePlayer() {
        
        guard let parentViewController = RGTopViewController.shareDefault.topViewController() as? RGTabBarController else {return}
        parentViewController.coverTopViewController = nil

        if parentViewController.view.subviews.filter({$0.tag == 100}).isEmpty == false {
        
            if let videoView = parentViewController.view.viewWithTag(100)?.parentViewController() as? RGVideoViewController {
                videoView.player?.currentItem?.cancelPendingSeeks()
                videoView.player?.currentItem?.asset.cancelLoading()
                videoView.operationTimer?.invalidate()
                videoView.operationTimer = nil
                videoView.removeFromParent()
                videoView.view.removeFromSuperview()
                
                operationTimer?.invalidate()
                operationTimer = nil

                self.removeFromParent()
                self.view.removeFromSuperview()
            }
            
            let currentTime = CMTimeGetSeconds(player.currentTime())
            RGAPI.sharedAPI.syncReadingProgress(documentId: viewModel.documentId, type: "VIDEO", position: 0, sequence: Int(currentTime), completion: nil)
            
            self.willMove(toParent: nil)
            parentViewController.view.viewWithTag(100)?.removeFromSuperview()
        }
    }
    
    func removeCurrentVideoView() {
        guard let parentViewController = RGTopViewController.shareDefault.topViewController() else {return}
        for childView in parentViewController.children {
            guard let videoView = childView as? RGVideoViewController else {continue}
            videoView.releasePlayer()
            break
        }
    }
    
    func setTouchEvent() {

        self.touchView = UIView(frame: self.view.frame)

        let panner = UIPanGestureRecognizer(target: self, action: #selector(panDidFire))
        self.touchView.addGestureRecognizer(panner)

        let tapped = UITapGestureRecognizer(target: self, action: #selector(tapDidFire))
        self.touchView.addGestureRecognizer(tapped)

        self.view.addSubview(touchView)
    }
    
    @objc func tapDidFire(_ tapped: UITapGestureRecognizer) {

        viewModel?.isPIPView = false
        self.touchView?.removeFromSuperview()
        self.view.layer.borderWidth = 0
        self.view.autoresizingMask = [.flexibleHeight, .flexibleTopMargin]

        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIView.AnimationOptions(), animations: {[weak self] in
            guard let self = self else {return}
            self.view.frame.size.width = UIScreen.main.bounds.width
            self.view.frame.size.height = UIScreen.main.bounds.height
            self.view.layer.cornerRadius = 0
            self.view.frame.origin = CGPoint(x: 0, y: 0)

           }, completion: {[weak self](_) in
            guard let self = self else {return}
            self.modalPresentationStyle = .fullScreen
            self.operationView.isHidden = false
            self.playPauseButton.isHidden = false
            RGAppLockOrientation.lockOrientation(.all)
        })
        RGTopViewController.shareDefault.topViewController()?.view.bringSubviewToFront(view)
    }

    @objc func panDidFire(_ panner: UIPanGestureRecognizer) {

       guard viewModel?.isPIPView == true else {return}

       //判斷是否快速滑動
       if panner.state == .ended {
           let velocityPoint = panner.velocity(in: self.view)
           if abs(velocityPoint.x) > 2000 || abs(velocityPoint.y) > 2000 {
              self.panVelocity(self.panDirection(velocityPoint))
           }
       }

       let offset = panner.translation(in: view)
       panner.setTranslation(CGPoint.zero, in: view)
       var center = self.view.center
       center.x += offset.x
       center.y += offset.y
       self.view.center = center

       self.view.alpha = self.setViewAlpha()

       if panner.state == .ended || panner.state == .cancelled {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIView.AnimationOptions(), animations: {[weak self] in
                guard let self = self else {return}
                self.snapViewToSocket()
           }, completion: nil)
       }
   }
    
    fileprivate func setViewAlpha() -> CGFloat {

        if self.view.frame.origin.x <= 0 {
            return (self.view.frame.width + self.view.frame.origin.x) / self.view.frame.width
        }

        if self.view.frame.origin.y <= 0 {
            return (self.view.frame.height + self.view.frame.origin.y) / self.view.frame.height
        }

        if self.view.frame.origin.x + self.view.frame.width >= UIScreen.main.bounds.width {
            return (UIScreen.main.bounds.width - self.view.frame.origin.x) / self.view.frame.width
        }

        if self.view.frame.origin.y + self.view.frame.height >= UIScreen.main.bounds.height {
            return (UIScreen.main.bounds.height - self.view.frame.origin.y) / self.view.frame.height
        }
        return 1
    }
    
    fileprivate func panDirection(_ velocityPoint: CGPoint) -> UISwipeGestureRecognizer.Direction? {

        if abs(velocityPoint.x) > abs(velocityPoint.y) {//水平

            if velocityPoint.x > 0 {//向右
                return UISwipeGestureRecognizer.Direction.right
            } else if velocityPoint.x < 0 {//向左
                return UISwipeGestureRecognizer.Direction.left
            }

        } else if abs(velocityPoint.x) < abs(velocityPoint.y) {//垂直

            if velocityPoint.y > 0 {//向下
                return UISwipeGestureRecognizer.Direction.down
            } else if velocityPoint.y < 0 {//向上
                return UISwipeGestureRecognizer.Direction.up
            }
        }

        return nil
    }
    
    fileprivate func panVelocity(_ panned: UISwipeGestureRecognizer.Direction?) {

        guard let direction = panned else {return}

        switch direction {

        case UISwipeGestureRecognizer.Direction.up:
            self.removeAVView(CGPoint(x: self.view.frame.origin.x, y: 0))

        case UISwipeGestureRecognizer.Direction.down:
            self.removeAVView(CGPoint(x: self.view.frame.origin.x, y: UIScreen.main.bounds.height))

        case UISwipeGestureRecognizer.Direction.left:
            self.removeAVView(CGPoint(x: 0, y: self.view.frame.origin.y))

        case UISwipeGestureRecognizer.Direction.right:
            self.removeAVView(CGPoint(x: UIScreen.main.bounds.width, y: self.view.frame.origin.y))

        default:
            break
        }
    }

    fileprivate func snapViewToSocket() {

        guard self.view != nil else {return}

        let minPanding: CGFloat = 10

        if self.view.frame.origin.x <= 0 {

            if self.view.center.x >= minPanding {
                self.view.frame.origin.x = minPanding
                self.view.alpha = 1
                return
            }
            self.removeAVView(CGPoint(x: -self.view.frame.width, y: self.view.frame.origin.y))
            return
        }

        if self.view.frame.origin.y <= 0 {

            if self.view.center.y >= minPanding {
                self.view.frame.origin.y = minPanding
                self.view.alpha = 1
                return
            }
            self.removeAVView(CGPoint(x: self.view.frame.origin.x, y: -self.view.frame.height))
            return
        }

        if self.view.frame.origin.x + self.view.frame.width >= UIScreen.main.bounds.width {

            if UIScreen.main.bounds.width - self.view.center.x >= minPanding {
                self.view.frame.origin.x = UIScreen.main.bounds.width - self.view.frame.width - minPanding
                self.view.alpha = 1
                return
            }
            self.removeAVView(CGPoint(x: UIScreen.main.bounds.width + self.view.frame.width, y: self.view.frame.origin.y))
            return
        }

        if self.view.frame.origin.y + self.view.frame.height >= UIScreen.main.bounds.height {
            if UIScreen.main.bounds.height - self.view.center.y >= minPanding {
                self.view.frame.origin.y = UIScreen.main.bounds.height - self.view.frame.height - minPanding
                self.view.alpha = 1
                return
            }
            self.removeAVView(CGPoint(x: self.view.frame.origin.x, y: UIScreen.main.bounds.height + self.view.frame.height))
            return
        }

        if self.view.center.x <= UIScreen.main.bounds.width/2 {
            self.view.frame.origin.x = minPanding
        } else {
            self.view.frame.origin.x = UIScreen.main.bounds.width - self.view.frame.width - minPanding
        }
        self.view.alpha = 1
    }
    
    fileprivate func removeAVView(_ dispearPoint: CGPoint) {

        DispatchQueue.main.async(execute: {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: UIView.AnimationOptions(), animations: {[weak self] in
                guard let self = self else {return}
                self.view.frame.origin = dispearPoint
                self.view.alpha = 0

                }, completion: {[weak self](_) in
                    guard let self = self else {return}
                    self.releasePlayer()
            })
        })
    }
}

extension UIView {
    func parentViewController() -> UIViewController? {
        var parentResponder: UIResponder? = self
        while true {
            guard let nextResponder = parentResponder?.next else { return nil }
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            parentResponder = nextResponder
        }
    }

    func parentView<T: UIView>(type: T.Type) -> T? {
        var parentResponder: UIResponder? = self
        while true {
            guard let nextResponder = parentResponder?.next else { return nil }
            if let view = nextResponder as? T {
                return view
            }
            parentResponder = nextResponder
        }
    }
}
