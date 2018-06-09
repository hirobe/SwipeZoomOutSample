//
//  DetailViewController.swift
//  SwipeDismiss
//
//  Created by Hirobe Kazuya on 2018/05/17.
//  Copyright © 2018 Bunguu inc. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    var parentImageViewRect:CGRect = .zero
    var parentImage:UIImage?

    var modalTransition:DetailModalTransition = DetailModalTransition()

    var panGesture: UIPanGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView.image = parentImage

        panGesture = UIPanGestureRecognizer(target: self, action: #selector(DetailViewController.handleVerticalPanGesture(_:)))
        self.view.addGestureRecognizer(panGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.dismiss(animated: false, completion: nil)
        }
        */
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func handleVerticalPanGesture(_ sender: UIPanGestureRecognizer){
        let point: CGPoint = sender.translation(in: self.view)
        let velocity = sender.velocity(in: self.view)
        let per = fabs(point.y) / self.view.frame.size.height
        switch (sender.state) {
        case .cancelled, .failed:
            resetPosition()
        case .changed:
            // ドラッグ動作 + y移動量に合わせて縮小 (concatenatingの順番に注意)
            self.imageView.transform =
                CGAffineTransform(scaleX: 1.0 - per, y: 1.0 - per)
                .concatenating( CGAffineTransform(translationX: point.x, y: point.y) )
        case .ended:
            if per > 0.1 || fabs(velocity.y) > 1000 {
                // 進行度0.3以上 or スワイプの勢いが一定以上なら遷移実行へ
                self.modalTransition.isForPresented = false
                self.modalTransition.swipeScale = 1.0 - per
                self.modalTransition.swipePoint = CGPoint(x: point.x , y: point.y )
                self.modalTransition.swipeVelocity = velocity
                self.dismiss(animated: true, completion: nil)
            } else {
                resetPosition()
            }
        default:
            break
        }
    }

    func resetPosition() {
        UIView.animate(withDuration: 0.3) {
            self.imageView.transform = CGAffineTransform.identity
        }
    }

    func detailImageRect(containerView:UIView, safeAreaInsets:UIEdgeInsets) -> CGRect {
        // 画像の表示座標を計算。presentの場合は、self.viewはまだレイアウトされていないので、containerViewのサイズをもとに自分で計算する
        let safeAreaFrame = CGRect(x: containerView.frame.minX + safeAreaInsets.left,
                                   y: containerView.frame.minY + safeAreaInsets.top,
                                   width: containerView.frame.width - safeAreaInsets.left - safeAreaInsets.right,
                                   height: containerView.frame.height - safeAreaInsets.top - safeAreaInsets.bottom)

        // imageViewはsafeArea一杯に配置されていて、aspectFillで表示中の画像はそれより小さい。縦横比から画面内のimageの領域を計算する
        guard let size:CGSize = parentImage?.size else { return .zero }
        let rate = min(safeAreaFrame.size.width / size.width, safeAreaFrame.size.height / size.height)
        let imageSize = CGSize(width: size.width * rate, height: size.height * rate)
        var imageFrame = CGRect(x: (safeAreaFrame.width - imageSize.width) / 2.0 + safeAreaInsets.left,
                                y: (safeAreaFrame.height - imageSize.height) / 2.0 + safeAreaInsets.top,
                                width: imageSize.width,
                                height: imageSize.height)

        // imageViewのスワイプによるtransition後のframeを計算
        imageFrame.origin = CGPoint(x: imageFrame.origin.x + self.modalTransition.swipePoint.x,
                                    y: imageFrame.origin.y + self.modalTransition.swipePoint.y)
        imageFrame = CGRect(x: imageFrame.origin.x + (imageFrame.width * (1.0 - self.modalTransition.swipeScale))/2.0,
                            y: imageFrame.origin.y + (imageFrame.height * (1.0 - self.modalTransition.swipeScale))/2.0,
                            width: imageFrame.width * self.modalTransition.swipeScale,
                            height: imageFrame.height * self.modalTransition.swipeScale)

        return imageFrame
    }
}

class DetailModalTransition : NSObject, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {

    var isForPresented:Bool = true

    var dismissComplated: (() -> Void)?
    
