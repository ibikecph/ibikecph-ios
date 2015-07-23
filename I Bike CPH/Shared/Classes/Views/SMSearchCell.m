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
    switch (type) {
        case FavoriteItemTypeHome:
            imageName = @"favoriteHome";
        break;
        case FavoriteItemTypeWork:
            imageName = @"favoriteWork";
            break;
        case FavoriteItemTypeSchool:
            imageName = @"favoriteSchool";
            break;
        case FavoriteItemTypeUnknown:
            imageName = @"Favorite";
            break;
    }
    self.iconImage.image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
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
    self.iconImage.image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    [self updateIconImageToHighlighted:highlighted];
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    [self updateIconImageToHighlighted:selected];
}

- (void)updateIconImageToHighlighted:(BOOL)highlighted {
    self.iconImage.tintColor = highlighted ? [Styler backgroundColor] : [Styler foregroundColor];
}

@end
