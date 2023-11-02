//
//  UIColor+Batelco.swift
//  Batelco
//
//  Created by Alin Muntean on 25/09/2019.
//  Copyright © 2019 Batelco. All rights reserved.
//

import UIKit

public extension UIColor {
  // App Generic Colors
  
  class var actualBlack: UIColor { UIColor(hex: "#000000") }
  
  class var black: UIColor { UIColor(hex: "#1A242D") }
  
  class var invalidTextFieldColor: UIColor { UIColor(hex: "#FBF4F0") }
  
  class var appErrorRed: UIColor { UIColor(hex: "#F53A3A") }
  
  class var appDisableRed: UIColor { UIColor(hex: "#DA9097") }
  
  // Gray's Anatomy
  
  class var veryLightGray: UIColor { UIColor(hex: "#F7F7F7") }
  
  class var newVeryLightGray: UIColor { UIColor(hex: "#F4F4F4") }
  
  class var newLightGray: UIColor { UIColor(hex: "#DFE1E2") }
  
  class var appMediumGray: UIColor { UIColor(hex: "#787A7A") }
  
  class var appDarkGray: UIColor { UIColor(hex: "#55565A") }
  
  class var appLightGray: UIColor { UIColor(hex: "#BDBDBD") }
  
  class var placeholderGray: UIColor { UIColor(hex: "#C7C7CD") }
  
  class var appNewLightGray: UIColor { UIColor(hex: "#9B9B99") }
  
  // #FAFAFA Actual Value
  // #FF0000 RED for Testing
  class var backgroundOffWhite: UIColor { UIColor(hex: "#FAFAFA") }
  
  class var appRed: UIColor { UIColor(hex: "#E21331") }
  
  class var appGreen: UIColor { UIColor(hex: "#288F80") }
  
  class var appOrange: UIColor { UIColor(hex: "#D46C57") }
  
  // eCommerce
  
  class var eCommerceGreen: UIColor { UIColor(hex: "#439D90") }
  
  class var eCommerceOrange: UIColor { UIColor(hex: "#F0E9E3") }
  
  class var eCommerceGray: UIColor { UIColor(hex: "#5C6368") }
  
  // Feature Specific Colors
  
  // Welcome Video Background Red
  class var videoRed: UIColor { UIColor(hex: "#CE092F") }
  
  // Bills Adjustment Text Orange
  class var billsOrange: UIColor { UIColor(hex: "#DB9C49") }
  
  // Line Reconnection Success Alert Green
  class var lineReconnectionGreen: UIColor { UIColor(hex: "#5CB85C") }
  
  // Auto Pay Gray
  class var autoPayGray: UIColor { UIColor(hex: "#CBCBCB") }
  
  // UI/UX Revamp July 2022
  
  class var tabBarBorder: UIColor { UIColor(red: 0, green: 0, blue: 0, alpha: 0.15) }
  
  class var timelineGray: UIColor { UIColor(hex: "#A6A6A6") }
  
  class var deviceSettlementGray: UIColor { UIColor(hex: "#ECECEC") }
  
  class var appYellow: UIColor { UIColor(hex: "#F5C884") }
  
  // AccuraScan
  class var accuraScanCameraOverlay: UIColor { UIColor(red: 0, green: 0, blue: 0, alpha: 0.4) }
  
  // Prepaid Trans History Gray
  class var creditTransferGray: UIColor { UIColor(hex: "#C3C3C3") }
  
  // Al Dana
  class var desertStorm: UIColor { UIColor(hex: "#ECE7E1") }
  class var aldanaLightGray: UIColor { UIColor(hex: "#959595") }
  class var aldanaVeryLightGrey: UIColor { UIColor(hex: "#e8e8e8") }
  class var aldanaGreyDivider: UIColor { UIColor(hex: "#D4D4D4") }
  class var aldanaHyberLink: UIColor { UIColor(hex: "#0645AD") }
  
  // Sim Options
  class var treeOfLifeGreen: UIColor { UIColor(hex: "#488D80") }
  class var treeOfLifeGreenTransparent: UIColor { UIColor(red: 72 / 255, green: 141 / 255, blue: 128 / 255, alpha: 0.1) }
  
  // Prapaid Validity
  
  class var validityGray: UIColor { UIColor(hex: "#606060") }
  
  // Enhanced Roaming
  
  class var progressBarTint: UIColor { UIColor(hex: "#4192E9") }
  class var roamingBlue: UIColor { UIColor(hex: "#1773CD") }
  class var roamingAddOnCardBorder: UIColor { UIColor(hex: "#E0E9F4") }
  class var roamingBlockBackgroundBox: UIColor { UIColor(red: 0.65, green: 0.65, blue: 0.65, alpha: 0.1) }
  class var roamingActiveBackgroundBox: UIColor { UIColor(red: 0.28, green: 0.55, blue: 0.5, alpha: 0.15) }
  class var roamingInProgressBackgroundBox: UIColor { UIColor(red: 0.86, green: 0.61, blue: 0.29, alpha: 0.1) }
  class var gbsBlockBackgroundColor: UIColor { UIColor(red: 0.25, green: 0.57, blue: 0.91, alpha: 0.1) }
  class var notPreferedBlockBackgroundColor: UIColor { UIColor(red: 0.89, green: 0.07, blue: 0.19, alpha: 0.1) }
  class var roamingShadowColor: UIColor { UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 0.1) }
  
  // Device on new line

  class var premiumNiceNumber: UIColor { UIColor(hex: "#BA9865") }
}

public extension UIColor {
    
  convenience init(hex: String) {
    let red, green, blue: CGFloat
    var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    
    if cString.hasPrefix("#") {
      cString.remove(at: cString.startIndex)
    }
    
    if cString.count != 6 {
      self.init(red: 0, green: 0, blue: 0, alpha: 1)
      return
    }
    
    var rgbValue: UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)

    red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
    green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
    blue = CGFloat(rgbValue & 0x0000FF) / 255.0
    self.init(red: red, green: green, blue: blue, alpha: 1.0)
    return
  }
}