    var swipePoint: CGPoint = CGPoint.zero
    var swipeScale : CGFloat = 1.0
    var swipeVelocity : CGPoint = CGPoint.zero

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.isForPresented = false
        return self
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.isForPresented = true
        return self
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if isForPresented { // present
            return 0.2
        } else { // dissmis
            return 0.4
        }
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isForPresented { // present
            presentAnimation(transitionContext)
        } else { // dissmis
            dissmisAnimation(transitionContext)
        }
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        if !isForPresented && transitionCompleted {
            dismissComplated?()
        }
    }

    private func safeAreaInsets(transitionContext: UIViewControllerContextTransitioning) -> UIEdgeInsets {
        // transisionContextからviewControllerのsafeAreaInsetを取得するには.fromを使うこと。containerViewや.toでは正しく取得できないので注意
        if #available(iOS 11, *) {
            return transitionContext.viewController(forKey: .from)?.view.safeAreaInsets ?? .zero
        }
        return .zero
    }

    func presentAnimation(_ transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard let nav = transitionContext.viewController(forKey: .to) as? UINavigationController,
            let detailVC:DetailViewController = nav.visibleViewController as? DetailViewController
            else { fatalError() }

        let fromImageRect = detailVC.parentImageViewRect
        let toImageRect = detailVC.detailImageRect(containerView: containerView, safeAreaInsets: self.safeAreaInsets(transitionContext: transitionContext))

        // imageを移動するためのviewを作成
        let imageView:UIImageView = UIImageView(frame: fromImageRect)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.image = detailVC.parentImage
        containerView.addSubview(imageView)

        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.curveEaseOut], animations: { () -> Void in
            imageView.frame = toImageRect
        }) { (finished) -> Void in
            containerView.addSubview(nav.view)
            imageView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }

    func dissmisAnimation(_ transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard let nav = transitionContext.viewController(forKey: .from) as? UINavigationController,
            let detailVC:DetailViewController = nav.visibleViewController as? DetailViewController
            else { fatalError() }

        let fromImageRect = detailVC.detailImageRect(containerView: containerView, safeAreaInsets: self.safeAreaInsets(transitionContext: transitionContext))
        let toImageRect = detailVC.parentImageViewRect

        // 下を隠すためのviewを作成
        let backgroundView:UIView = UIView(frame:containerView.bounds)
        containerView.addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.white

        // imageを移動するためのviewを作成
        let yMoveView:UIView = UIView(frame:containerView.bounds)
        let xMoveView:UIView = UIView(frame:containerView.bounds)
        let imageView:UIImageView = UIImageView(frame: fromImageRect)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.image = detailVC.parentImage
        containerView.addSubview(yMoveView)
        yMoveView.addSubview(xMoveView)
        xMoveView.addSubview(imageView)

        // アニメーション
        nav.view.isHidden = true
        backgroundView.alpha = 1.0
        imageView.frame = fromImageRect

        let velocityX = min(self.swipeVelocity.x / (toImageRect.midX - fromImageRect.midX) , 10000.0)
        let velocityY = min(self.swipeVelocity.y / (toImageRect.midY - fromImageRect.midY) , 10000.0)

        // x軸移動アニメーション
        UIView.animate(withDuration: transitionDuration(using: transitionContext) , delay: 0,
                       usingSpringWithDamping: 0.95,
                       initialSpringVelocity: velocityX,
                       animations: { () -> Void in
                        xMoveView.frame.origin = CGPoint(x: toImageRect.midX - fromImageRect.midX, y:0)
        })
        // y軸移動アニメーション
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0,
                       usingSpringWithDamping: 0.95,
                       initialSpringVelocity: velocityY ,
                       animations: { () -> Void in
                        yMoveView.frame.origin = CGPoint(x:0, y: toImageRect.midY - fromImageRect.midY)
        })

        // 縮小アニメーション
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.curveLinear], animations: { () -> Void in
            imageView.frame.size = toImageRect.size
            imageView.center = CGPoint(x:fromImageRect.midX, y:fromImageRect.midY)
            backgroundView.alpha = 0.0

        }) { (finished) -> Void in
            yMoveView.isHidden = true
            nav.view.removeFromSuperview()
            yMoveView.removeFromSuperview()
            backgroundView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }

}
