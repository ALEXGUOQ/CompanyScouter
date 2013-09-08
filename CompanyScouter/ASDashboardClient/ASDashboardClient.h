//
//  ASDashboardClient.h
//  DashboardAPI
//
//  Created by shuichi on 7/13/13.
//  Copyright (c) 2013 Shuichi Tsutsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"


//#define STAGING


extern NSString * const ASAPIResponseClickCount;
extern NSString * const ASAPIResponseDate;
extern NSString * const ASAPIResponseInvitationCount;
extern NSString * const ASAPIResponseInviteeCount;
extern NSString * const ASAPIResponseKFactor;
extern NSString * const ASAPIResponseUserCount;

extern NSString * const ASAPIResponseAppName;
extern NSString * const ASAPIResponseAppIconUrl;


typedef enum {
	ASStatsTypeOverall,
	ASStatsTypeToday,
    ASStatsTypeByMonth,
} ASStatsType;


@interface ASDashboardClient : AFHTTPClient

+ (ASDashboardClient *)sharedClient;

+ (void)setAPIKey:(NSString *)APIKey;

+ (void)requestStatsWithType:(ASStatsType)type
                  handler:(void (^)(NSDictionary *result, NSError *error))completion;

+ (void)requestAppsWithHandler:(void (^)(NSDictionary *result, NSError *error))handler;

@end
