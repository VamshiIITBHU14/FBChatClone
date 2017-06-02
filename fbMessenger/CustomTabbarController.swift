//
//  CustomTabbarController.swift
//  fbMessenger
//
//  Created by Vamshi Krishna on 01/06/17.
//  Copyright © 2017 VamshiKrishna. All rights reserved.
//

import Foundation
import UIKit

class CustomTabbarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        let friendsController = FriendsController(collectionViewLayout: layout)
        let recentMessagesControlelr = UINavigationController(rootViewController: friendsController)
        recentMessagesControlelr.tabBarItem.title = "Recent"
        recentMessagesControlelr.tabBarItem.image = UIImage(named: "recent")
        
        viewControllers = [recentMessagesControlelr, createDummyTabbarController(title: "Calls", imageName: "calls"), createDummyTabbarController(title: "Groups", imageName: "groups"), createDummyTabbarController(title: "People", imageName: "people"), createDummyTabbarController(title: "Settings", imageName: "settings")]
    }
    
    private func createDummyTabbarController(title:String, imageName:String) -> UINavigationController{
        let viewController = UIViewController()
        let navController = UINavigationController(rootViewController: viewController)
        navController.tabBarItem.title = title
        navController.tabBarItem.image = UIImage(named: imageName)
        return navController
    }
}
