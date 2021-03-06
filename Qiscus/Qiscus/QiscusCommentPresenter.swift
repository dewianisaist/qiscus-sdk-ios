//
//  QiscusCommentPresenter.swift
//  Example
//
//  Created by Ahmad Athaullah on 2/15/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
public enum QiscusCommentPresenterType:Int {
    case text
    case image
    case video
    case audio
    case file
}
@objc public class QiscusCommentPresenter: NSObject {
    // commentAttribute
    var localId:Int64 = 0
    var commentId:Int64 = 0
    var commentText = ""
    var commentAttributedText:NSMutableAttributedString?
    var commentDate = ""
    var commentTime = ""
    var commentStatus = QiscusCommentStatus.sent
    var commentType = QiscusCommentPresenterType.text
    var commentUniqueid = ""
    var commentIndexPath:IndexPath?
    var createdAt:Double = Double(0)
    var isToday:Bool = false
    
    var topicId:Int = 0
    
    // user attribute
    var userIsOwn = false
    var userFullName = ""
    var userImage = UIImage()
    var userEmail = ""
    
    // link attribute
    var showLink = false
    var linkImage:UIImage?
    var linkTitle:String?
    var linkDescription:String?
    var linkImageURL:String?
    var linkSaved = false
    var linkURL = ""
    
    // processing attribute
    var isUploading = false
    var isUploaded = false
    var isDownloading = false
    var uploadProgress = CGFloat(0)
    var downloadProgress = CGFloat(0)
    
    var fromPresenter = true
    var cellIdentifier:String = ""
    var balloonImage:UIImage?
    var cellSize = CGSize()
    var cellPos = CellTypePosition.single
    var displayImage:UIImage?
    
    // url variable 
    var localFileExist = false
    var remoteURL: String?
    var localURL :String?
    var localThumbURL :String?
    
    
    // audio variable
    var durationLabel = ""
    var currentTimeSlider = Float(0)
    var seekTimeLabel = "00:00"
    var audioFileExist = false
    var audioIsPlaying = false
    
    // other file variable
    var fileName = ""
    var fileType = ""
    
    // upload
    var toUpload = false
    var uploadData:Data?
    var uploadMimeType:String?
    
    // getter variable
    var comment:QiscusComment?{
        get{
            return QiscusComment.getComment(withLocalId: localId)
        }
    }
    var linkTextAttributes:[String: Any]{
        get{
            var foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor
            var underlineColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor
            if self.userIsOwn{
                foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor
                underlineColorAttributeName = QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor
            }
            return [
                NSForegroundColorAttributeName: foregroundColorAttributeName,
                NSUnderlineColorAttributeName: underlineColorAttributeName,
                NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
                NSFontAttributeName: Qiscus.style.chatFont
            ]
        }
    }
    var textAttribute:[String: Any]{
        get{
            var foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonTextColor
            if self.userIsOwn{
                foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            }
            return [
                NSForegroundColorAttributeName: foregroundColorAttributeName,
                NSFontAttributeName: Qiscus.style.chatFont
            ]
        }
    }
    class func getPresenter(forComment comment:QiscusComment)->QiscusCommentPresenter{
        let commentPresenter = QiscusCommentPresenter()
        commentPresenter.fromPresenter = true
        commentPresenter.localId = comment.localId
        commentPresenter.isToday = comment.isToday
        commentPresenter.commentId = comment.commentId
        commentPresenter.commentText = comment.commentText
        commentPresenter.commentDate = comment.commentDay
        commentPresenter.commentTime = comment.commentTime
        commentPresenter.commentStatus = comment.commentStatus
        commentPresenter.userIsOwn = comment.isOwnMessage
        commentPresenter.createdAt = comment.commentCreatedAt
        commentPresenter.userEmail = comment.commentSenderEmail
        commentPresenter.commentUniqueid = comment.commentUniqueId
        commentPresenter.topicId = comment.commentTopicId
        
        if let user = comment.sender{
            commentPresenter.userFullName = user.userFullName
        }
        
        var position:String = "Left"
        if comment.isOwnMessage{
            position = "Right"
        }

