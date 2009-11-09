//  DSReceptionistTests.m
//  Copyright (c) 2009 Decimus Software, Inc. All rights reserved.
//
//  The latest version of this source may be found at:
//     http://github.com/bdrister/DSReceptionist
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


#import "DSReceptionistTests.h"

#import "DSReceptionist.h"


@interface ReceptionistTestsObservedObject : NSObject
{
	int myValue;
	NSMutableArray* toManyRelationship;
}
@property (readwrite, nonatomic) int myValue;
@property (readonly, nonatomic) int myDependentValue;

- (NSArray *)toManyRelationship;
- (void)setToManyRelationship:(NSArray*)newArray;
- (unsigned)countOfToManyRelationship;
- (id)objectInToManyRelationshipAtIndex:(unsigned)theIndex;
- (void)insertObject:(id)obj inToManyRelationshipAtIndex:(unsigned)theIndex;
- (void)removeObjectFromToManyRelationshipAtIndex:(unsigned)theIndex;
- (void)replaceObjectInToManyRelationshipAtIndex:(unsigned)theIndex withObject:(id)obj;

@end

@implementation ReceptionistTestsObservedObject
@synthesize myValue;

- (id)init {
	if((self = [super init])) {
		toManyRelationship = [[NSMutableArray alloc] init];
		[self dsMakeKey:@"myDependentValue" dependentOnArrayKeyPath:@"toManyRelationship" elementKeyPath:@"myValue"];
	}
	return self;
}

- (NSArray *)toManyRelationship {
    return [NSArray arrayWithArray:toManyRelationship];
}

- (void)setToManyRelationship:(NSArray*)newArray {
	[toManyRelationship setArray:newArray];
}

- (unsigned)countOfToManyRelationship {
    return [toManyRelationship count];
}

- (id)objectInToManyRelationshipAtIndex:(unsigned)theIndex {
    return [toManyRelationship objectAtIndex:theIndex];
}

