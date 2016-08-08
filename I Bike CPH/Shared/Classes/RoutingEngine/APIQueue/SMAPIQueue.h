//
//  SMAPIQueue.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 17/11/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

@import Foundation;

@interface SMAPIQueue : NSObject<SMAPIOperationDelegate>

@property(nonatomic, weak) id<SMAPIOperationDelegate> delegate;

@property(nonatomic, strong) NSOperationQueue *queue;

- (void)stopAllRequests;
- (void)cancelTask:(SMAPIOperation *)task;

- (id)initWithMaxOperations:(NSInteger)maxOps;

- (void)addTasks:(NSString *)srchString;

@end