        switch comment.commentType {
        case .text:
            commentPresenter.commentType = .text
            commentPresenter.cellIdentifier = "cellText\(position)"
            commentPresenter.showLink = comment.showLink
            
            var attributedText = NSMutableAttributedString(string: commentPresenter.commentText)
            
            let allRange = (commentPresenter.commentText as NSString).range(of: commentPresenter.commentText)
            attributedText.addAttributes(commentPresenter.textAttribute, range: allRange)
            
            if commentPresenter.showLink {
                if let url = comment.commentLink{
                    commentPresenter.linkTitle = "Load data ..."
                    commentPresenter.linkDescription = "Load url description"
                    commentPresenter.linkImage = Qiscus.image(named: "link")
                    
                    var urlToCheck = url.lowercased()
                    if !urlToCheck.contains("http"){
                        urlToCheck = "http://\(url.lowercased())"
                    }
                    
                    commentPresenter.linkURL = urlToCheck
                    
                    if let linkData = QiscusLinkData.getLinkData(fromURL: urlToCheck){
                        commentPresenter.linkDescription = linkData.linkDescription
                        commentPresenter.linkImageURL = linkData.linkImageURL
                        commentPresenter.linkSaved = true
                        
                        if let image = linkData.thumbImage{
                            commentPresenter.linkImage = image
                        }
                        if linkData.linkTitle != "" {
                            commentPresenter.linkTitle = linkData.linkTitle
                            let text = commentPresenter.commentText.replacingOccurrences(of: linkData.linkURL, with: linkData.linkTitle)
                            
                            let allRange = (text as NSString).range(of: text)
                            let titleRange = (text as NSString).range(of: linkData.linkTitle)
                            
                            attributedText = NSMutableAttributedString(string: text)
                            attributedText.addAttributes(commentPresenter.textAttribute, range: allRange)
                            
                            for (attribute,_) in commentPresenter.textAttribute {
                                attributedText.removeAttribute(attribute, range: titleRange)
                            }
                            attributedText.addAttributes(commentPresenter.linkTextAttributes, range: titleRange)
                            
                            let url = NSURL(string: linkData.linkURL)!
                            attributedText.addAttribute(NSLinkAttributeName, value: url, range: titleRange)
                        }
                    }
                }
                else{
                    commentPresenter.showLink = false
                }
            }
            commentPresenter.commentAttributedText = attributedText
            Qiscus.uiThread.sync {
                let cellSize = QiscusCommentPresenter.calculateTextSize(attributedText: attributedText)
                commentPresenter.cellSize = cellSize
            }
            break
        default:
            var commentFile = QiscusFile.getCommentFileWithComment(comment)
            var file = QiscusFile()
            if commentFile == nil {
                commentFile = QiscusFile()
                commentFile!.updateURL(comment.getMediaURL())
                commentFile!.updateCommentId(comment.commentId)
                commentFile!.saveCommentFile()
                
                commentFile = QiscusFile.getCommentFileWithComment(comment)!
                comment.commentFileId = commentFile!.fileId
            }
            file = QiscusFile.copyFile(file: commentFile!)
            
            commentPresenter.localFileExist = file.isLocalFileExist()
            commentPresenter.isUploaded = file.isUploaded
            commentPresenter.remoteURL = file.fileURL
            commentPresenter.uploadMimeType = file.fileMimeType
            commentPresenter.fileType = file.fileExtension
            
            switch file.fileType {
            case .media:
                commentPresenter.commentType = .image
                commentPresenter.cellIdentifier = "cellMedia\(position)"
                commentPresenter.displayImage = Qiscus.image(named: "media_balloon")
                commentPresenter.cellSize.height = 135
                
                if let image = file.thumbImage(){
                    commentPresenter.displayImage = image
                    commentPresenter.localURL = file.fileLocalPath
                    commentPresenter.localThumbURL = file.fileMiniThumbPath
                }else{
                    commentPresenter.remoteURL = file.fileURL
                    var thumbURL = commentPresenter.remoteURL!.replacingOccurrences(of: "/upload/", with: "/upload/w_30,c_scale/").replacingOccurrences(of: " ", with: "%20")
                    if commentPresenter.fileType == "gif"{
                        let thumbUrlArr = thumbURL.characters.split(separator: ".")
                        
                        var newThumbURL = ""
                        var i = 0
                        for thumbComponent in thumbUrlArr{
                            if i == 0{
                                newThumbURL += String(thumbComponent)
                            }else if i < (thumbUrlArr.count - 1){
                                newThumbURL += ".\(String(thumbComponent))"
                            }else{
                                newThumbURL += ".png"
                            }
                            i += 1
                        }
                        thumbURL = newThumbURL
                    }
                    
                    if let imageURL = URL(string: thumbURL){
                        if let imageData = NSData(contentsOf: imageURL){
                            if let image = UIImage(data: imageData as Data){
                                commentPresenter.displayImage = image
                            }
                        }
                    }
                    
                }
                break
            case .video:
                commentPresenter.commentType = .video
                commentPresenter.cellIdentifier = "cellMedia\(position)"
                commentPresenter.displayImage = Qiscus.image(named: "media_balloon")
                commentPresenter.cellSize.height = 135
                if let image = file.thumbImage(){
                    commentPresenter.displayImage = image
                    commentPresenter.localURL = file.fileLocalPath
                    commentPresenter.localThumbURL = file.fileMiniThumbPath
                }else{
                    var thumbURL = commentPresenter.remoteURL!.replacingOccurrences(of: "/upload/", with: "/upload/w_30,c_scale/")
                    let thumbUrlArr = thumbURL.characters.split(separator: ".")
                    
                    var newThumbURL = ""
                    var i = 0
                    for thumbComponent in thumbUrlArr{
                        if i == 0{
                            newThumbURL += String(thumbComponent)
                        }else if i < (thumbUrlArr.count - 1){
                            newThumbURL += ".\(String(thumbComponent))"
                        }else{
                            newThumbURL += ".png"
                        }
                        i += 1
                    }
                    thumbURL = newThumbURL
                    if let imageURL = URL(string: thumbURL){
                        if let imageData = NSData(contentsOf: imageURL){
                            if let image = UIImage(data: imageData as Data){
                                commentPresenter.displayImage = image
                            }
                        }
                    }
                }
                break
            case .audio:
                commentPresenter.commentType = .audio
                commentPresenter.cellIdentifier = "cellAudio\(position)"
                commentPresenter.localFileExist = file.localFileExist
                commentPresenter.cellSize.height = 83
                commentPresenter.audioFileExist = file.isOnlyLocalFileExist
                if file.isOnlyLocalFileExist {
                    commentPresenter.localURL = file.fileLocalPath
                }
                break
            default:
                commentPresenter.commentType = .file
                commentPresenter.cellIdentifier = "cellFile\(position)"
                commentPresenter.cellSize.height = 65
                commentPresenter.fileName = file.fileName
                break
            }
            break
        }
        
