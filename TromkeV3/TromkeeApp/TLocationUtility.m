//
//  TLocationUtility.m
//  Tromkee
//
//  Created by Satyanarayana SVV on 1/13/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TLocationUtility.h"
#import <CoreLocation/CoreLocation.h>

@interface TLocationUtility () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocationCoordinate2D userLocation;

@end

@implementation TLocationUtility

+(id)sharedInstance {
    static TLocationUtility* locationUtility = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        locationUtility = [[TLocationUtility alloc] init];
    });
    
    return locationUtility;
}

-(id)init {
    self = [super init];
    if (self) {
        [self initiateLocationCapture];
    }
    
    return self;
}

-(void)initiateLocationCapture {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    self.locationManager.distanceFilter = 200; //meters
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation {
    DLog(@"Lat: %f Long: %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    self.userLocation = newLocation.coordinate;
    [[NSNotificationCenter defaultCenter] postNotificationName:TROMKE_USER_LOCATION_UPDATED object:nil];
    
    CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        
        CLPlacemark* placemark = placemarks[0];
        NSMutableString* placeStr = [[NSMutableString alloc] init];
        NSString* placemarkName = placemark.name;
        NSString* placemarkSubLocality = placemark.subLocality;
        NSString* placemarkLocality = placemark.locality;

        if (placemarkName && ![placemarkName isEqual:[NSNull null]]) {
            [placeStr appendString:placemarkName];
        }
        
        if (placemarkSubLocality && ![placemarkSubLocality isEqual:[NSNull null]]) {
            if ([placeStr length]) {
                [placeStr appendString:@", "];
            }
            [placeStr appendString:placemarkSubLocality];
        }
        
        if (placemarkLocality && ![placemarkLocality isEqual:[NSNull null]]) {
            if ([placeStr length]) {
                [placeStr appendString:@", "];
            }
            [placeStr appendString:placemarkLocality];
        }
        
        NSLog(@"%@", placeStr);
        [[NSUserDefaults standardUserDefaults] setValue:placeStr forKeyPath:USER_LOCATION];
        
//        for (CLPlacemark * placemark in placemarks) {
////            NSString* placemarkName = placemark.name;
////            NSString* placemarkSubLocality = placemark.subLocality;
////            NSString* placemarkLocality = placemark.locality;
////            
////            if (placemarkName && ![placemarkName isEqual:[NSNull null]] &&
////                placemarkSubLocality && ![placemarkSubLocality isEqual:[NSNull null]] &&
////                placemarkLocality && ![placemarkLocality isEqual:[NSNull null]]) {
//                [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%@, %@, %@", placemark.name, placemark.subLocality, placemark.locality] forKeyPath:USER_LOCATION];
////            }
//        }
    }];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    NSLog(@"Failed to get location: %@", error);
    [manager stopUpdatingLocation];
//    [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Failed to fetch user's location. You cannot continue using the app" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
}

-(CLLocationCoordinate2D)getUserCoordinate {
    return self.userLocation;
}
@end
