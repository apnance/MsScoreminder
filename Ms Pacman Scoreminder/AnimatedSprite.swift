
//
//  AnimatedSprite.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 8/20/23.
//

import UIKit

struct AnimatedSprite {
    
    private static let spriteSheet = SpriteSheet(sprites: UIImage(named: "ms_sprite_sheet_v2")!,
                                                 spriteWidth: 16,
                                                 spriteHeight: 16)
    
    class Character {
        
        /// Specifiies whether the sprite image sequences are in rows or columns
        enum Orientation { case row, col }
        
        let orientation: Orientation
        
        /// Start row or col - depends on orientation
        let loc: Int
        
        fileprivate init(orientation: Orientation, loc: Int) {
            
            self.orientation    = orientation
            self.loc            = loc
            
        }
        
        fileprivate func frames(_ startFrame: Int, _ endFrame: Int) -> [UIImage] {
            
            var images = [UIImage]()
            let range  = startFrame...endFrame
            
            switch orientation {
                    
                case .row:
                    
                    for col in range {
                        
                        images.append(spriteSheet.get(row: loc,
                                                      col: col)!.pixelatedLCD(1, interstitialColor: .clear)!)
                        
                    }
                    
                case .col:
                    
                    for row in range {
                        
                        images.append(spriteSheet.get(row: row,
                                                      col: loc)!.pixelatedLCD(1, interstitialColor: .clear)!)
                        
                    }
                    
            }
            
            return images
            
        }
        
    }
    
    class Ms: Character {
        
        private init(_ loc: Int) { super.init(orientation: .row, loc: loc) }
        
        static let goRight  = Ms(0).frames(0,2)
        static let goLeft   = Ms(1).frames(0,2)
        static let goUp     = Ms(2).frames(0,2)
        static let goDown   = Ms(3).frames(0,2)
        
    }
    
    class Ghost: Character {
        
        static let blinky           = Ghost(4)
        static let pinky            = Ghost(5)
        static let inky             = Ghost(6)
        static let clyde            = Ghost(7)
        
        private static var scared   = Character(orientation: .row, loc: 4)
        private static var eyes     = Character(orientation: .row, loc: 5)
        
        private init(_ loc: Int) {
            
            super.init(orientation: .row, loc: loc)
            
        }
        
        static func random() -> Ghost {
            
            switch Int.random(min: 0, max: 3) {
                    
                case 0: return .blinky
                case 1: return .pinky
                case 2: return .inky
                default: return .clyde
                    
            }
            
        }
        
        
        lazy var lookRight: [UIImage] = frames(0,1)
        lazy var lookLeft:  [UIImage] = frames(2,3)
        lazy var lookUp:    [UIImage] = frames(4,5)
        lazy var lookDown:  [UIImage] = frames(6,7)
        
        lazy var lookClockWise      = lookRight + lookDown + lookLeft + lookUp
        lazy var lookCounterWise    = lookLeft + lookDown + lookRight + lookUp
        
        var scared                  = Ghost.scared.frames(8,9)
        var scaredFading            = Ghost.scared.frames(8,11)
        
        var eyesRight               = Ghost.eyes.frames(8,8)
        var eyesLeft                = Ghost.eyes.frames(9,9)
        var eyesUp                  = Ghost.eyes.frames(10,10)
        var eyesDown                = Ghost.eyes.frames(11,11)
        
        
    }
    
    class Fruit: Character {
        
        private init(_ loc: Int) {
            
            super.init(orientation: .col, loc: loc)
            
        }
        
        static let cherry       = Fruit(3)
        static let strawberry   = Fruit(4)
        static let orange       = Fruit(5)
        static let pretzel      = Fruit(6)
        static let apple        = Fruit(7)
        static let pear         = Fruit(8)
        static let banana       = Fruit(9)
        
        var bounce: [UIImage] {
            
            frames(0,2) + (frames(0,2)).reversed()
            
        }
        
    }
    
    class Pellets {
        
        static var animated: [UIImage] = {
            
            var frames = [UIImage]()
            
            for i in 9...11 {
                frames.append(spriteSheet.get(row:i,
                                              startCol: 3,
                                              colNum: 5)!.pixelatedLCD(1,
                                                                       interstitialColor: .clear)!)
                
            }
            
            return frames
            
        } ()
        
        
    }
    
}

fileprivate struct SpriteSheet {
    
    var sprites:        UIImage
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