- (void)insertObject:(id)obj inToManyRelationshipAtIndex:(unsigned)theIndex {
    [toManyRelationship insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromToManyRelationshipAtIndex:(unsigned)theIndex {
    [toManyRelationship removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInToManyRelationshipAtIndex:(unsigned)theIndex withObject:(id)obj {
    [toManyRelationship replaceObjectAtIndex:theIndex withObject:obj];
}

+ (NSSet*)keyPathsForValuesAffectingMyDependentValue {
	return [NSSet setWithObject:@"myValue"]; // also toManyRelationship.myValue, but that's handled by the receptionist
}

- (int)myDependentValue {
	return myValue + [[toManyRelationship valueForKeyPath:@"@sum.myValue"] intValue];
}

@end



@implementation ReceptionistTests

- (void)setUp {
	[super setUp];
	
	queue = dispatch_queue_create("net.decimus.unit-tests.receptionist-tests-queue", NULL);
}

- (void)tearDown {
	[receptionist endObservation]; receptionist = nil;
	dispatch_release(queue);
	[super tearDown];
}

- (void)testBasicFunctionality {
	ReceptionistTestsObservedObject* observed = [[ReceptionistTestsObservedObject alloc] init];
	observed.myValue = 0;
	
	__block int observedOld = -1;
	__block int observedNew = -1;
	receptionist = [DSReceptionist receptionistForKeyPath:@"myValue"
												   object:observed
												  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
													queue:queue
													 task:^(NSDictionary *change) {
														 observedOld = [[change objectForKey:NSKeyValueChangeOldKey] intValue];
														 observedNew = [[change objectForKey:NSKeyValueChangeNewKey] intValue];
													 }];
	
	// Make some changes
	observed.myValue = 1;
	// Make sure the queue's empty
	dispatch_sync(queue, ^{ });
	// Make sure the values were right
	STAssertEquals(observedOld, 0, @"Observed old wasn't 0, was %d", observedOld);
	STAssertEquals(observedNew, 1, @"Observed new wasn't 1, was %d", observedNew);
	
	// Make some changes
	observed.myValue = 2;
	// Make sure the queue's empty
	dispatch_sync(queue, ^{ });
	// Make sure the values were right
	STAssertEquals(observedOld, 1, @"Observed old wasn't 1, was %d", observedOld);
	STAssertEquals(observedNew, 2, @"Observed new wasn't 2, was %d", observedNew);
	
	[receptionist endObservation];
	
	// Make some changes
	observed.myValue = 3;
	// Make sure the queue's empty
	dispatch_sync(queue, ^{ });
	// Make sure the values are UNCHANGED, because we're not observing anymore
	STAssertEquals(observedOld, 1, @"Observed old wasn't 1, was %d", observedOld);
	STAssertEquals(observedNew, 2, @"Observed new wasn't 2, was %d", observedNew);
}

- (void)testArrayFunctionality {
	ReceptionistTestsObservedObject* observedArrayHolder = [[ReceptionistTestsObservedObject alloc] init];
	ReceptionistTestsObservedObject* observedChild1 = [[ReceptionistTestsObservedObject alloc] init]; observedChild1.myValue = 1;
	ReceptionistTestsObservedObject* observedChild2 = [[ReceptionistTestsObservedObject alloc] init]; observedChild2.myValue = 2;
	ReceptionistTestsObservedObject* observedChild3 = [[ReceptionistTestsObservedObject alloc] init]; observedChild3.myValue = 3;
	
	__block NSDictionary* changeDict = nil;
	receptionist = [DSReceptionist receptionistForArrayKeyPath:@"toManyRelationship"
												elementKeyPath:@"myValue"
														object:observedArrayHolder
													   options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
														 queue:queue
														  task:^(NSDictionary *change) {
															  changeDict = change;
														  }];
	
	// Okay, we're all set up. Here we go.
	
	// Relationship is empty, thus toManyRelationship.myValue is [ ].
	// Add something to the array.
	[observedArrayHolder insertObject:observedChild1 inToManyRelationshipAtIndex:0];
	// Make sure the queue's empty
	dispatch_sync(queue, ^{ });
	// Make sure the change is right
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeKindKey] isEqualToNumber:[NSNumber numberWithUnsignedInt:NSKeyValueChangeInsertion]],
				 @"Change kind wasn't insertion, was %@", [changeDict objectForKey:NSKeyValueChangeKindKey]);
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeIndexesKey] isEqualToIndexSet:[NSIndexSet indexSetWithIndex:0]],
				 @"Change indexes wasn't {0}, was %@", [changeDict objectForKey:NSKeyValueChangeIndexesKey]);
	STAssertTrue(![changeDict objectForKey:NSKeyValueChangeOldKey] ||
				 [[changeDict objectForKey:NSKeyValueChangeOldKey] isEqualToArray:[NSArray array]],
				 @"Old array wasn't [ ], was %@", [changeDict objectForKey:NSKeyValueChangeOldKey]);
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeNewKey] isEqualToArray:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:1]]],
				 @"New array wasn't [1], was %@", [changeDict objectForKey:NSKeyValueChangeNewKey]);
	
	// Change the child's value => [42]
	observedChild1.myValue = 42;
	// Make sure the queue's empty
	dispatch_sync(queue, ^{ });
	// Make sure the change is right
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeKindKey] isEqualToNumber:[NSNumber numberWithUnsignedInt:NSKeyValueChangeReplacement]],
				 @"Change kind wasn't replacement, was %@", [changeDict objectForKey:NSKeyValueChangeKindKey]);
	// We don't support indexes on element value changes at this point. Can change if we need to later, but that's expensive to do.
