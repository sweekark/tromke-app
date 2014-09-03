//
//  APAddressBook.m
//  APAddressBook
//
//  Created by Alexey Belkevich on 1/10/14.
//  Copyright (c) 2014 alterplay. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "APAddressBook.h"
#import "APContact.h"
#import "APPhoneWithLabel.h"

void APAddressBookExternalChangeCallback(ABAddressBookRef addressBookRef, CFDictionaryRef info,
                                         void *context);

@interface APAddressBook ()
@property (nonatomic, readonly) ABAddressBookRef addressBook;
@property (nonatomic, readonly) dispatch_queue_t localQueue;
@property (nonatomic, copy) void (^changeCallback)();
@end

@implementation APAddressBook

#pragma mark - life cycle

- (id)init
{
    self = [super init];
    if (self)
    {
        CFErrorRef *error = NULL;
        _addressBook = ABAddressBookCreateWithOptions(NULL, error);
        if (error)
        {
            NSLog(@"%@", (__bridge_transfer NSString *)CFErrorCopyFailureReason(*error));
            return nil;
        }
        NSString *name = [NSString stringWithFormat:@"com.alterplay.addressbook.%ld",
                                   (long)self.hash];
        _localQueue = dispatch_queue_create([name cStringUsingEncoding:NSUTF8StringEncoding], NULL);
        self.fieldsMask = APContactFieldDefault;
    }
    return self;
}

- (void)dealloc
{
    [self stopObserveChanges];
    if (_addressBook)
    {
        CFRelease(_addressBook);
    }
#if !OS_OBJECT_USE_OBJC
    dispatch_release(_localQueue);
#endif
}

#pragma mark - public

+ (APAddressBookAccess)access
{
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    switch (status)
    {
        case kABAuthorizationStatusDenied:
        case kABAuthorizationStatusRestricted:
            return APAddressBookAccessDenied;

        case kABAuthorizationStatusAuthorized:
            return APAddressBookAccessGranted;

        default:
            return APAddressBookAccessUnknown;
    }
}

- (void)getContactsForSync:(void (^)(NSArray *contactsDict, NSError *error))callbackBlock {
    [self loadContactsOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0) completion:^(NSArray *contacts, NSError *error) {
        if (!error) {
            NSMutableArray* tempArray = [NSMutableArray array];
            for (APContact* contact in contacts) {
                [tempArray addObject:[contact dictionary]];
            }
            callbackBlock(tempArray, nil);
        } else {
            callbackBlock(nil, error);
        }
    }];
    
//    [self loadContacts:^(NSArray *contacts, NSError *error) {
//        if (!error) {
//            NSMutableArray* tempArray = [NSMutableArray array];
//            for (APContact* contact in contacts) {
//                [tempArray addObject:[contact dictionary]];
//            }
//            callbackBlock(tempArray, nil);
//        } else {
//            callbackBlock(nil, error);
//        }
//    }];
}

- (void)loadContacts:(void (^)(NSArray *contacts, NSError *error))callbackBlock {
    [self loadContactsOnQueue:dispatch_get_main_queue() completion:callbackBlock];
}

- (void)loadContactsOnQueue:(dispatch_queue_t)queue
                 completion:(void (^)(NSArray *contacts, NSError *error))completionBlock
{
    APContactField fieldMask = self.fieldsMask;
    NSArray *descriptors = self.sortDescriptors;
    APContactFilterBlock filterBlock = self.filterBlock;

	ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef errorRef)
	{
	    dispatch_async(self.localQueue, ^
        {
	        NSArray *array = nil;
	        NSError *error = nil;
            if (granted)
            {
                CFArrayRef peopleArrayRef = ABAddressBookCopyArrayOfAllPeople(self.addressBook);
                NSUInteger contactCount = (NSUInteger)CFArrayGetCount(peopleArrayRef);
                NSMutableArray *contacts = [[NSMutableArray alloc] init];
                for (NSUInteger i = 0; i < contactCount; i++)
                {
                    ABRecordRef recordRef = CFArrayGetValueAtIndex(peopleArrayRef, i);
                    APContact *contact = [[APContact alloc] initWithRecordRef:recordRef fieldMask:fieldMask];
                    if (!filterBlock || filterBlock(contact))
                    {
                        for (APPhoneWithLabel* phone in contact.phonesWithLabels) {
                            [contacts addObject:@{@"Name":[contact contactName],
                                                  @"Thumbnail" : contact.thumbnail ? contact.thumbnail : [UIImage imageNamed:@"NewPhone"],
                                                  @"IsSelected" : @NO,
                                                  @"Phone" : phone.phone}];
                        }
//                        [contacts addObject:contact];
                    }
                }
                //[contacts sortUsingDescriptors:descriptors];
                NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"Name"  ascending:YES];
                [contacts sortUsingDescriptors:@[descriptor]];
//                contacts = [[contacts sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]] mutableCopy];
                
                
                array = contacts.copy;
                CFRelease(peopleArrayRef);
            }
            else if (errorRef)
            {
                error = (__bridge NSError *)errorRef;
            }

            dispatch_async(queue, ^
            {
                if (completionBlock)
                {
                    completionBlock(array, error);
                }
            });
		});
	});
}

- (void)startObserveChangesWithCallback:(void (^)())callback
{
    if (callback)
    {
        if (!self.changeCallback)
        {
            ABAddressBookRegisterExternalChangeCallback(self.addressBook,
                                                        APAddressBookExternalChangeCallback,
                                                        (__bridge void *)(self));
        }
        self.changeCallback = callback;
    }
}

- (void)stopObserveChanges
{
    if (self.changeCallback)
    {
        self.changeCallback = nil;
        ABAddressBookUnregisterExternalChangeCallback(self.addressBook,
                                                      APAddressBookExternalChangeCallback,
                                                      (__bridge void *)(self));
    }
}

#pragma mark - external change callback

void APAddressBookExternalChangeCallback(ABAddressBookRef __unused addressBookRef,
                                         CFDictionaryRef __unused info,
                                         void *context)
{
    APAddressBook *addressBook = (__bridge APAddressBook *)(context);
    addressBook.changeCallback ? addressBook.changeCallback() : nil;
}

@end
