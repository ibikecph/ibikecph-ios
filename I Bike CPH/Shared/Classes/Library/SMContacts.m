//
//  SMContacts.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 25/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMContacts.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@implementation SMContacts

- (id)initWithDelegate:(id<SMContactsDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

- (void)loadContacts
{
    ABAddressBookRef addressBook;
    CFErrorRef error = nil;
    addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
      // callback can occur in background, address book must be accessed on thread it was created on
      dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            if (self.delegate) {
                [self.delegate addressBookHelperError:self];
            }
        }
        else if (!granted) {
            if (self.delegate) {
                [self.delegate addressBookHelperDeniedAcess:self];
            }
        }
        else {
            // access granted
            AddressBookUpdated(addressBook, nil, self);
            CFRelease(addressBook);
        }
      });
    });
}

void AddressBookUpdated(ABAddressBookRef addressBook, CFDictionaryRef info, SMContacts *helper)
{
    CFArrayRef allPeopleRef = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);

    NSMutableArray *people = [NSMutableArray array];

    for (int i = 0; i < nPeople; i++) {
        ABRecordRef thisPerson = CFArrayGetValueAtIndex(allPeopleRef, i);

        NSString *contactFirstLast = nil;

        CFTypeRef firstName = ABRecordCopyValue(thisPerson, kABPersonFirstNameProperty);
        if (firstName) {
            contactFirstLast = [NSString stringWithFormat:@"%@", firstName];
            CFRelease(firstName);
        }

        CFTypeRef lastName = ABRecordCopyValue(thisPerson, kABPersonLastNameProperty);
        if (lastName) {
            if (contactFirstLast) {
                contactFirstLast = [NSString stringWithFormat:@"%@ %@", contactFirstLast, lastName];
            }
            else {
                contactFirstLast = [NSString stringWithFormat:@"%@", lastName];
            }
            CFRelease(lastName);
        }

        CFTypeRef organization = ABRecordCopyValue(thisPerson, kABPersonOrganizationProperty);
        if (organization) {
            if (contactFirstLast) {
                contactFirstLast = [NSString stringWithFormat:@"%@ %@", contactFirstLast, organization];
            }
            else {
                contactFirstLast = [NSString stringWithFormat:@"%@", organization];
            }
            CFRelease(organization);
        }

        if (contactFirstLast == nil) {
            contactFirstLast = @"";
        }

        NSString *address = nil;

        ABMultiValueRef addressList = ABRecordCopyValue(thisPerson, kABPersonAddressProperty);
        if (addressList) {
            if (ABMultiValueGetCount(addressList) > 0) {
                CFDictionaryRef dict = ABMultiValueCopyValueAtIndex(addressList, 0);
                address = CFDictionaryGetValue(dict, kABPersonAddressStreetKey);
                if (CFDictionaryGetValue(dict, kABPersonAddressCityKey)) {
                    address = [NSString stringWithFormat:@"%@, %@", address, CFDictionaryGetValue(dict, kABPersonAddressCityKey)];
                }
                if (CFDictionaryGetValue(dict, kABPersonAddressCountryKey)) {
                    address = [NSString stringWithFormat:@"%@, %@", address, CFDictionaryGetValue(dict, kABPersonAddressCountryKey)];
                }
                CFRelease(dict);
            }
            CFRelease(addressList);
        }

        if (contactFirstLast && address) {
            NSMutableDictionary *cnt = [@{
                @"name" : contactFirstLast,
                @"source" : @"contacts",
                @"address" : [address stringByReplacingOccurrencesOfString:@"\n" withString:@", "]
            } mutableCopy];

            CFDataRef imageData = ABPersonCopyImageData(thisPerson);
            UIImage *image = [UIImage imageWithData:(__bridge NSData *)imageData];
            CFRelease(imageData);

            if (image) {
                [cnt setValue:image forKey:@"image"];
            }

            [people addObject:cnt];
        }
    }

    CFRelease(allPeopleRef);

    if (helper.delegate) {
        [[helper delegate] addressBookHelper:helper finishedLoading:people];
    }
};

@end
