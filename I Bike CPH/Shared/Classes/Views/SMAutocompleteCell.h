//
//  SMAutocompleteCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 30/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

/**
 * Table view cell for autocomplete table view. Has name label + adress label + descriptive image
 */
@interface SMAutocompleteCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet AsyncImageView *iconImage;

+ (CGFloat)getHeight;

@end
