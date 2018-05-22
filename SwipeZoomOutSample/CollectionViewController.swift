//
//  CollectionViewController.swift
//  SwipeDismiss
//
//  Created by Hirobe Kazuya on 2018/05/17.
//  Copyright © 2018 Bunguu inc. All rights reserved.
//

import UIKit

private let reuseIdentifier = "ImageCell2"

class CollectionViewController: UICollectionViewController {

    var images:[UIImage?] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.images =  [Int](1 ..< 50).map {_ in self.makeRandomImage()}
        self.title = "Circles"
        
        self.collectionView!.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        cell.backgroundColor = UIColor.yellow
        cell.imageView.image = makeRandomImage()
        return cell
    }
    
    private func makeRandomImage() -> UIImage? {
        let size = CGSize(width:320, height:480)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context:CGContext = UIGraphicsGetCurrentContext() else { return nil}
        let rect:CGRect = CGRect(origin: .zero, size: size)
        context.setFillColor(UIColor.lightGray.cgColor)
        context.fill(rect)
        for index in 0..<3 {
            let x = CGFloat(Float(arc4random()) / Float(UINT32_MAX)) * size.width
            let y = CGFloat(Float(arc4random()) / Float(UINT32_MAX)) * size.height
            let r = CGFloat(Float(arc4random()) / Float(UINT32_MAX)) * size.width
            let color:UIColor = [UIColor.blue, UIColor.red, UIColor.green][index]
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(10.0)
            context.addArc(center: CGPoint(x:x, y:y),
                           radius: r * 0.5,
                           startAngle: 0.0,
                           endAngle: .pi * 2.0,
                           clockwise: false)
            context.strokePath()
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ImageCell else { return }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else { return }
        vc.parentImageViewRect = collectionView.convert(cell.frame, to: collectionView.window)
        vc.parentImage = cell.imageView.image

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = vc.modalTransition
        nav.isNavigationBarHidden = true
        self.present(nav, animated: true)
    }

}
