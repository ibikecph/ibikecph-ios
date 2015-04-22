//
//  SMAutocompleteHeader.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 14/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
/**
 * Table view cell that acts as header for autocomplete table view
 */
@interface SMAutocompleteHeader : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *headerTitle;
+ (CGFloat)getHeight;

@end
