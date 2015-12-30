//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Victor Guthrie on 12/24/15.
//  Copyright © 2015 chicovg. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    var photoImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        photoImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        contentView.addSubview(photoImageView)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
