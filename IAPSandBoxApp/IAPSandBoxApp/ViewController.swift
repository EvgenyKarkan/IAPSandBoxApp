//
//  ViewController.swift
//  IAPSandBoxApp
//
//  Created by Evgeny Karkan on 11/12/15.
//  Copyright © 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	@IBOutlet weak var buyButton: UIButton!
	
	let iapWorker = IAPWorker.worker


	//MARK: - Action
	
	@IBAction func buttonDidPressed(sender: AnyObject) {
		
		self.iapWorker.purchaseProductWithId("1_extra_coin") { (error) -> Void in
			
			if error != nil {
				print("ERROR \(error)")
				
			}
			else {
				print("SUCCESS")
			}
		}
	}
}

