//  DSReceptionist.h
//  Copyright (c) 2009 Decimus Software, Inc. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  is permitted provided that the following conditions are met:
//     - Redistributions of source code must retain the above copyright notice,
//       this list of conditions, and the following disclaimer.
//     - Redistributions in binary form must reproduce the above copyright notice,
//       this list of conditions, and the following disclaimer in the documentation
//       and/or other materials provided with the distribution.
//     - Neither the name of Decimus Software nor the names of the contributors may
//       be used to endorse or promote products derived from this software without
//       specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
//  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
//  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



//! Block typedef for DSReceptionist KVO callbacks.
//! (Key path and object should use the block's scope capture.)
typedef void (^ReceptionistTaskBlock)(NSDictionary *change);


//! Allows the use of blocks as the recipients of KVO notifications.
//! This helps with receiving the notifications on a specific thread/dispatch queue for safety, and
//! also having a dedicated observer object helps mitigate much of the awkwardness of KVO.  Plus,
//! blocks are helpful.
//!
//! Note: If you want this object to survive GC and still provide you notifications, you need to maintain a reference to it.
//!       KVO changes in 10.6 mean that it will no longer be kept alive by the KVO machinery.
//! 
//! This is a class cluster; only use the factory methods to create instances.
@interface DSReceptionist : NSObject {
	dispatch_queue_t dispatchQueue;		//!< Dispatch queue to submit block to, for dispatch mode
	NSOperationQueue* operationQueue;	//!< NSOperationQueue to submit block to, for NSOperationQueue mode
	ReceptionistTaskBlock taskBlock;	//!< Block to call when a KVO callback occurs
}

//! Creates a receptionist that will submit the given block to the given NSOperation queue when a KVO notification occurs.
//! Change holds values for NSKeyValueObservingOptions=0.
//! If queue is nil, task will be executed synchronously on the notifying thread.
+ (id)receptionistForKeyPath:(NSString *)path
					  object:(id)obj
			  operationQueue:(NSOperationQueue *)queue
						task:(void (^)(NSDictionary* change))task;
//! Creates a receptionist that will submit the given block to the given dispatch queue when a KVO notification occurs.
//! Change holds values for NSKeyValueObservingOptions=0.
//! If queue is NULL, task will be executed synchronously on the notifying thread.
+ (id)receptionistForKeyPath:(NSString *)path
					  object:(id)obj
					   queue:(dispatch_queue_t)queue
						task:(void (^)(NSDictionary* change))task;
//! Creates a receptionist that will submit the given block to the given NSOperation queue when a KVO notification occurs.
//! If queue is nil, task will be executed synchronously on the notifying thread.
+ (id)receptionistForKeyPath:(NSString *)path
					  object:(id)obj
					 options:(NSKeyValueObservingOptions)options
			  operationQueue:(NSOperationQueue *)queue
						task:(void (^)(NSDictionary* change))task;
//! Creates a receptionist that will submit the given block to the given dispatch queue when a KVO notification occurs.
//! If queue is NULL, task will be executed synchronously on the notifying thread.
+ (id)receptionistForKeyPath:(NSString *)path
					  object:(id)obj
					 options:(NSKeyValueObservingOptions)options
					   queue:(dispatch_queue_t)queue
						task:(void (^)(NSDictionary* change))task;

//! Creates a receptionist that will submit the given block to the given NSOperation queue when a KVO notification occurs.
//! The effect is similar to observing a joined arrayPath+elementPath across the array boundary, except unlike normal KVO, it actually works.
//! Changes to an element's elementPath value are treated as replacements in the value of the array, but NO INDEXES are provided.
//! Change holds values for NSKeyValueObservingOptions=0.
//! If queue is nil, task will be executed synchronously on the notifying thread.
+ (id)receptionistForArrayKeyPath:(NSString*)arrayPath
				   elementKeyPath:(NSString*)elementPath
						   object:(id)obj
				   operationQueue:(NSOperationQueue*)queue
							 task:(void (^)(NSDictionary* change))task;
//! Creates a receptionist that will submit the given block to the given dispatch queue when a KVO notification occurs.
//! The effect is similar to observing a joined arrayPath+elementPath across the array boundary, except unlike normal KVO, it actually works.
//! Changes to an element's elementPath value are treated as replacements in the value of the array, but NO INDEXES are provided.
//! Change holds values for NSKeyValueObservingOptions=0.
//! If queue is NULL, task will be executed synchronously on the notifying thread.
+ (id)receptionistForArrayKeyPath:(NSString*)arrayPath
				   elementKeyPath:(NSString*)elementPath
						   object:(id)obj
							queue:(dispatch_queue_t)queue
							 task:(void (^)(NSDictionary* change))task;
//! Creates a receptionist that will submit the given block to the given NSOperation queue when a KVO notification occurs.
//! The effect is similar to observing a joined arrayPath+elementPath across the array boundary, except unlike normal KVO, it actually works.
//! Changes to an element's elementPath value are treated as replacements in the value of the array, but NO INDEXES are provided.
//! If queue is nil, task will be executed synchronously on the notifying thread.
+ (id)receptionistForArrayKeyPath:(NSString*)arrayPath
				   elementKeyPath:(NSString*)elementPath
						   object:(id)obj
						  options:(NSKeyValueObservingOptions)options
				   operationQueue:(NSOperationQueue*)queue
							 task:(void (^)(NSDictionary* change))task;
//! Creates a receptionist that will submit the given block to the given dispatch queue when a KVO notification occurs.
//! The effect is similar to observing a joined arrayPath+elementPath across the array boundary, except unlike normal KVO, it actually works.
//! Changes to an element's elementPath value are treated as replacements in the value of the array, but NO INDEXES are provided.
//! If queue is NULL, task will be executed synchronously on the notifying thread.
+ (id)receptionistForArrayKeyPath:(NSString*)arrayPath
				   elementKeyPath:(NSString*)elementPath
						   object:(id)obj
						  options:(NSKeyValueObservingOptions)options
							queue:(dispatch_queue_t)queue
							 task:(void (^)(NSDictionary* change))task;

//! Convenience method making a receptionist that calls will/did change appropriately to make
//! obj.dependentKey compliant with KVO for depending on obj.arrayPath.elementPath.
+ (id)receptionistMakingKey:(NSString*)dependentKey
	dependentOnArrayKeyPath:(NSString*)arrayPath
			 elementKeyPath:(NSString*)elementPath
					 object:(id)obj;

//! Stops observation and cleans up resources.
//! This object should no longer be used after this call.
- (void)endObservation;

@end


//! DSReceptionist additions to NSObject
@interface NSObject (DSReceptionistAdditions)
//! Creates a DSReceptionist to create the designated dependency, and attaches it permanently to the receiving object using Obj-C associated objects.
//! This allows you to not have to clutter your code with an additional ivar for the receptionist in the common case that the key is never going to
//! stop its dependency, nor do you need any access to the actual receptionist.
//! \see -[DSReceptionist receptionistMakingKey:dependentOnArrayKeyPath:elementKeyPath:object:]
- (void)dsMakeKey:(NSString*)dependentKey
dependentOnArrayKeyPath:(NSString*)arrayPath
   elementKeyPath:(NSString*)elementPath;
@end
