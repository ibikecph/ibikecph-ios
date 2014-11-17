//
//  SMRouteTypeSelectCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 06/06/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Table view cell for route type. Used in SMRouteNavigationController. FIXME: Merge.
 */
@interface SMRouteTypeSelectCell : UITableViewCell {
    
    __weak IBOutlet UIImageView *cellImage;
    __weak IBOutlet UILabel *cellText;
}
@property (weak, nonatomic) IBOutlet UIImageView *cellCheckbox;

+ (CGFloat)getHeight;
- (void)setupCellWithData:(NSDictionary*)data;

@end
