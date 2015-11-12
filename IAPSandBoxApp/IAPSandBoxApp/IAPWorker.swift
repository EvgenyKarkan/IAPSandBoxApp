//
//  IAPWorker.swift
//  IAPSandBoxApp
//
//  Created by Evgeny Karkan on 11/12/15.
//  Copyright © 2015 Evgeny Karkan. All rights reserved.
//

import Foundation
import StoreKit


class IAPWorker: NSObject {

	//MARK: - Singleton
	
	static let worker = IAPWorker()

	//MARK: - Init
	
	override init() {
		super.init()
	
		SKPaymentQueue.defaultQueue().addTransactionObserver(self)
	}

	
	func canMakePayements() -> Bool {
		
        var result = false
        result     = SKPaymentQueue.canMakePayments()
		
		if !result {
			print("Payements unavialable")
		}
		
		return result
	}
}

//MARK: - SKPaymentTransactionObserver protocol APIs

extension IAPWorker: SKPaymentTransactionObserver {

	func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
		
	}
}
