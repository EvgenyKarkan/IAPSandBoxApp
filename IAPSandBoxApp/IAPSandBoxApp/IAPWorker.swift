//
//  IAPWorker.swift
//  IAPSandBoxApp
//
//  Created by Evgeny Karkan on 11/12/15.
//  Copyright © 2015 Evgeny Karkan. All rights reserved.
//

import Foundation
import StoreKit

//MARK: - Blocks
typealias RestoreTransactionsCompletionBlock = NSError? -> Void
typealias LoadProductsCompletionBlock        = ([SKProduct]?, NSError?) -> Void
typealias PurchaseProductCompletionBlock     = (NSError?) -> Void
typealias LoadProductsRequestInfo            = (request: SKProductsRequest, completion: LoadProductsCompletionBlock)
typealias PurchaseProductRequestInfo         = (productId: String, completion: PurchaseProductCompletionBlock)



class IAPWorker: NSObject {

	//MARK: - Singleton
	
	static let worker = IAPWorker()

	//MARK: - Properties
	
	private var availableProducts       = [String : SKProduct]()
    private var purchasedProductIds     = [String]()
    private var loadProductsRequests    = [LoadProductsRequestInfo]()
    private var purchaseProductRequests = [PurchaseProductRequestInfo]()
	private var restoreTransactionsCompletionBlock: RestoreTransactionsCompletionBlock?
	
	//MARK: - Init
	
	override init() {
		super.init()
	
		SKPaymentQueue.defaultQueue().addTransactionObserver(self)
	}

	
	private func canMakePayements() -> Bool {
		
        var result = false
        result     = SKPaymentQueue.canMakePayments()
		
		if !result {
			print("Payements unavialable")
		}
		
		return result
	}
	
	//MARK: - Public APIs
	
	func purchaseProductWithId(productId: String, completion: PurchaseProductCompletionBlock) {
		
		if !self.canMakePayements() {
			let error = NSError(domain: "inAppPurchase", code: 0, userInfo: [NSLocalizedDescriptionKey: "In App Purchasing is unavailable"])
			completion(error)
		}
		else {
			self.loadProductsWithIds([productId]) { (products, error) -> Void in
				
				if error != nil {
					completion(error);		print("ERROR on product load \(error)")
				}
				else {
					print("Loaded products \(products!)")
					
					if products?.count == 0 {
						let error = NSError(domain: "inAppPurchase", code: 1, userInfo: [NSLocalizedDescriptionKey: "No any product have been loaded"])
						completion(error)
					}
					else {
						if let product = products?.first {
							self.purchaseProduct(product, completion: completion)
						}
					}
				}
			}
		}
	}
	
	private func loadProductsWithIds(productIds: [String], completion: LoadProductsCompletionBlock) {
		
        var loadedProducts = [SKProduct]()
        var remainingIds   = [String]()
		
		for productId in productIds {
			if let product = self.availableProducts[productId] {
				loadedProducts.append(product)
			}
			else {
				remainingIds.append(productId)
			}
		}
		
		if remainingIds.count == 0 {
			completion(loadedProducts, nil)
		}
		
		print("Remaining IDs \(remainingIds)")
		
        let request      = SKProductsRequest(productIdentifiers: Set(remainingIds))
        request.delegate = self
		
		self.loadProductsRequests.append(LoadProductsRequestInfo(request: request, completion: completion))
		request.start()
	}
	
	func purchaseProduct(product: SKProduct, completion: PurchaseProductCompletionBlock) {
		
		self.purchaseProductRequests.append(PurchaseProductRequestInfo(productId: product.productIdentifier, completion: completion))
		
		let payment = SKPayment(product: product)
		
		SKPaymentQueue.defaultQueue().addPayment(payment)
	}
	
	private func callLoadProductsCompletionForRequest(request: SKProductsRequest, responseProducts: [SKProduct]?, error: NSError?) {
		
		dispatch_async(dispatch_get_main_queue()) {
			
			for i in 0..<self.loadProductsRequests.count {
				
				let requestInfo = self.loadProductsRequests[i]
				
				if requestInfo.request == request {
					self.loadProductsRequests.removeAtIndex(i)
					
					print("Request info...... \(requestInfo)")
					
					print("Response products \(responseProducts)")
					print("Error \(error)")
					
					requestInfo.completion(responseProducts, error)
					return
				}
			}
		}
	}
	
	private func callPurchaseProductCompletionForProduct(productId: String, error: NSError?) {
		
		dispatch_async(dispatch_get_main_queue()) {
			
			for i in 0..<self.purchaseProductRequests.count {
				
				let requestInfo = self.purchaseProductRequests[i]
				
				if requestInfo.productId == productId {
					self.purchaseProductRequests.removeAtIndex(i)
					requestInfo.completion(error)
					return
				}
			}
		}
	}
}

//MARK: - SKPaymentTransactionObserver protocol APIs

extension IAPWorker: SKPaymentTransactionObserver {

	func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
		
		for transaction in transactions {
			let productId = transaction.payment.productIdentifier
			
			switch transaction.transactionState {
				
				case .Restored: fallthrough
				
				case .Purchased:
					self.purchasedProductIds.append(productId)
					//savePurchasedItems()
					
					self.callPurchaseProductCompletionForProduct(productId, error: nil)
					
					queue.finishTransaction(transaction)
				
				case .Failed:
					self.callPurchaseProductCompletionForProduct(productId, error: transaction.error)
					
					queue.finishTransaction(transaction)
				
				case .Purchasing:
					print("Purchasing \(productId)...")
				
				default: break
			}
		}
	}
	
	func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
		
		if let completion = self.restoreTransactionsCompletionBlock {
			completion(nil)
		}
	}
	
	func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
		
		if let completion = self.restoreTransactionsCompletionBlock {
			completion(error)
		}
	}
}

extension IAPWorker: SKProductsRequestDelegate {
	
	func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
		
		for product in response.products {
			self.availableProducts[product.productIdentifier] = product
		}
		
		print("REQUEST -> -> \(request)")
		
		print("DID RECIEVE RESPONSE \(response)")
		print("RESPONSE PRODUCTS \(response.products)")
		print("INVALID PRODUCTS IDENTIFIERS \(response.invalidProductIdentifiers)")
		
		self.callLoadProductsCompletionForRequest(request, responseProducts: response.products, error: nil)
	}
	
	func request(request: SKRequest, didFailWithError error: NSError) {
		
		if let productRequest = request as? SKProductsRequest {
			self.callLoadProductsCompletionForRequest(productRequest, responseProducts: nil, error: error)
		}
	}
}

