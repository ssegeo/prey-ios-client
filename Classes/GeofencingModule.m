//
//  GoefencingModule.m
//  Prey
//
//  Created by Carlos Yaconi on 06-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "GeofencingModule.h"
#import "PreyGeofencingController.h"

@implementation GeofencingModule

- (void)main {
    NSString *action = [self.options objectForKey:@"action"];
    NSString *region_id = [self.options objectForKey:@"region_id"];
    CLLocationDegrees center_lat = [[self.options objectForKey:@"center_lat"] doubleValue];
    CLLocationDegrees center_lon = [[self.options objectForKey:@"center_lon"] doubleValue];
    CLLocationDistance radius = [[self.options objectForKey:@"radius"] doubleValue];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(center_lat, center_lon);
    
    CLRegion *region = [[CLRegion alloc] initCircularRegionWithCenter:center radius:radius identifier:region_id];
    
    SEL s = NSSelectorFromString(action);
    [self performSelector:s withObject:region];
}

- (void)start: (CLRegion *)region {
    [[PreyGeofencingController instance] addNewregion:region];
}

- (void)stop: (CLRegion *)region {
    [[PreyGeofencingController instance] removeRegion:region.identifier];
}

- (NSString *) getName {
	return @"geofencing";
}


- (NSMutableDictionary *) reportData {
    return nil;
}

- (void)dealloc {
	[super dealloc];
}

@end
