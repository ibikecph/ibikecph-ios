//
//  SMEnterRouteCell.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 13/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMSearchCell.h"

@implementation SMSearchCell

- (void)setImageWithFavoriteType:(FavoriteItemType)type {
    
    NSString *imageName;
    NSString *imageNameHighlight;
    switch (type) {
        case FavoriteItemTypeHome:
            imageName = @"favHomeGrey";
            imageNameHighlight = @"favHomeWhite";
        break;
        case FavoriteItemTypeWork:
            imageName = @"favWorkGrey";
            imageNameHighlight = @"favWorkWhite";
            break;
        case FavoriteItemTypeSchool:
            imageName = @"favSchoolGrey";
            imageNameHighlight = @"favSchoolWhite";
            break;
        case FavoriteItemTypeUnknown:
            imageName = @"favStarGreySmall";
            imageNameHighlight = @"favStarWhiteSmall";
            break;
    }
    self.iconImage.image = [UIImage imageNamed:imageName];
    self.iconImage.highlightedImage = [UIImage imageNamed:imageNameHighlight];
}

- (void)setImageWithType:(SearchListItemType)type isFromStreetSearch:(BOOL)isFromStreetSearch {
    NSString *imageName;
    switch (type) {
        case SearchListItemTypeFavorite: [self setImageWithFavoriteType:FavoriteItemTypeUnknown]; return;
        case SearchListItemTypeHistory: imageName = @"findHistory"; break;
        case SearchListItemTypeCalendar: imageName = @"findRouteCalendar"; break;
        case SearchListItemTypeContact: imageName = @"findRouteContacts"; break;
        case SearchListItemTypeFoursquare: imageName = @"findLocation"; break;
        case SearchListItemTypeCurrentLocation: imageName = @"findLocation"; break;
        case SearchListItemTypeKortfor: {
            imageName = isFromStreetSearch ? @"findAutocomplete" : @"findLocation";
            break;
        }
        default:
            break;
    }
    self.iconImage.image = [UIImage imageNamed:imageName];
    self.iconImage.highlightedImage = nil;
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    [self.iconImage setHighlighted:highlighted];
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    [self.iconImage setHighlighted:selected];
}

@end
