//
//  SMEnterRouteController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 13/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTranslatedViewController.h"
#import "SMRequestOSRM.h"
#import "SMSearchController.h"


/**
 * Route picker delegate methods
 */
@protocol EnterRouteDelegate <NSObject>

- (void)findRouteFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to fromAddress:(NSString*)src toAddress:(NSString*)dst;
- (void)findRouteFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to fromAddress:(NSString*)src toAddress:(NSString*)dst withJSON:(id)jsonRoot;

@end

/**
 * View controller for creating route. Has from and to labels, swap and start button, and arrow image view for current location. FIXME: Merge.
 */
@interface SMEnterRouteController : SMTranslatedViewController <SMRequestOSRMDelegate, UITableViewDataSource, UITableViewDelegate, SMSearchDelegate>

@property (nonatomic, weak) id<EnterRouteDelegate> delegate;

@end
