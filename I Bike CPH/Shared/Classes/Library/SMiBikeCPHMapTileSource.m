//
//  SMiBikeMapTileSource.m
//  I Bike CPH
//
//  Created by Petra Markovic on 2/13/13.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import "SMiBikeCPHMapTileSource.h"

@implementation SMiBikeCPHMapTileSource

- (id)init
{
	if (!(self = [super init]))
        return nil;

    self.minZoom = 9;
    self.maxZoom = 17;

	return self;
}

- (NSURL *)URLForTile:(RMTile)tile
{
	NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
			  @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f",
			  self, tile.zoom, self.minZoom, self.maxZoom);

//    // debug
//    NSLog(@"%@", [NSString stringWithFormat:@"http://tiles.ibikecph.dk/tiles/%d/%d/%d.png", tile.zoom, tile.x, tile.y]);
	return [NSURL URLWithString:[NSString stringWithFormat:@"http://tiles.ibikecph.dk/tiles/%d/%d/%d.png", tile.zoom, tile.x, tile.y]];
}

- (NSString *)uniqueTilecacheKey
{
    // TODO
//	return @"OpenStreetMap";
  	return @"I Bike CPH";
}

- (NSString *)shortName
{
    // TODO
//	return @"Open Street Map";
    return @"I Bike CPH";
}

- (NSString *)longDescription
{
    // TODO
//	return @"Open Street Map, the free wiki world map, provides freely usable map data for all parts of the world, under the Creative Commons Attribution-Share Alike 2.0 license.";
	return @"I Bike CPH";
}

- (NSString *)shortAttribution
{
    // TODO
//	return @"© OpenStreetMap CC-BY-SA";
    return @"I Bike CPH";
}

- (NSString *)longAttribution
{
    // TODO
//	return @"Map data © OpenStreetMap, licensed under Creative Commons Share Alike By Attribution.";
    return @"I Bike CPH";
}

@end
