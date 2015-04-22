//
//  SMContactsCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 25/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

/**
 * Table view cell for contact. Has image, name label, disclosure image. FIXME: Probably not used in app :/
 */
@interface SMContactsCell : UITableViewCell {
    
    __weak IBOutlet UIImageView *cellBG;
}
@property (weak, nonatomic) IBOutlet UIImageView *contactImage;
@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UIImageView *contactDisclosure;

+ (CGFloat)getHeight;

@end
