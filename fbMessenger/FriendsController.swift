//
//  ViewController.swift
//  fbMessenger
//
//  Created by Vamshi Krishna on 30/05/17.
//  Copyright © 2017 VamshiKrishna. All rights reserved.
//

import UIKit
import CoreData

class FriendsController: UICollectionViewController, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    private let cellId = "cellId"
    
    lazy var fetchedResultsController:NSFetchedResultsController = { () -> NSFetchedResultsController<NSFetchRequestResult> in
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Friend")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastMessage.date", ascending: false)]
        fetchRequest.predicate = NSPredicate(format:"lastMessage != nil")
        let delegate = UIApplication.shared.delegate as?AppDelegate;
        let context = delegate?.persistentContainer.viewContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context!, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if type == .insert{
            blockOperations.append(BlockOperation(block: {
                (self.collectionView?.insertItems(at: [newIndexPath!]))!
            }))
        }
    }
    
    var blockOperations = [BlockOperation]()
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.performBatchUpdates({
            for operation in self.blockOperations{
                operation.start()
            }
        }, completion: { (completed) in
            let lastItem = (self.fetchedResultsController.sections?[0].numberOfObjects)! - 1
            let indexPath = IndexPath(item: lastItem, section: 0)
            self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = false
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Recent"
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        setupData()
        collectionView?.register(MessageCell.self, forCellWithReuseIdentifier: cellId)
        
        do{
            try fetchedResultsController.performFetch()
        }catch let error{
            print(error)
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add Mark", style: .plain, target: self, action: #selector(addMark))
    }
    
    func addMark(){
        guard let delegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let context = delegate.persistentContainer.viewContext
        let mark = NSEntityDescription.insertNewObject(forEntityName: "Friend", into: context) as! Friend
        mark.name = "Mark Zuckerberg"
        mark.profileImageName = "zuckprofile"
        _=FriendsController.createMessageWithText(text: "Hey, I am Mark!", friend: mark, minutesAgo: 8*60*36, context: context)
        
        let bill = NSEntityDescription.insertNewObject(forEntityName: "Friend", into: context) as! Friend
        bill.name = "Bill Gates"
        mark.profileImageName = "zuckprofile"
        _=FriendsController.createMessageWithText(text: "Hey, I am Bill!", friend: bill, minutesAgo: 8*60*24, context: context)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = fetchedResultsController.sections?[section].numberOfObjects{
            return count
        }
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MessageCell
        let friend = fetchedResultsController.object(at: indexPath) as! Friend
        cell.message = friend.lastMessage
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 100)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let layout = UICollectionViewFlowLayout()
        let controller = ChatLogController(collectionViewLayout: layout)
        let friend = fetchedResultsController.object(at: indexPath) as! Friend
        controller.friend = friend
        navigationController?.pushViewController(controller, animated: true)
    }
}

class MessageCell:BaseCell{
    
    override var isHighlighted: Bool{
        didSet{
            backgroundColor = isHighlighted ? UIColor.returnRGBColor(r: 0, g: 134, b: 249, alpha: 1) : UIColor.white
            nameLabel.textColor = isHighlighted ? UIColor.white : UIColor.black
            timeLabel.textColor = isHighlighted ? UIColor.white : UIColor.black
            messageLabel.textColor = isHighlighted ? UIColor.white : UIColor.black
        }
    }
    var message:Message?{
        didSet{
            nameLabel.text = message?.friend?.name
            messageLabel.text =  message?.text
            
            if let profileImageName  = message?.friend?.profileImageName{
                profileImageView.image = UIImage(named: profileImageName)
                hasReadImageView.image = UIImage(named: profileImageName)
            }
            
            if let date = message?.date{
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm a"
                let elapsedTimeInSeconds = NSDate().timeIntervalSince(date as Date)
                let secondsInDay : TimeInterval = 60*60*24
                
                if(elapsedTimeInSeconds > 7*secondsInDay){
                    dateFormatter.dateFormat = "MM/dd/yy"
                } else if elapsedTimeInSeconds > secondsInDay{
                    dateFormatter.dateFormat = "EEE"
                }
                
                timeLabel.text = dateFormatter.string(from: date as Date)
            }
        }
    }
    
    let profileImageView:UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 34
        iv.layer.masksToBounds = true
        return iv
    }()
    
    let nameLabel:UILabel = {
        let label = UILabel()
        label.text = "Friend's Name"
        label.font = UIFont.systemFont(ofSize: 18)
        return label
    }()
    
    let messageLabel:UILabel = {
        let label = UILabel()
        label.text = "Message MessageMessageMessage containerViewcontainerViewcontainerView"
        label.textColor = UIColor.darkGray
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    let timeLabel : UILabel = {
        let label = UILabel()
        label.text = "09:50 pm"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .right
        return label
    }()
    
    let dividerLineView:UIView = {
        let dv = UIView()
        dv.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        return dv
    }()
    
    let hasReadImageView : UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 10
        iv.layer.masksToBounds = true
        return iv
    }()
    
    override func setupViews() {
        addSubview(profileImageView)
        addSubview(dividerLineView)
        
        setupContainerView()
        profileImageView.image = UIImage(named:"zuckprofile")
        hasReadImageView.image = UIImage(named:"zuckprofile")
        addConstraintsWithFormat(format: "H:|-12-[v0(68)]", views: profileImageView)
        addConstraintsWithFormat(format: "V:[v0(68)]", views: profileImageView)
        addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        addConstraintsWithFormat(format: "H:|-82-[v0]|", views: dividerLineView)
        addConstraintsWithFormat(format: "V:[v0(1)]|", views: dividerLineView)
        
    }
    
    private func setupContainerView() {
        let containerView = UIView()
        addSubview(containerView)
        addConstraintsWithFormat(format: "H:|-90-[v0]|", views: containerView)
        addConstraintsWithFormat(format: "V:[v0(50)]", views: containerView)
        addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        containerView.addSubview(nameLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(hasReadImageView)
        
        containerView.addConstraintsWithFormat(format: "H:|[v0][v1(80)]-12-|", views: nameLabel, timeLabel)
        containerView.addConstraintsWithFormat(format: "V:|[v0][v1(24)]|", views: nameLabel,messageLabel)
        containerView.addConstraintsWithFormat(format: "H:|[v0]-8-[v1(20)]-12-|", views: messageLabel, hasReadImageView)
        containerView.addConstraintsWithFormat(format: "V:|[v0(24)]", views: timeLabel)
        containerView.addConstraintsWithFormat(format: "V:[v0(20)]|", views: hasReadImageView)
    }
}

class BaseCell:UICollectionViewCell{
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews(){
        
    }
}


