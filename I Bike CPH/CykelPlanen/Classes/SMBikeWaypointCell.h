//
//  SMBikeWaypointCell.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Table view cell for bike waypoint. Has top/bottom address labels, address image view, distance label, distance image view.
 */
@interface SMBikeWaypointCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelAddressTop;
@property (weak, nonatomic) IBOutlet UILabel *labelAddressBottom;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewAddress;
@property (weak, nonatomic) IBOutlet UILabel *labelDistance;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewDistance;
@property (weak, nonatomic) IBOutlet UIView *viewAddress;
@property (weak, nonatomic) IBOutlet UIView *viewDistance;

-(void)setupWithString:(NSString*)str;
@end
