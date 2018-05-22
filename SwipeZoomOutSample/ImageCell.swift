//
//  ImageCell.swift
//  SwipeDismiss
//
//  Created by hirobe on 2018/05/17.
//  Copyright © 2018年 Bunguu inc. All rights reserved.
//

import UIKit

class ImageCell: UICollectionViewCell {
    
    var imageView: UIImageView = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.imageView.frame = self.bounds
        self.imageView.clipsToBounds = true
        self.imageView.contentMode = .scaleAspectFill
        self.addSubview(imageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
