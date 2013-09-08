//
//  ASDashboardClient.m
//  DashboardAPI
//
//  Created by shuichi on 7/13/13.
//  Copyright (c) 2013 Shuichi Tsutsumi. All rights reserved.
//

#import "ASDashboardClient.h"
#import "AFJSONRequestOperation.h"


NSString * const ASAPIResponseClickCount        = @"click_count";
NSString * const ASAPIResponseDate              = @"date";
NSString * const ASAPIResponseInvitationCount   = @"invitation_count";
NSString * const ASAPIResponseInviteeCount      = @"invitee_count";
NSString * const ASAPIResponseKFactor           = @"k_factor";
NSString * const ASAPIResponseUserCount         = @"user_count";

NSString * const ASAPIResponseAppName           = @"name";
NSString * const ASAPIResponseAppIconUrl        = @"icon_url";


#ifndef STAGING
#define API_BASE_URL      @"https://api.appsocial.ly"
#else
#define API_BASE_URL      @"https://staging.appsocial.ly"
#endif

#define USER_AGENT        @"AppSociallyClient-iOS/1.0"


/*
 "click_count" = 12;
 date = "2013-07-13";
 "invitation_count" = 62;
 "invitee_count" = 4;
 "k_factor" = "0.03";
 "user_count" = 533;
 
 */


@interface ASDashboardClient ()
@property (nonatomic) NSString* APIKey;
@end


@implementation ASDashboardClient

+ (ASDashboardClient *)sharedClient
{
    static ASDashboardClient *sharedClient = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[ASDashboardClient alloc] initWithBaseURL:[NSURL URLWithString:API_BASE_URL]];
    });
    
    return sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url
{
    if (self = [super initWithBaseURL:url]) {
        
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setParameterEncoding:AFJSONParameterEncoding];
        
        [self setDefaultHeader:@"Accept"     value:@"application/json"];
        [self setDefaultHeader:@"User-Agent" value:USER_AGENT];
        
#ifdef STAGING
        self.allowsInvalidSSLCertificate = YES;
#endif
    }
    
    return self;
}




// =============================================================================
#pragma mark - Private

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    NSAssert(self.APIKey, @"API Key has not been set. Please set API Key as below.\n\n[AppSociallyClient setAPIKey:@\"YOUR_APPSOCIALLY_API_KEY\"];\n\n");
    
    NSMutableDictionary *params = parameters.mutableCopy;
        
    NSMutableURLRequest *req = [super requestWithMethod:method path:path parameters:params];
    [req setValue:self.APIKey forHTTPHeaderField:@"X-API-KEY"];

    // set cookies
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    NSDictionary * headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    [req setAllHTTPHeaderFields:headers];
    
    NSLog(@"allHTTPHeaderFields:%@", [req allHTTPHeaderFields]);
    
    return req;
}

- (void)authorizeWithEmail:(NSString *)email
                  password:(NSString *)password
                   handler:(void (^)(NSDictionary *result, NSError *error))handler
{
    __weak ASDashboardClient *weakSelf;
    
    NSAssert([email length], @"no email");
    NSAssert([password length], @"no password");
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        NSString *path = @"/login";

        NSDictionary *params = @{@"email": email,
                                 @"password": password};
        
        NSLog(@"path:%@, params:%@", path, params);

        [weakSelf postPath:path
                parameters:params
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       
                       dispatch_async(dispatch_get_main_queue(), ^{
                           
                           handler(responseObject, nil);
                       });
                       
                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       
                       dispatch_async(dispatch_get_main_queue(), ^{
                           
                           handler(nil, error);
                       });
                   }];
    });
}

- (void)requestStatsWithType:(ASStatsType)type
                     handler:(void (^)(NSDictionary *result, NSError *error))handler
{
    __weak ASDashboardClient *weakSelf = self;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{

        // Create the API path
        NSString *path = @"/stats";

        switch (type) {

            case ASStatsTypeOverall:
            default:

                path = [path stringByAppendingString:@"/total"];

                break;

            case ASStatsTypeToday:

                break;

            case ASStatsTypeByMonth:
            {
#warning とりあえず今月だけ。

                NSDate *date = [NSDate date];
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setLocale:[NSLocale systemLocale]];
                [dateFormatter setDateFormat:@"yyyy-MM"];
                NSString *dateStr = [dateFormatter stringFromDate:date];

                path = [path stringByAppendingFormat:@"/month/%@", dateStr];

                break;
            }
        }
        
        NSLog(@"path:%@", path);
        
        [weakSelf getPath:path
               parameters:nil
                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
                      
                      dispatch_async(dispatch_get_main_queue(), ^{
                          
                          handler(responseObject, nil);
                      });
                      
                  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                      
                      dispatch_async(dispatch_get_main_queue(), ^{
                          
                          handler(nil, error);
                      });
                  }];
    });
}

- (void)requestAppsWithHandler:(void (^)(NSDictionary *result, NSError *error))handler {

    __weak ASDashboardClient *weakSelf = self;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        // Create the API path
        NSString *path = @"/dashboard/apps?page=0";
        
        NSLog(@"path:%@", path);
        
        [weakSelf getPath:path
               parameters:nil
                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
                      
                      dispatch_async(dispatch_get_main_queue(), ^{
                          
                          handler(responseObject, nil);
                      });
                      
                  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                      
                      dispatch_async(dispatch_get_main_queue(), ^{
                          
                          handler(nil, error);
                      });
                  }];
    });
}


// =============================================================================
#pragma mark - Public

+ (void)setAPIKey:(NSString *)APIKey {
    
    [[ASDashboardClient sharedClient] setAPIKey:APIKey];
}

+ (void)requestStatsWithType:(ASStatsType)type
                     handler:(void (^)(NSDictionary *result, NSError *error))hanler
{
    [[ASDashboardClient sharedClient] requestStatsWithType:type
                                                handler:hanler];
}

+ (void)requestAppsWithHandler:(void (^)(NSDictionary *result, NSError *error))handler
{
//    LOG_CURRENT_METHOD;
    
    [[ASDashboardClient sharedClient] requestAppsWithHandler:handler];
}

@end
