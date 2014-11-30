//
//  SMSearchHistory.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 10/05/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMAPIRequest.h"
#import "SharedImport.h"

@protocol SMSearchHistoryDelegate <NSObject>
- (void)searchHistoryOperationFinishedSuccessfully:(id)req withData:(id)data;
@end

/**
 * Handler that fetches/saves history
 */
@interface SMSearchHistory : NSObject <SMAPIRequestDelegate>

@property (nonatomic, weak) id<SMSearchHistoryDelegate>delegate;

+ (SMSearchHistory *)instance;
+ (NSArray*)getSearchHistory;
+ (BOOL)saveToSearchHistory:(HistoryItem *)item;
+ (BOOL) saveSearchHistory;

- (void)fetchSearchHistoryFromServer;
- (void)addSearchToServer:(NSObject<SearchListItem> *)srchData;

- (void)addFinishedRouteToServer:(NSDictionary*)srchData;

@end
