//  DSReceptionist.m
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


#import "DSReceptionist.h"

#import <objc/runtime.h>


//! DSReceptionist internal methods
@interface DSReceptionist ()
//! Designated initializer
- (id)initWithDispatchQueue:(dispatch_queue_t)dispatchQueue operationQueue:(NSOperationQueue*)operationQueue task:(ReceptionistTaskBlock)task;
//! Submits the user's task block to the user's dispatch/NSOperation queue with the given change dictionary
- (void)observedChange:(NSDictionary*)change;
@end

//! Concrete receptionist class for key paths that don't cross an array boundary
@interface DSScalarReceptionist : DSReceptionist {
	id observedObject;					//!< Object being observed
	NSString* keyPath;					//!< Key path of observedObject being observed
}
//! Designated initializer
- (id)initWithKeyPath:(NSString*)path
			   object:(id)obj
			  options:(NSKeyValueObservingOptions)_options
		dispatchQueue:(dispatch_queue_t)_dispatchQueue
	   operationQueue:(NSOperationQueue*)_opQueue
				 task:(ReceptionistTaskBlock)task;
@end

//! Concrete receptionist class for key paths crossing an array boundary.
@interface DSArrayReceptionist : DSReceptionist {
	id observedObject;							//!< Object being observed
	NSString* arrayPath;						//!< Key path from observedObject to the array
	NSString* elementPath;						//!< Key path from each array element to the value in question
	NSKeyValueObservingOptions userKVOOptions;	//!< User's KVO options, which may not be the actual options we pass to various observations
	BOOL haveReceivedInitial;					//!< Flag set once we've received the initial array observation notice, so we can filter it out if the user didn't want it
}
//! Designated initializer
- (id)initWithArrayKeyPath:(NSString*)arrayPath
			elementKeyPath:(NSString*)elementPath
					object:(id)obj
				   options:(NSKeyValueObservingOptions)options
			 dispatchQueue:(dispatch_queue_t)dispatchQueue
			operationQueue:(NSOperationQueue*)opQueue
					  task:(ReceptionistTaskBlock)task;
@end

@implementation DSReceptionist

+ (id)receptionistForKeyPath:(NSString *)path object:(id)obj operationQueue:(NSOperationQueue *)queue task:(ReceptionistTaskBlock)task {
	DSReceptionist* receptionist = [[DSScalarReceptionist alloc] initWithKeyPath:path
																		  object:obj
																		 options:0
																   dispatchQueue:NULL
																  operationQueue:queue
																			task:task];
	return receptionist;
}
+ (id)receptionistForKeyPath:(NSString *)path object:(id)obj queue:(dispatch_queue_t)queue task:(ReceptionistTaskBlock)task {
	DSReceptionist* receptionist = [[DSScalarReceptionist alloc] initWithKeyPath:path
																		  object:obj
																		 options:0
																   dispatchQueue:queue
																  operationQueue:nil
																			task:task];
	return receptionist;
}
+ (id)receptionistForKeyPath:(NSString *)path
					  object:(id)obj
					 options:(NSKeyValueObservingOptions)options
			  operationQueue:(NSOperationQueue *)queue
						task:(void (^)(NSDictionary* change))task {
	DSReceptionist* receptionist = [[DSScalarReceptionist alloc] initWithKeyPath:path
																		  object:obj
																		 options:options
																   dispatchQueue:NULL
																  operationQueue:queue
																			task:task];
	return receptionist;
}
+ (id)receptionistForKeyPath:(NSString *)path
					  object:(id)obj
					 options:(NSKeyValueObservingOptions)options
					   queue:(dispatch_queue_t)queue
						task:(void (^)(NSDictionary* change))task {
	DSReceptionist* receptionist = [[DSScalarReceptionist alloc] initWithKeyPath:path
																		  object:obj
																		 options:options
																   dispatchQueue:queue
																  operationQueue:nil
																			task:task];
	return receptionist;
}

