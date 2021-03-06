//
//  QiscusColorConfiguration.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 9/7/16.
//  Copyright © 2016 Ahmad Athaullah. All rights reserved.
//

import UIKit

open class QiscusColorConfiguration: NSObject {
    static var sharedInstance = QiscusColorConfiguration()
    
    /// Your cancel button color, using UIColor class, Default value : UIColor(red: 223/255.0, green: 223/255.0, blue: 223/255.0, alpha:1.0)
    open var cancelButtonColor = UIColor(red: 223/255.0, green: 223/255.0, blue: 223/255.0, alpha:1.0)
    
    /// Your alert text color, using UIColor class, Default value : UIColor(red: 155/255.0, green: 155/255.0, blue: 155/255.0, alpha:1.0)
    open var alertTextColor = UIColor(red: 155/255.0, green: 155/255.0, blue: 155/255.0, alpha:1.0)
    
    /// Your left baloon color, using UIColor class, Default value : UIColor(red: 0/255.0, green: 187/255.0, blue: 150/255.0, alpha: 1.0)
    open var leftBaloonColor = UIColor(red: 0/255.0, green: 187/255.0, blue: 150/255.0, alpha: 1)
    
    /// Your right baloon color, using UIColor class, Default value : UIColor(red: 165/255.0, green: 226/255.0, blue: 221/255.0, alpha: 1.0)
    open var rightBaloonColor = UIColor(red: 165/255.0, green: 226/255.0, blue: 221/255.0, alpha: 1)
    
    /// Your left baloon text color, using UIColor class, Default value : UIColor.whiteColor()
    open var leftBaloonTextColor = UIColor.white
    
    /// Your right baloon text color, using UIColor class, Default value : UIColor(red: 33/255.0, green: 33/255.0, blue: 33/255.0, alpha: 1)
    open var rightBaloonTextColor = UIColor(red: 33/255.0, green: 33/255.0, blue: 33/255.0, alpha: 1)
    
    /// Your text color of time label, using UIColor class, Default value : UIColor(red: 114/255.0, green: 114/255.0, blue: 114/255.0, alpha: 1)
    open var timeLabelTextColor = UIColor(red: 114/255.0, green: 114/255.0, blue: 114/255.0, alpha: 1)
    
    /// Your failed text color if the message fail to send, using UIColor class, Default value : UIColor(red: 1, green: 19/255.0, blue: 0, alpha: 1)
    open var failToSendColor = UIColor(red: 1, green: 19/255.0, blue: 0, alpha: 1)
    
    /// Your link color of left baloon chat, using UIColor class, Default value : UIColor.whiteColor()
    open var leftBaloonLinkColor = UIColor.white
    
    /// Your link color of right baloon chat, using UIColor class, Default value : UIColor(red: 33/255.0, green: 33/255.0, blue: 33/255.0, alpha: 1)
    open var rightBaloonLinkColor = UIColor(red: 33/255.0, green: 33/255.0, blue: 33/255.0, alpha: 1)
    
    /// Your background color of lock view, using UIColor class, Default value : UIColor(red: 255.0/255.0, green: 87/255.0, blue: 34/255.0, alpha: 1)
    open var lockViewBgColor = UIColor(red: 255.0/255.0, green: 87/255.0, blue: 34/255.0, alpha: 1)
    
    /// Your tint color of lock view, using UIColor class, Default value : UIColor.blackColor()
    open var lockViewTintColor = UIColor.black
    
    /// Welcome image color, using UIColor class, Default value: UIColor(red: 18/255.0, green: 180/255.0, blue: 147/255.0, alpha: 1)
    open var welcomeIconColor = UIColor(red: 18/255.0, green: 180/255.0, blue: 147/255.0, alpha: 1)
    
    open var baseColor:UIColor{
        get{
            return QiscusChatVC.sharedInstance.topColor
        }
    }
    
    fileprivate override init(){}
}
