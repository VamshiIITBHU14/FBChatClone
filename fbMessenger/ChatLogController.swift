//
//  ChatLogController.swift
//  fbMessenger
//
//  Created by Vamshi Krishna on 01/06/17.
//  Copyright © 2017 VamshiKrishna. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class ChatLogController: UICollectionViewController , UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    private let cellId = "cellId"
    
    var friend:Friend?{
        didSet{
            navigationItem.title = friend?.name
        }
    }
    
    let messageInputContainerView:UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    let inputTextField:UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter Message Here"
        return tf
    }()
    
    let sendButton:UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send", for: .normal)
        let titleColor = UIColor.returnRGBColor(r: 0, g: 137, b: 249, alpha: 1)
        button.setTitleColor(titleColor, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        return button
    }()
    
    func handleSend(){
        guard let delegate = UIApplication.shared.delegate as?AppDelegate else{
            return
        }
        let context = delegate.persistentContainer.viewContext
        _ = FriendsController.createMessageWithText(text: inputTextField.text!, friend: friend!, minutesAgo: 2, context: context, isSender: true)
        
        do{
            try context.save()
            inputTextField.text = nil
            
        }catch let error{
            print(error)
        }
    }
    
    private func setupInputComponents(){
       let topBorderView = UIView()
       topBorderView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        
       messageInputContainerView.addSubview(inputTextField)
       messageInputContainerView.addSubview(sendButton)
       messageInputContainerView.addSubview(topBorderView)
        
       messageInputContainerView.addConstraintsWithFormat(format: "H:|-8-[v0][v1(60)]|", views: inputTextField ,sendButton)
       messageInputContainerView.addConstraintsWithFormat(format: "V:|[v0]|", views: inputTextField)
       messageInputContainerView.addConstraintsWithFormat(format: "V:|[v0]|", views: sendButton)
       messageInputContainerView.addConstraintsWithFormat(format: "H:|[v0]|", views: topBorderView)
       messageInputContainerView.addConstraintsWithFormat(format: "V:|[v0(0.5)]", views: topBorderView)
    }
    
    var bottomConstraint:NSLayoutConstraint?
    
    lazy var fetchedRequestsController:NSFetchedResultsController = { () -> NSFetchedResultsController<NSFetchRequestResult> in
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "friend.name = %@", (self.friend?.name)!)
        let delegate = UIApplication.shared.delegate as?AppDelegate;
        let context = delegate?.persistentContainer.viewContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context!, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    var blockOperations = [BlockOperation]()
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if type == .insert{
           blockOperations.append(BlockOperation(block: { 
            (self.collectionView?.insertItems(at: [newIndexPath!]))!
           }))
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.performBatchUpdates({ 
            for operation in self.blockOperations{
                operation.start()
            }
        }, completion: { (completed) in
            let lastItem = (self.fetchedRequestsController.sections?[0].numberOfObjects)! - 1
            let indexPath = IndexPath(item: lastItem, section: 0)
            self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
        })
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try fetchedRequestsController.performFetch()
        }catch let error{
            print(error)
        }
        
        tabBarController?.tabBar.isHidden = true
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(ChatlogCell.self, forCellWithReuseIdentifier: cellId)
        view.addSubview(messageInputContainerView)
        view.addConstraintsWithFormat(format: "H:|[v0]|", views: messageInputContainerView)
        view.addConstraintsWithFormat(format: "V:[v0(48)]", views: messageInputContainerView)
        bottomConstraint = NSLayoutConstraint(item: messageInputContainerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraint(bottomConstraint!)
        setupInputComponents()
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboard), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboard), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Simulate", style: .plain, target: self, action: #selector(simulateSenderMessages))
    }
    
    func simulateSenderMessages(){
        guard let delegate = UIApplication.shared.delegate as?AppDelegate else{
            return
        }
        let context = delegate.persistentContainer.viewContext
        _ =  FriendsController.createMessageWithText(text: "This message was sent a few minutes ago....", friend: friend!, minutesAgo: 1, context: context)
        _ =  FriendsController.createMessageWithText(text: "Another message was sent a few seconds ago....", friend: friend!, minutesAgo: 0, context: context)
        do{
            try context.save()
         
        }catch let error{
            print(error)
        }
    }
    
    func handleKeyboard(notification:NSNotification){
        if let userInfo = notification.userInfo{
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
            let isKeyboardShowing = notification.name == NSNotification.Name.UIKeyboardWillShow
            bottomConstraint?.constant = isKeyboardShowing ? -(keyboardFrame?.height)! : 0
            UIView.animate(withDuration: 0, delay: 0, options: .curveEaseOut, animations: { 
                self.view.layoutIfNeeded()
            }, completion: { (completed) in
                if (isKeyboardShowing){
                    let lastItem = (self.fetchedRequestsController.sections?[0].numberOfObjects)! - 1
                    let indexPath = IndexPath(item: lastItem, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
            })
           
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        inputTextField.endEditing(true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = fetchedRequestsController.sections?[0].numberOfObjects{
            return count
        }
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatlogCell
        let message = fetchedRequestsController.object(at: indexPath) as! Message
        cell.messageTextView.text = message.text
        
        
        if  let messageText = message.text, let profileImageName = message.friend?.profileImageName{
            
            cell.profileImageView.image = UIImage(named: profileImageName)
            let size = CGSize(width: 250, height: 1000)
            let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
            let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 18)], context: nil)
            if !message.isSender{
                cell.messageTextView.frame = CGRect(x: 48+8, y: 0, width: estimatedFrame.width + 16, height: estimatedFrame.height+20)
                cell.textBubbleView.frame = CGRect(x: 48 - 10, y: -4, width: estimatedFrame.width + 16 + 8 + 16, height: estimatedFrame.height+20+6)
                cell.profileImageView.isHidden = false
                cell.bubbleImageView.image = ChatlogCell.grayBubbleImage
                cell.bubbleImageView.tintColor = UIColor(white: 0.95, alpha: 1)
                cell.messageTextView.textColor = UIColor.black
            }
            else{
                
                //outgoing sender messages
                cell.messageTextView.frame = CGRect(x: view.frame.width - estimatedFrame.width - 16 - 16 - 8 , y: 0, width: estimatedFrame.width + 16, height: estimatedFrame.height+20)
                cell.textBubbleView.frame = CGRect(x: view.frame.width-estimatedFrame.width - 16 - 8 - 16 - 10, y: -4, width: estimatedFrame.width + 16 + 8 + 10, height: estimatedFrame.height+20+6)
                cell.profileImageView.isHidden = true
                cell.bubbleImageView.image = ChatlogCell.blueBubbleImage
                cell.bubbleImageView.tintColor = UIColor.returnRGBColor(r: 0, g: 137, b: 249, alpha: 1)
                cell.messageTextView.textColor = UIColor.white
            }
           
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let message = fetchedRequestsController.object(at: indexPath) as! Message
        if let messageText = message.text{
            let size = CGSize(width: 250, height: 1000)
            let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
            let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 18)], context: nil)
            return CGSize(width: view.frame.width, height: estimatedFrame.height+20)
        }
        return CGSize(width: view.frame.width, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(8, 0, 0, 0)
    }
}

