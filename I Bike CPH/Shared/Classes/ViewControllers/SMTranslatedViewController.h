//
//  SMTranslatedViewController.h
//  iBike
//
//  Created by Ivan Pavlovic on 25/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "GAITrackedViewController.h"
#import "SMAppDelegate.h"

/**
 * Base class for all the view controller
 *
 * Handles translation by calling [SMTranslation translateView:self.view] in viewDidLoad()
 */
@interface SMTranslatedViewController : UIViewController

@property (nonatomic, weak) SMAppDelegate * appDelegate;

@end
