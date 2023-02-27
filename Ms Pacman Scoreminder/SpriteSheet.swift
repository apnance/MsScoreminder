//
//  SpriteManager.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 2/22/23.
//

import APNUtil
import UIKit

struct SpriteSheet {
    
    var sprites: UIImage
    var spriteWidth:    Int
    var spriteHeight:   Int
    
    func get(row: Int, col: Int) -> UIImage? {
        
        if let cgImage = sprites.cgImage {
        
            let cropped = cgImage.cropping(to: CGRect(x: col * spriteWidth, y: row * spriteHeight,
                                                      width: spriteWidth, height: spriteHeight))!
            
            return UIImage(cgImage: cropped)
            
        }
        
        return nil /*EXIT*/
        
    }
    
    
    func get(row: Int, startCol: Int, colNum: Int) -> UIImage? {
        
        if let cgImage = sprites.cgImage {
        
            let cropped = cgImage.cropping(to: CGRect(x: startCol * spriteWidth, y: row * spriteHeight,
                                                      width: colNum * spriteWidth, height: spriteHeight))!
            
            return UIImage(cgImage: cropped)
            
        }
        
        return nil /*EXIT*/
        
    }

    
}