        commentPresenter.fromPresenter = false
        return commentPresenter
    }
    
    class func calculateTextSize(attributedText : NSMutableAttributedString) -> CGSize {
        var size = CGSize()
        let textView = UITextView()
        textView.font = Qiscus.style.chatFont
        textView.dataDetectorTypes = .all
        textView.linkTextAttributes = QiscusCommentPresenter().linkTextAttributes
        
        let maxWidth:CGFloat = 190
        textView.attributedText = attributedText
        
        size = textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        
        return size
    }
    func getBalloonImage()->UIImage?{
        var balloonImage:UIImage?
        if self.userIsOwn{
            switch cellPos {
            case .single:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 28)
                balloonImage = Qiscus.image(named:"text_balloon_right")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            case .first:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 13)
                balloonImage = Qiscus.image(named:"text_balloon_first")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            case .middle:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 13)
                balloonImage = Qiscus.image(named:"text_balloon_mid")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            case .last:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 28)
                balloonImage = Qiscus.image(named:"text_balloon_last_r")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            }
        }else{
            switch cellPos {
            case .single:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 28, 13, 13)
                balloonImage = Qiscus.image(named:"text_balloon_left")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            case .first:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 13)
                balloonImage = Qiscus.image(named:"text_balloon_first")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            case .middle:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 13)
                balloonImage = Qiscus.image(named:"text_balloon_mid")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            case .last:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 28, 13, 13)
                balloonImage = Qiscus.image(named:"text_balloon_last_l")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            }
        }
        return balloonImage
    }
}
