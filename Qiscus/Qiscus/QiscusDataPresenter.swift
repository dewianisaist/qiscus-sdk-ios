//
//  QiscusDataPresenter.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 2/15/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import Photos


@objc public protocol QiscusDataPresenterDelegate {
    func dataPresenter(didFinishLoad comments:[[QiscusCommentPresenter]], inRoom:QiscusRoom)
    func dataPresenter(gotNewData presenter:QiscusCommentPresenter, inRoom:QiscusRoom)
    func dataPresenter(didChangeStatusFrom commentId: Int64, toStatus: QiscusCommentStatus, topicId: Int)
    func dataPresenter(didChangeContent data:QiscusCommentPresenter, inRoom:QiscusRoom)
    func dataPresenter(didChangeCellSize presenter:QiscusCommentPresenter, inRoom:QiscusRoom)
    func dataPresenter(didFinishLoadMore comments:[[QiscusCommentPresenter]], inRoom:QiscusRoom)
    func dataPresenter(didFailLoadMore inRoom:QiscusRoom)
    func dataPresenter(didChangeUser user: QiscusUser, onUserWithEmail email: String)
    func dataPresenter(didChangeRoom room: QiscusRoom, onRoomWithId roomId:Int)
    func dataPresenter(didFailLoad error:String)
    func dataPresenter(willResendData data:QiscusCommentPresenter)
    func dataPresenter(dataDeleted data:QiscusCommentPresenter)
}
@objc class QiscusDataPresenter: NSObject {
    open static let shared = QiscusDataPresenter()
    
    var commentClient = QiscusCommentClient.sharedInstance
    var delegate:QiscusDataPresenterDelegate?
    var data = [[QiscusCommentPresenter]]()
    var room = QiscusRoom()
    
    fileprivate override init(){
        super.init()
        commentClient.commentDelegate = self
        commentClient.delegate = self
    }
    
    func loadComments(inRoom roomId:Int, withMessage:String? = nil){
        Qiscus.logicThread.async {
            if let room = QiscusRoom.getRoomById(roomId){
                let comments = QiscusComment.grouppedComment(inTopicId: room.roomLastCommentTopicId)
                let presenters = QiscusDataPresenter.getPresenters(fromComments: comments)
                Qiscus.uiThread.async {
                    self.delegate?.dataPresenter(didFinishLoad: presenters, inRoom: room)
                }
                if let message = withMessage {
                    self.commentClient.postMessage(message: message, topicId: room.roomLastCommentTopicId)
                }
                self.room = room
                self.data = presenters
            }else{
                self.commentClient.getRoom(withID: roomId, withMessage: withMessage)
            }
        }
    }
    func loadComments(inRoomWithUsers user:String, optionalData:String? = nil, withMessage:String? = nil, distinctId:String = ""){
        Qiscus.logicThread.async {
            if let room = QiscusRoom.getRoom(distinctId, andUserEmail: user){
                let comments = QiscusComment.grouppedComment(inTopicId: room.roomLastCommentTopicId)
                let presenters = QiscusDataPresenter.getPresenters(fromComments: comments)
                Qiscus.uiThread.async {
                    self.delegate?.dataPresenter(didFinishLoad: presenters, inRoom: room)
                }
                if let message = withMessage {
                    self.commentClient.postMessage(message: message, topicId: room.roomLastCommentTopicId)
                }
                self.room = room
                self.data = presenters
            }else{
                self.commentClient.getListComment(withUsers: [user], distincId: distinctId, optionalData:optionalData, withMessage: withMessage)
            }
        }
    }
    func loadComments(inNewGroupChat users:[String], optionalData:String? = nil, withMessage:String? = nil){
        commentClient.createNewRoom(withUsers: users, optionalData: optionalData, withMessage: withMessage)
    }
    public func loadMore(inRoom room:QiscusRoom, fromComment commentId:Int64){
        commentClient.loadMore(room: room, fromComment: commentId)
    }
    fileprivate class func getPresenters(fromComments comments:[[QiscusComment]])->[[QiscusCommentPresenter]]{
        var commentsPresenter = [[QiscusCommentPresenter]]()
        
        var section = 0
        for commentGroup in comments{
            var presenterGroup = [QiscusCommentPresenter]()
            var row = 0
            for comment in commentGroup{
                let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                presenter.commentIndexPath = IndexPath(row: row, section: section)
                var cellPos = CellTypePosition.single
                if commentGroup.count > 1 {
                    if row == 0 {
                        cellPos = .first
                    }else if row == (commentGroup.count - 1){
                        cellPos = .last
                    }else{
                        cellPos = .middle
                    }
                }
                presenter.cellPos = cellPos
                if let balloon = presenter.getBalloonImage() {
                    presenter.balloonImage = balloon
                }
                presenterGroup.append(presenter)
                row += 1
            }
            if presenterGroup.count > 0{
                commentsPresenter.append(presenterGroup)
            }
            section += 1
        }
        
        return commentsPresenter
    }
    