//	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeIndexesKey] isEqualToIndexSet:[NSIndexSet indexSetWithIndex:0]],
//				 @"Change indexes wasn't {0}, was %@", [changeDict objectForKey:NSKeyValueChangeIndexesKey]);
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeOldKey] isEqualToArray:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:1]]],
				 @"Old array wasn't [1], was %@", [changeDict objectForKey:NSKeyValueChangeOldKey]);
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeNewKey] isEqualToArray:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:42]]],
				 @"New array wasn't [42], was %@", [changeDict objectForKey:NSKeyValueChangeNewKey]);
	
	
	// Remove the child => [ ]
	[observedArrayHolder removeObjectFromToManyRelationshipAtIndex:0];
	// Make sure the queue's empty
	dispatch_sync(queue, ^{ });
	// Make sure the change is right
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeKindKey] isEqualToNumber:[NSNumber numberWithUnsignedInt:NSKeyValueChangeRemoval]],
				 @"Change kind wasn't removal, was %@", [changeDict objectForKey:NSKeyValueChangeKindKey]);
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeIndexesKey] isEqualToIndexSet:[NSIndexSet indexSetWithIndex:0]],
				 @"Change indexes wasn't {0}, was %@", [changeDict objectForKey:NSKeyValueChangeIndexesKey]);
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeOldKey] isEqualToArray:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:42]]],
				 @"Old array wasn't [42], was %@", [changeDict objectForKey:NSKeyValueChangeOldKey]);
	STAssertTrue(![changeDict objectForKey:NSKeyValueChangeNewKey] ||
				 [[changeDict objectForKey:NSKeyValueChangeNewKey] isEqualToArray:[NSArray array]],
				 @"New array wasn't [ ], was %@", [changeDict objectForKey:NSKeyValueChangeNewKey]);
	
	// Change the child's value
	observedChild1.myValue = 86;
	// Make sure the queue's empty
	dispatch_sync(queue, ^{ });
	// Make sure there is NO CHANGE to the change dictionary, as we shouldn't be observing the child any more
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeKindKey] isEqualToNumber:[NSNumber numberWithUnsignedInt:NSKeyValueChangeRemoval]],
				 @"Change kind wasn't removal, was %@", [changeDict objectForKey:NSKeyValueChangeKindKey]);
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeIndexesKey] isEqualToIndexSet:[NSIndexSet indexSetWithIndex:0]],
				 @"Change indexes wasn't {0}, was %@", [changeDict objectForKey:NSKeyValueChangeIndexesKey]);
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeOldKey] isEqualToArray:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:42]]],
				 @"Old array wasn't [42], was %@", [changeDict objectForKey:NSKeyValueChangeOldKey]);
	STAssertTrue(![changeDict objectForKey:NSKeyValueChangeNewKey] ||
				 [[changeDict objectForKey:NSKeyValueChangeNewKey] isEqualToArray:[NSArray array]],
				 @"New array wasn't [ ], was %@", [changeDict objectForKey:NSKeyValueChangeNewKey]);
	
	// Set the array wholesale => [2,3]
	observedArrayHolder.toManyRelationship = [NSArray arrayWithObjects:observedChild2, observedChild3, nil];
	// Make sure the queue's empty
	dispatch_sync(queue, ^{ });
	// Make sure the change is right
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeKindKey] isEqualToNumber:[NSNumber numberWithUnsignedInt:NSKeyValueChangeSetting]],
				 @"Change kind wasn't setting, was %@", [changeDict objectForKey:NSKeyValueChangeKindKey]);
	STAssertTrue(![changeDict objectForKey:NSKeyValueChangeOldKey] ||
				 [[changeDict objectForKey:NSKeyValueChangeOldKey] isEqualToArray:[NSArray array]],
				 @"Old array wasn't [ ], was %@", [changeDict objectForKey:NSKeyValueChangeOldKey]);
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeNewKey] isEqualToArray:([NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:2], [NSNumber numberWithUnsignedInt:3], nil])],
				 @"New array wasn't [2,3], was %@", [changeDict objectForKey:NSKeyValueChangeNewKey]);
	
	// Append an object to the array => [2,3,86]
	[observedArrayHolder insertObject:observedChild1 inToManyRelationshipAtIndex:2];
	// Make sure the queue's empty
	dispatch_sync(queue, ^{ });
	// Make sure the change is right
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeKindKey] isEqualToNumber:[NSNumber numberWithUnsignedInt:NSKeyValueChangeInsertion]],
				 @"Change kind wasn't insertion, was %@", [changeDict objectForKey:NSKeyValueChangeKindKey]);
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeIndexesKey] isEqualToIndexSet:[NSIndexSet indexSetWithIndex:2]],
				 @"Change indexes wasn't {2}, was %@", [changeDict objectForKey:NSKeyValueChangeIndexesKey]);
	STAssertTrue(![changeDict objectForKey:NSKeyValueChangeOldKey] ||
				 [[changeDict objectForKey:NSKeyValueChangeOldKey] isEqualToArray:[NSArray array]],
				 @"Old array wasn't [ ], was %@", [changeDict objectForKey:NSKeyValueChangeOldKey]);
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeNewKey] isEqualToArray:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:86]]],
				 @"New array wasn't [1], was %@", [changeDict objectForKey:NSKeyValueChangeNewKey]);
	
	// Remove an object from the array => [2,86]
	[observedArrayHolder removeObjectFromToManyRelationshipAtIndex:1];
	// Make sure the queue's empty
	dispatch_sync(queue, ^{ });
	// Make sure the change is right
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeKindKey] isEqualToNumber:[NSNumber numberWithUnsignedInt:NSKeyValueChangeRemoval]],
				 @"Change kind wasn't removal, was %@", [changeDict objectForKey:NSKeyValueChangeKindKey]);
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeIndexesKey] isEqualToIndexSet:[NSIndexSet indexSetWithIndex:1]],
				 @"Change indexes wasn't {1}, was %@", [changeDict objectForKey:NSKeyValueChangeIndexesKey]);
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeOldKey] isEqualToArray:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:3]]],
				 @"Old array wasn't [3], was %@", [changeDict objectForKey:NSKeyValueChangeOldKey]);
	STAssertTrue(![changeDict objectForKey:NSKeyValueChangeNewKey] ||
				 [[changeDict objectForKey:NSKeyValueChangeNewKey] isEqualToArray:[NSArray array]],
				 @"New array wasn't [ ], was %@", [changeDict objectForKey:NSKeyValueChangeNewKey]);
	
	// Change the child's value => [2,42]
	observedChild1.myValue = 42;
	// Make sure the queue's empty
	dispatch_sync(queue, ^{ });
	// Make sure the change is right
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeKindKey] isEqualToNumber:[NSNumber numberWithUnsignedInt:NSKeyValueChangeReplacement]],
				 @"Change kind wasn't replacement, was %@", [changeDict objectForKey:NSKeyValueChangeKindKey]);
	// We don't support indexes on element value changes at this point. Can change if we need to later, but that's expensive to do.
	//	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeIndexesKey] isEqualToIndexSet:[NSIndexSet indexSetWithIndex:0]],
	//				 @"Change indexes wasn't {0}, was %@", [changeDict objectForKey:NSKeyValueChangeIndexesKey]);
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeOldKey] isEqualToArray:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:86]]],
				 @"Old array wasn't [86], was %@", [changeDict objectForKey:NSKeyValueChangeOldKey]);
	STAssertTrue([[changeDict objectForKey:NSKeyValueChangeNewKey] isEqualToArray:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:42]]],
				 @"New array wasn't [42], was %@", [changeDict objectForKey:NSKeyValueChangeNewKey]);
}