+ (id)receptionistForArrayKeyPath:(NSString*)arrayPath
				   elementKeyPath:(NSString*)elementPath
						   object:(id)obj
				   operationQueue:(NSOperationQueue*)queue
							 task:(void (^)(NSDictionary* change))task {
	DSReceptionist* receptionist = [[DSArrayReceptionist alloc] initWithArrayKeyPath:arrayPath
																	  elementKeyPath:elementPath
																			  object:obj
																			 options:0
																	   dispatchQueue:NULL
																	  operationQueue:queue
																				task:task];
	return receptionist;
}
+ (id)receptionistForArrayKeyPath:(NSString*)arrayPath
				   elementKeyPath:(NSString*)elementPath
						   object:(id)obj
							queue:(dispatch_queue_t)queue
							 task:(void (^)(NSDictionary* change))task {
	DSReceptionist* receptionist = [[DSArrayReceptionist alloc] initWithArrayKeyPath:arrayPath
																	  elementKeyPath:elementPath
																			  object:obj
																			 options:0
																	   dispatchQueue:queue
																	  operationQueue:nil
																				task:task];
	return receptionist;
}
+ (id)receptionistForArrayKeyPath:(NSString*)arrayPath
				   elementKeyPath:(NSString*)elementPath
						   object:(id)obj
						  options:(NSKeyValueObservingOptions)options
				   operationQueue:(NSOperationQueue*)queue
							 task:(void (^)(NSDictionary* change))task {
	DSReceptionist* receptionist = [[DSArrayReceptionist alloc] initWithArrayKeyPath:arrayPath
																	  elementKeyPath:elementPath
																			  object:obj
																			 options:options
																	   dispatchQueue:NULL
																	  operationQueue:queue
																				task:task];
	return receptionist;
}
+ (id)receptionistForArrayKeyPath:(NSString*)arrayPath
				   elementKeyPath:(NSString*)elementPath
						   object:(id)obj
						  options:(NSKeyValueObservingOptions)options
							queue:(dispatch_queue_t)queue
							 task:(void (^)(NSDictionary* change))task {
	DSReceptionist* receptionist = [[DSArrayReceptionist alloc] initWithArrayKeyPath:arrayPath
																	  elementKeyPath:elementPath
																			  object:obj
																			 options:options
																	   dispatchQueue:queue
																	  operationQueue:nil
																				task:task];
	return receptionist;
}

+ (id)receptionistMakingKey:(NSString*)dependentKey
	dependentOnArrayKeyPath:(NSString*)arrayPath
			 elementKeyPath:(NSString*)elementPath
					 object:(id)obj {
	return [DSReceptionist receptionistForArrayKeyPath:arrayPath
										elementKeyPath:elementPath
												object:obj
											   options:NSKeyValueObservingOptionPrior
												 queue:NULL
												  task:^(NSDictionary *change) {
													  if([[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue])
														  [obj willChangeValueForKey:dependentKey];
													  else
														  [obj didChangeValueForKey:dependentKey];
												  }];
}

- (id)initWithDispatchQueue:(dispatch_queue_t)_dispatchQueue operationQueue:(NSOperationQueue*)_operationQueue task:(ReceptionistTaskBlock)_task {
	if((self = [super init])) {
		NSAssert(![self isMemberOfClass:[DSReceptionist class]], @"Parent DSReceptionist class is abstract, can't be instantiated");
		
		if(_dispatchQueue) {
			dispatchQueue = _dispatchQueue;
			dispatch_retain(dispatchQueue);
		}
		
		operationQueue = _operationQueue;
		
		taskBlock = [_task copy];
	}
	return self;
}

- (void)finalize {
	if(dispatchQueue)
		dispatch_release(dispatchQueue);
	[super finalize];
}

- (void)observedChange:(NSDictionary*)change {
	dispatch_block_t rawBlock = ^{ taskBlock(change); };
	
	if(dispatchQueue)
		dispatch_async(dispatchQueue, rawBlock);
	[operationQueue addOperationWithBlock:rawBlock];
	
	if(!dispatchQueue && !operationQueue)
		rawBlock();
}

- (void)endObservation {
	if(dispatchQueue) {
		dispatch_release(dispatchQueue);
		dispatchQueue = NULL;
	}
}

@end



@implementation DSScalarReceptionist

- (id)initWithKeyPath:(NSString*)path
			   object:(id)obj
			  options:(NSKeyValueObservingOptions)_options
		dispatchQueue:(dispatch_queue_t)_dispatchQueue
	   operationQueue:(NSOperationQueue*)_opQueue
				 task:(ReceptionistTaskBlock)task {
	if((self = [super initWithDispatchQueue:_dispatchQueue operationQueue:_opQueue task:task])) {
		keyPath = [path copy];
		observedObject = obj;
		
		[observedObject addObserver:self forKeyPath:keyPath options:_options context:NULL];
	}
	
	return self;
}

- (void)observeValueForKeyPath:(NSString *)changeKeyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSAssert([changeKeyPath isEqualToString:keyPath], @"Got an observation for a key path we're not observing: %@ (should be %@)", changeKeyPath, keyPath);
	NSAssert(object == observedObject, @"Got an observation for an object we're not observing: %@ (should be %@)", object, observedObject);
	[self observedChange:change];
}

- (void)endObservation {
	[observedObject removeObserver:self forKeyPath:keyPath];
	observedObject = nil; // in case this gets called again...
	[super endObservation];
}

@end


@implementation DSArrayReceptionist

- (id)initWithArrayKeyPath:(NSString*)_arrayPath
			elementKeyPath:(NSString*)_elementPath
					object:(id)_obj
				   options:(NSKeyValueObservingOptions)_options
			 dispatchQueue:(dispatch_queue_t)_dispatchQueue
			operationQueue:(NSOperationQueue*)_opQueue
					  task:(ReceptionistTaskBlock)_task {
	if((self = [super initWithDispatchQueue:_dispatchQueue operationQueue:_opQueue task:_task])) {
		arrayPath = [_arrayPath copy];
		elementPath = [_elementPath copy];
		observedObject = _obj;
		userKVOOptions = _options;
		
		// Watch the array for changes
		[observedObject addObserver:self forKeyPath:arrayPath
							options:(userKVOOptions|NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew)
							context:NULL];
	}
	
	return self;
}

