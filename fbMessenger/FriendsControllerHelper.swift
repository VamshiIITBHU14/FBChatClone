//
//  FriendsControllerHelper.swift
//  fbMessenger
//
//  Created by Vamshi Krishna on 30/05/17.
//  Copyright © 2017 VamshiKrishna. All rights reserved.
//

import Foundation

import UIKit
import CoreData

extension FriendsController{
    
    func clearData(){
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else{
            return
        }
        
        let context = delegate.persistentContainer.viewContext
        do{
            let entityNames = ["Friend", "Message"]
            for entityName in entityNames{
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
                let objects = try (context.fetch(fetchRequest))
                for object in objects{
                    context.delete(object)
                }
            }
            try (context.save())
        } catch let error{
            print(error)
        }
    }
    func setupData(){
        clearData()
        guard let delegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let context = delegate.persistentContainer.viewContext
        
        createSteveMessagesWithContext(context: context)
        
        let donald = NSEntityDescription.insertNewObject(forEntityName: "Friend", into: context) as! Friend
        donald.name = "Donald Trump"
        donald.profileImageName = "donald_trump_profile"
        _=FriendsController.createMessageWithText(text: "My name is Donald Trump!", friend: donald, minutesAgo: 5, context: context)
        
        let gandhi = NSEntityDescription.insertNewObject(forEntityName: "Friend", into: context) as! Friend
        gandhi.name = "Mahatma Gandhi"
        gandhi.profileImageName = "gandhi"
        _=FriendsController.createMessageWithText(text: "My name is MK Gandhi", friend: gandhi, minutesAgo: 60*36, context: context)
        
        let hillary = NSEntityDescription.insertNewObject(forEntityName: "Friend", into: context) as! Friend
        hillary.name = "Hillary Clinton"
        hillary.profileImageName = "hillary_profile"
        _=FriendsController.createMessageWithText(text: "My name is Hillary Clinton", friend: hillary, minutesAgo: 8*60*36, context: context)
        
        do{
            try(context.save())
        } catch let error{
            print (error)
        }
    }
    
    private func createSteveMessagesWithContext(context: NSManagedObjectContext){
        let steve = NSEntityDescription.insertNewObject(forEntityName: "Friend", into: context) as! Friend
        steve.name = "Steve Jobs"
        steve.profileImageName = "steve_profile"
        
        _=FriendsController.createMessageWithText(text: "Hello! I am Jobs!Hello! I am Jobs!Hello! I am Jobs!Hello! I am Jobs!Hello! I am Jobs!Hello! I am Jobs!", friend: steve, minutesAgo: 10,  context: context)
        _=FriendsController.createMessageWithText(text: "How are you doing?", friend: steve, minutesAgo: 8,  context: context)
        _=FriendsController.createMessageWithText(text: "How's work? Interested in working for apple?How's work? Interested in working for apple?How's work? Interested in working for apple?", friend: steve, minutesAgo: 7,  context: context)
        
        //response messages
        _=FriendsController.createMessageWithText(text: "Yes! I would love to", friend: steve, minutesAgo: 4,  context: context, isSender: true)
        _=FriendsController.createMessageWithText(text: "Whatever you say!Whatever you say!Whatever you say!Whatever you say!", friend: steve, minutesAgo: 6,  context: context, isSender: true)
        _=FriendsController.createMessageWithText(text: "Yes! I would be humbled!Yes! I would be humbled!Yes! I would be humbled!Yes! I would be humbled!", friend: steve, minutesAgo: 2,  context: context, isSender: true)
    }
    
    static func createMessageWithText(text:String, friend:Friend,minutesAgo:Double, context:NSManagedObjectContext, isSender:Bool = false) -> Message {
        let message = NSEntityDescription.insertNewObject(forEntityName: "Message", into: context) as! Message
        message.friend = friend
        message.text = text
        message.date = NSDate().addingTimeInterval(-minutesAgo * 60)
        message.isSender = NSNumber(booleanLiteral: isSender) as! Bool
        friend.lastMessage = message
        return message
    }
    
}