- (void)testDependentValue {
	ReceptionistTestsObservedObject* observedArrayHolder = [[ReceptionistTestsObservedObject alloc] init]; observedArrayHolder.myValue = 42;
	ReceptionistTestsObservedObject* observedChild1 = [[ReceptionistTestsObservedObject alloc] init]; observedChild1.myValue = 1;
	
	__block int observedOld = -1;
	__block int observedNew = -1;
	receptionist = [DSReceptionist receptionistForKeyPath:@"myDependentValue"
												   object:observedArrayHolder
												  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
													queue:queue
													 task:^(NSDictionary *change) {
														 observedOld = [[change objectForKey:NSKeyValueChangeOldKey] intValue];
														 observedNew = [[change objectForKey:NSKeyValueChangeNewKey] intValue];
													 }];
	
	STAssertEquals(observedArrayHolder.myDependentValue, 42, @"Dependent value had wrong initial value.");
	
	// Make some changes
	observedArrayHolder.myValue = 45;
	// Make sure the queue's empty
	dispatch_sync(queue, ^{ });
	// Make sure the values were right
	STAssertEquals(observedArrayHolder.myDependentValue, 45, @"Dependent value had wrong value.");
	STAssertEquals(observedOld, 42, @"Observed old wasn't 42, was %d", observedOld);
	STAssertEquals(observedNew, 45, @"Observed new wasn't 45, was %d", observedNew);
	
	// Make some changes
	[observedArrayHolder insertObject:observedChild1 inToManyRelationshipAtIndex:0];
	// Make sure the queue's empty
	dispatch_sync(queue, ^{ });
	// Make sure the values were right
	STAssertEquals(observedArrayHolder.myDependentValue, 46, @"Dependent value had wrong value.");
	STAssertEquals(observedOld, 45, @"Observed old wasn't 0, was %d", observedOld);
	STAssertEquals(observedNew, 46, @"Observed new wasn't 1, was %d", observedNew);
	
	// Make some changes
	observedChild1.myValue = -3;
	// Make sure the queue's empty
	dispatch_sync(queue, ^{ });
	// Make sure the values were right
	STAssertEquals(observedArrayHolder.myDependentValue, 42, @"Dependent value had wrong value.");
	STAssertEquals(observedOld, 46, @"Observed old wasn't 0, was %d", observedOld);
	STAssertEquals(observedNew, 42, @"Observed new wasn't 1, was %d", observedNew);
}

@end