- (NSMutableDictionary*)flattenOldAndNewChangeKeys:(NSDictionary*)change {
	NSMutableDictionary* tweakedChangeDictionary = [change mutableCopy];
	
	NSArray* oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	if(oldValue)
		[tweakedChangeDictionary setObject:[oldValue valueForKeyPath:elementPath] forKey:NSKeyValueChangeOldKey];
	
	NSArray* newValue = [change objectForKey:NSKeyValueChangeNewKey];
	if(newValue)
		[tweakedChangeDictionary setObject:[newValue valueForKeyPath:elementPath] forKey:NSKeyValueChangeNewKey];
	
	return tweakedChangeDictionary;
}

- (void)observeArrayChange:(NSDictionary*)change {
	// First, see if this is a prior notification.
	if([[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue]) {
		// User specified NSKeyValueObservingOptionPrior, and the array is about to change.
		// We're not interested in this ourselves, but we'll pass it along.
		// Any old/new values will be unflattened, but the other keys will be correct.
		
		if(userKVOOptions & NSKeyValueObservingOptionOld) {
			// User is looking at old value, we need to flatten it
			[self observedChange:[self flattenOldAndNewChangeKeys:change]];
		} else {
			// User isn't looking at old value, so we can just pass it on directly
			[self observedChange:change];
		}
		
		return;
	}
	
	// At this point, we know the array already changed.
	
	// Adjust our observations for the changed contents.
	// Stop observing the removed items
	NSArray* oldArray = [change objectForKey:NSKeyValueChangeOldKey];
	if(oldArray)
		[oldArray removeObserver:self fromObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [oldArray count])] forKeyPath:elementPath];
	// Start observing the added items
	NSArray* newArray = [change objectForKey:NSKeyValueChangeNewKey];
	if(newArray)
		[newArray addObserver:self toObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [newArray count])] forKeyPath:elementPath
					  options:userKVOOptions context:NULL];
	
	// Pass the observation on to the user
	if(haveReceivedInitial || (userKVOOptions & NSKeyValueObservingOptionInitial)) {
		if(userKVOOptions & (NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)) {
			// User is looking at old/new value, we need to flatten it
			[self observedChange:[self flattenOldAndNewChangeKeys:change]];
		} else {
			// User isn't looking at old/new value, so we can just pass it on directly
			[self observedChange:change];
		}
	}
	haveReceivedInitial = YES;
}

- (void)observeElementChange:(NSDictionary*)change object:(id)object {
	// First, see if this is a prior notification
	if([[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue]) {
		NSAssert(userKVOOptions & NSKeyValueObservingOptionPrior, @"We're getting a prior notification even though the user didn't want it.");
		
		if(userKVOOptions & NSKeyValueObservingOptionOld) {
			// We need to patch the changes dict before sending it on.
			// Wrap the changed value in an array.
			NSMutableDictionary* newChange = [change mutableCopy];
			[newChange setObject:[NSArray arrayWithObject:[change objectForKey:NSKeyValueChangeOldKey]] forKey:NSKeyValueChangeOldKey];
			[self observedChange:newChange];
		} else {
			// They're not looking at the old value; just pass change on direct
			[self observedChange:change];
		}
		
		return;
	}
	
	// Once we get here, we know the array is already changed.
	NSMutableDictionary* newChange = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:NSKeyValueChangeReplacement] forKey:NSKeyValueChangeKindKey];
	if(userKVOOptions & NSKeyValueObservingOptionOld) {
		[newChange setObject:[NSArray arrayWithObject:[change objectForKey:NSKeyValueChangeOldKey]] forKey:NSKeyValueChangeOldKey];
	}
	if(userKVOOptions & NSKeyValueObservingOptionNew) {
		[newChange setObject:[NSArray arrayWithObject:[change objectForKey:NSKeyValueChangeNewKey]] forKey:NSKeyValueChangeNewKey];
	}
	
	[self observedChange:newChange];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if((object == observedObject) && [keyPath isEqualToString:arrayPath])
		[self observeArrayChange:change];
	else
		[self observeElementChange:change object:object];
}

- (void)endObservation {
	NSArray* observedArray = [observedObject valueForKeyPath:arrayPath];
	[observedArray removeObserver:self fromObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [observedArray count])] forKeyPath:elementPath];
	
	[observedObject removeObserver:self forKeyPath:arrayPath];
	observedObject = nil; // in case this gets called again...
	
	[super endObservation];
}

@end


@implementation NSObject (DSReceptionistAdditions)
- (void)dsMakeKey:(NSString*)dependentKey dependentOnArrayKeyPath:(NSString*)arrayPath elementKeyPath:(NSString*)elementPath {
	DSReceptionist* receptionist = [DSReceptionist receptionistMakingKey:dependentKey
												 dependentOnArrayKeyPath:arrayPath
														  elementKeyPath:elementPath
																  object:self];
	
	// We want the receptionist to just stick around as long as we do
	objc_setAssociatedObject(self, &receptionist, receptionist, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

