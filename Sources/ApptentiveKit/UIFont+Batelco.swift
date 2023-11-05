//
//  UIFont+Batelco.swift
//  Batelco
//
//  Created by Alin Muntean on 28/10/2019.
//  Copyright © 2019 Batelco. All rights reserved.
//

import UIKit

// Master extension to allow custom fonts
extension UIFont {
  private class func customFont(name: String, size: CGFloat) -> UIFont {
    guard 
        let font = UIFont(name: name, size: size)
      else
      {
      assertMessage("Can't load font: \(name)")
      return .systemFont(ofSize: size)
    }
    return font
  }
}
func assertMessage(_ message: String,
                   _ file: StaticString = #file,
                   _ function: StaticString = #function,
                   _ line: UInt = #line) {
  
    //print(message, "\(file)", "\(function)", line: Int(line))
    print("CANT LOAD FONT")
#if DEVELOPMENT
  assertionFailure(message, file: file, line: line)
#endif
}
// Batelco App Font
public extension UIFont {
  
  class func batelcoFontBlack(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "Averta-Black"
    return customFont(name: fontName, size: fontSize)
  }
  
  class func batelcoFontBlackItalic(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "AvertaStd-BlackItalic"
    return customFont(name: fontName, size: fontSize)
  }
  
  class func batelcoFontBold(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "AvertaStd-Bold"
    return customFont(name: fontName, size: fontSize)
  }
  
  class func batelcoFontBoldItalic(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "AvertaStd-BoldItalic"
    return customFont(name: fontName, size: fontSize)
  }
  
  class func batelcoFontExtraBold(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "AvertaStd-Extrabold"
    return customFont(name: fontName, size: fontSize)
  }
  
  class func batelcoFontExtraBoldItalic(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "AvertaStd-ExtraboldItalic"
    return customFont(name: fontName, size: fontSize)
  }
  
  class func batelcoFontExtraThin(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "AvertaStd-Extrathin"
    return customFont(name: fontName, size: fontSize)
  }
  
  class func batelcoFontExtraThinItalic(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "AvertaStd-ExtrathinItalic"
    return customFont(name: fontName, size: fontSize)
  }
  
  class func batelcoFontLight(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "AvertaStd-Light"
    return customFont(name: fontName, size: fontSize)
  }
  
  class func batelcoFontLightItalic(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "AvertaStd-LightItalic"
    return customFont(name: fontName, size: fontSize)
  }
  
  class func batelcoFontRegular(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "AvertaStd-Regular"
    return customFont(name: fontName, size: fontSize)
  }
  
  class func batelcoFontRegularItalic(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "AvertaStd-RegularItalic"
    return customFont(name: fontName, size: fontSize)
  }
  
  class func batelcoFontSemiBold(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "AvertaStd-Semibold"
    return customFont(name: fontName, size: fontSize)
  }
  
  class func batelcoFontSemiBoldItalic(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "AvertaStd-SemiboldItalic"
    return customFont(name: fontName, size: fontSize)
  }
  
  class func batelcoFontThin(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "AvertaStd-Thin"
    return customFont(name: fontName, size: fontSize)
  }
  
  class func batelcoFontThinItalic(ofSize fontSize: CGFloat) -> UIFont {
    let fontName = "AvertaStd-ThinItalic"
    return customFont(name: fontName, size: fontSize)
  }
}