class ChatlogCell:BaseCell{
    
    static let grayBubbleImage = UIImage(named:"bubble_gray")?.resizableImage(withCapInsets: UIEdgeInsetsMake(22, 26, 22, 26)).withRenderingMode(.alwaysTemplate)
    static let blueBubbleImage = UIImage(named:"bubble_blue")?.resizableImage(withCapInsets: UIEdgeInsetsMake(22, 26, 22, 26)).withRenderingMode(.alwaysTemplate)
    
    
    let messageTextView : UITextView = {
        let textView = UITextView()
        textView.text = "Sample Message"
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.backgroundColor = UIColor.clear
        textView.isEditable = false
        return textView
    }()
    
    let textBubbleView:UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        return view
    }()
    
    let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 15
        iv.layer.masksToBounds = true
        return iv
    }()
    
    let bubbleImageView : UIImageView = {
        let iv = UIImageView()
        iv.image = ChatlogCell.grayBubbleImage
        iv.tintColor = UIColor(white: 0.90, alpha: 1)
        return iv
    }()
    
    override func setupViews() {
        super.setupViews()

        addSubview(textBubbleView)
        addSubview(messageTextView)
        addSubview(profileImageView)
        
        addConstraintsWithFormat(format: "H:|-8-[v0(30)]|", views: profileImageView)
        addConstraintsWithFormat(format: "V:[v0(30)]|", views: profileImageView)
        
        textBubbleView.addSubview(bubbleImageView)
        textBubbleView.addConstraintsWithFormat(format: "H:|[v0]|", views: bubbleImageView)
        textBubbleView.addConstraintsWithFormat(format: "V:|[v0]|", views: bubbleImageView)
       
    }
    
}
