//
//  ViewController.m
//  CompanyScouter
//
//  Created by shuichi on 9/7/13.
//  Copyright (c) 2013 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
#import "CrunchBaseClient.h"
#import <CoreLocation/CoreLocation.h>


@interface ViewController ()
<CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [CrunchBaseClient requestCompanyWithName:@"AppSocially"
//                                     handler:
//     ^(NSDictionary *result, NSError *error) {
//         
//         if (error) {
//             
//             NSLog(@"error:%@", error);
//         }
//         else {
//             
//             NSLog(@"result:%@", result);
//         }
//     }];
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    if ([CLLocationManager locationServicesEnabled]) {
        
        self.locationManager.delegate = self;
        [self.locationManager startUpdatingLocation];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// =============================================================================
#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"location:%@", newLocation);
    
    [self.locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    NSLog(@"Update failed with error:%@", error);
}

@end