    class func getLinkData(withData data:QiscusCommentPresenter){
        QiscusCommentClient.sharedInstance.getLinkMetadata(url: data.linkURL, synchronous: false, withCompletion: { linkData in
            data.linkTitle = linkData.linkTitle
            data.linkDescription = linkData.linkDescription
            data.linkImageURL = linkData.linkImageURL
            data.linkImage = Qiscus.image(named: "link")
            
            QiscusLinkData.copyLink(link: linkData).saveLink()
            
            if linkData.linkTitle != "" {
                let text = data.commentText.replacingOccurrences(of: linkData.linkURL, with: linkData.linkTitle)
                let titleRange = (text as NSString).range(of: linkData.linkTitle)
                let attributedText = NSMutableAttributedString(string: text)
                
                let allRange = (text as NSString).range(of: text)
                attributedText.addAttributes(data.textAttribute, range: allRange)
                
                for (attribute,_) in data.textAttribute {
                    attributedText.removeAttribute(attribute, range: titleRange)
                }
                attributedText.addAttributes(data.linkTextAttributes, range: titleRange)
                
                let url = NSURL(string: linkData.linkURL)!
                attributedText.addAttribute(NSLinkAttributeName, value: url, range: titleRange)
                
                data.commentAttributedText = attributedText
                data.cellSize = QiscusCommentPresenter.calculateTextSize(attributedText: attributedText)
                data.showLink = true
                data.linkSaved = true
                if let image = linkData.thumbImage{
                    data.linkImage = image
                }
                
                if let comment = data.comment{
                    if comment.commentRoom.roomId == QiscusDataPresenter.shared.room.roomId{
                        Qiscus.uiThread.async {
                            QiscusDataPresenter.shared.delegate?.dataPresenter(didChangeContent: data, inRoom: QiscusDataPresenter.shared.room)
                        }
                    }
                }
                
            }else{
                data.linkTitle = "Not Found"
                data.linkDescription = "No description found"
                data.linkImage = Qiscus.image(named: "link")
                data.showLink = false
                if let comment = data.comment{
                    if comment.commentRoom.roomId == QiscusDataPresenter.shared.room.roomId{
                        Qiscus.uiThread.async {
                            QiscusDataPresenter.shared.delegate?.dataPresenter(didChangeContent: data, inRoom: QiscusDataPresenter.shared.room)
                        }
                    }
                }
            }
        }, withFailCompletion: {
            data.linkTitle = "Not Found"
            data.linkDescription = "No description found"
            data.linkImage = Qiscus.image(named: "link")
            data.showLink = false
            
            if let comment = data.comment{
                if comment.commentRoom.roomId == QiscusDataPresenter.shared.room.roomId{
                    Qiscus.uiThread.async {
                        QiscusDataPresenter.shared.delegate?.dataPresenter(didChangeContent: data, inRoom: QiscusDataPresenter.shared.room)
                    }
                }
            }
        })
    }
    func send(Message message:String, topicId:Int, linkData:QiscusLinkData?, indexPath: IndexPath?){
        if linkData != nil{
            linkData!.saveLink()
        }
        Qiscus.logicThread.async {
            self.commentClient.postMessage(message: message, topicId: topicId, linkData: linkData, indexPath: indexPath)
        }
    }
    func delete(DataPresenter data:QiscusCommentPresenter){
        self.delegate?.dataPresenter(dataDeleted: data)
    }
    func resend(DataPresenter data:QiscusCommentPresenter){
        data.commentStatus = .sending
        self.delegate?.dataPresenter(willResendData: data)
        if data.commentType == .text {
            Qiscus.uiThread.async {
                self.commentClient.postComment(data)
            }
        }else{
            if data.isUploaded{
                Qiscus.uiThread.async {
                    self.commentClient.postComment(data)
                }
            }else{
                if data.localFileExist {
                    self.commentClient.uploadMediaData(withData: data)
                }
            }
        }
    }
    public func uploadData(fromPresenter presenter:QiscusCommentPresenter){
        self.commentClient.uploadMediaData(withData: presenter)
    }
    public func newMediaMessage(_ topicId: Int,image:UIImage?,imageName:String,imagePath:URL? = nil, imageNSData:Data? = nil, roomId:Int? = nil, thumbImageRef:UIImage? = nil, videoFile:Bool = true, audioFile:Bool = false){
        Qiscus.logicThread.async {
            var imageData:Data = Data()
            if imageNSData != nil {
                imageData = imageNSData!
            }
            var thumbData:Data = Data()
            var imageMimeType:String = ""
            let imageNameArr = imageName.characters.split(separator: ".")
            let imageExt:String = String(imageNameArr.last!).lowercased()
            let comment = QiscusComment.newComment(withMessage: "", inTopicId: topicId)
            
            if image != nil {
                if !videoFile{
                    var thumbImage = UIImage()
                    
                    let isGifImage:Bool = (imageExt == "gif" || imageExt == "gif_")
                    let isJPEGImage:Bool = (imageExt == "jpg" || imageExt == "jpg_")
                    let isPNGImage:Bool = (imageExt == "png" || imageExt == "png_")
                    
                    if !isGifImage{
                        thumbImage = QiscusFile.createThumbImage(image!, fillImageSize: thumbImageRef)
                    }
                    
                    if isJPEGImage == true{
                        let imageSize = image!.size
                        var bigPart = CGFloat(0)
                        if(imageSize.width > imageSize.height){
                            bigPart = imageSize.width
                        }else{
                            bigPart = imageSize.height
                        }
                        
                        var compressVal = CGFloat(1)
                        if(bigPart > 2000){
                            compressVal = 2000 / bigPart
                        }
                        
                        imageData = UIImageJPEGRepresentation(image!, compressVal)!
                        thumbData = UIImageJPEGRepresentation(thumbImage, 1)!
                        imageMimeType = "image/jpg"
                    }else if isPNGImage == true{
                        imageData = UIImagePNGRepresentation(image!)!
                        thumbData = UIImagePNGRepresentation(thumbImage)!
                        imageMimeType = "image/png"
                    }else if isGifImage == true{
                        if imageNSData == nil{
                            let asset = PHAsset.fetchAssets(withALAssetURLs: [imagePath!], options: nil)
                            if let phAsset = asset.firstObject {
                                
                                let option = PHImageRequestOptions()
                                option.isSynchronous = true
                                option.isNetworkAccessAllowed = true
                                PHImageManager.default().requestImageData(for: phAsset, options: option) {
                                    (data, dataURI, orientation, info) -> Void in
                                    imageData = data!
                                    thumbData = data!
                                    imageMimeType = "image/gif"
                                }
                            }
                        }else{
                            imageData = imageNSData!
                            thumbData = imageNSData!
                            imageMimeType = "image/gif"
                        }
                    }
                }else{
                    if let mime:String = QiscusFileHelper.mimeTypes["\(imageExt)"] {
                        imageMimeType = mime
                        Qiscus.printLog(text: "mime: \(mime)")
                    }
                    thumbData = UIImagePNGRepresentation(image!)!
                }
            }else{
                if let mime:String = QiscusFileHelper.mimeTypes["\(imageExt)"] {
                    imageMimeType = mime
                    Qiscus.printLog(text: "mime: \(mime)")
                }
            }
            var imageThumbName = "thumb_\(comment.commentUniqueId).\(imageExt)"
            let fileName = "\(comment.commentUniqueId).\(imageExt)"
            if videoFile{
                imageThumbName = "thumb_\(comment.commentUniqueId).png"
            }
            let commentFile = QiscusFile()
            if image != nil {
                commentFile.fileLocalPath = QiscusFile.saveFile(imageData, fileName: fileName)
                commentFile.fileThumbPath = QiscusFile.saveFile(thumbData, fileName: imageThumbName)
            }else{
                commentFile.fileLocalPath = QiscusFile.saveFile(imageData, fileName: fileName)
            }
            comment.commentText = "[file]\(fileName) [/file]"
            
            
            commentFile.fileTopicId = topicId
            commentFile.isUploading = true
            commentFile.uploaded = false
            commentFile.fileMimeType = imageMimeType
            commentFile.saveCommentFile()
            commentFile.updateIsUploading(true)
            commentFile.updateUploadProgress(0.0)
            
            comment.commentFileId = commentFile.fileId
            
            let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
            presenter.isUploading = true
            presenter.uploadProgress = CGFloat(0)
            presenter.fileName = fileName
            presenter.toUpload = true
            presenter.uploadData = imageData
            presenter.uploadMimeType = imageMimeType
            presenter.localURL = commentFile.fileLocalPath
            presenter.localThumbURL = commentFile.fileThumbPath
            
            Qiscus.uiThread.async {
                self.delegate?.dataPresenter(gotNewData: presenter, inRoom: self.room)
            }
        }
    }
}
// MARK: QiscusServiceDelegate
extension QiscusDataPresenter: QiscusServiceDelegate{
    func qiscusService(didFinishLoadRoom inRoom: QiscusRoom) {
        let chatRoom = QiscusRoom.copyRoom(room: inRoom)
        Qiscus.logicThread.async {
            let comments = QiscusComment.grouppedComment(inTopicId: chatRoom.roomLastCommentTopicId)
            let presenters = QiscusDataPresenter.getPresenters(fromComments: comments)
            self.room = chatRoom
            self.data = presenters
            Qiscus.uiThread.async {
                self.delegate?.dataPresenter(didFinishLoad: presenters, inRoom: chatRoom)
            }
        }
    }
    func qiscusService(didFailLoadRoom withError: String) {
        self.delegate?.dataPresenter(didFailLoad: withError)
    }
    func qiscusService(didFinishLoadMore inRoom: QiscusRoom, dataCount: Int, from commentId:Int64) {
        let chatRoom = QiscusRoom.copyRoom(room: inRoom)
        if chatRoom.roomId == room.roomId{
            Qiscus.logicThread.async {
                var newData = [[QiscusCommentPresenter]]()
                if dataCount > 0 {
                    var data = [[QiscusComment]]()
                    if commentId > 0 {
                        data = QiscusComment.grouppedComment(inTopicId: chatRoom.roomLastCommentTopicId, fromCommentId: commentId)
                    }else{
                        data = QiscusComment.grouppedComment(inTopicId: chatRoom.roomLastCommentTopicId)
                    }
                    if data.count > 0 {
                        newData = QiscusDataPresenter.getPresenters(fromComments: data)
                    }else{
                        chatRoom.hasLoadMore = false
                    }
                }else{
                    chatRoom.hasLoadMore = false
                }
                self.delegate?.dataPresenter(didFinishLoadMore: newData, inRoom: chatRoom)
            }
        }
    }
    func qiscusService(gotNewMessage data: QiscusCommentPresenter) {
        if data.topicId == self.room.roomLastCommentTopicId{
            self.delegate?.dataPresenter(gotNewData: data, inRoom: self.room)
        }
    }
    func qiscusService(didChangeContent data:QiscusCommentPresenter){
        Qiscus.logicThread.async {
            if data.topicId == self.room.roomLastCommentTopicId {
                Qiscus.uiThread.async {
                    self.delegate?.dataPresenter(didChangeContent: data, inRoom: self.room)
                }
            }
        }
    }
    func qiscusService(didFailLoadMore inRoom: QiscusRoom) {
        let chatRoom = QiscusRoom.copyRoom(room: inRoom)
        Qiscus.logicThread.async {
            if chatRoom.roomLastCommentTopicId == self.room.roomLastCommentTopicId {
                Qiscus.uiThread.async {
                    self.delegate?.dataPresenter(didFailLoadMore: chatRoom)
                }
            }
        }
    }
    func qiscusService(didChangeUser user: QiscusUser, onUserWithEmail email: String) {
        self.delegate?.dataPresenter(didChangeUser: user, onUserWithEmail: email)
    }
    func qiscusService(didChangeRoom room: QiscusRoom, onRoomWithId roomId: Int) {
        if roomId == self.room.roomId{
            self.delegate?.dataPresenter(didChangeRoom: room, onRoomWithId: roomId)
        }
    }
}
extension QiscusDataPresenter: QCommentDelegate{
    func didSuccesPostComment(_ comment:QiscusComment){
        
    }
    func didFailedPostComment(_ comment:QiscusComment){
    
    }
    func downloadingMedia(_ comment:QiscusComment){
    
    }
    func didDownloadMedia(_ comment: QiscusComment){
    
    }
    func didUploadFile(_ comment:QiscusComment){
    
    }
    func uploadingFile(_ comment:QiscusComment){
    
    }
    func didFailedUploadFile(_ comment:QiscusComment){
    
    }
    func didSuccessPostFile(_ comment:QiscusComment){
    
    }
    func didFailedPostFile(_ comment:QiscusComment){
    
    }
    func finishedLoadFromAPI(_ topicId: Int){
    
    }
    func gotNewComment(_ comments:[QiscusComment]){
    
    }
    func didFailedLoadDataFromAPI(_ error: String){
    
    }
    func didFinishLoadMore(){
    
    }
    func commentDidChangeStatus(fromComment comment:QiscusComment, toStatus: QiscusCommentStatus){
    
    }
    func performResendMessage(onIndexPath: IndexPath){
    
    }
    func performDeleteMessage(onIndexPath:IndexPath){
    
    }
    func didChangeUserStatus(withUser user:QiscusUser){
    
    }
    func didChangeUserName(withUser user:QiscusUser){
    
    }
    func didChangeSize(comment: QiscusComment){
    
    }
}
