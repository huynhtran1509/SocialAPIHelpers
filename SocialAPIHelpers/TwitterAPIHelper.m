//
//  TwitterAPIClient.h
//
//  Created by Shuichi Tsutsumi on 8/6/13.
//  Copyright (c) 2013 Shuichi Tsutsumi. All rights reserved.
//

#import "TwitterAPIHelper.h"
#import <Accounts/Accounts.h>


#define kBaseURL @"http://api.twitter.com/1.1"


#pragma mark -------------------------------------------------------------------
#pragma mark - Categories

@interface NSURL (Extension)
+ (NSURL *)URLWithPath:(NSString *)path;
@end


@implementation NSURL (Extension)

+ (NSURL *)URLWithPath:(NSString *)path {
    
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@", kBaseURL, path];
    NSURL *url = [NSURL URLWithString:urlStr];
    
    return url;
}

@end



#pragma mark -------------------------------------------------------------------
#pragma mark - TwitterAPIHelper


@implementation TwitterAPIHelper

// =============================================================================
#pragma mark - GET statuses/home_timeline

+ (void)homeTimelineWithCount:(NSUInteger)count
                      sinceId:(NSString *)sinceId
                      account:(ACAccount *)account
                      handler:(SLRequestHandler)handler
{
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    NSMutableDictionary *parameters = @{}.mutableCopy;

    if (count > 0) {
        
        parameters[@"count"] = @(count);
    }
    
    if (sinceId) {
    
        parameters[@"since_id"] = sinceId;
    }
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:parameters];
    
    request.account = account;
    
    [request performRequestWithHandler:handler];
}

+ (void)homeTimelineForAccount:(ACAccount *)account
                       handler:(SLRequestHandler)handler
{
    [TwitterAPIHelper homeTimelineWithCount:20  // default by Twitter
                                    sinceId:nil
                                    account:account
                                    handler:handler];
}


// =============================================================================
#pragma mark - GET statuses/user_timeline

+ (void)userTimelineWithScreenName:(NSString *)screenName
                             count:(NSUInteger)count
                           sinceId:(NSString *)sinceId
                           account:(ACAccount *)account
                           handler:(SLRequestHandler)handler
{
    NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/1.1/statuses/user_timeline.json"];
    NSMutableDictionary *parameters = @{@"screen_name": screenName}.mutableCopy;
    
    if (count > 0) {
        
        parameters[@"count"] = @(count);
    }
    
    if (sinceId) {
        
        parameters[@"since_id"] = sinceId;
    }
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:parameters];
    
    request.account = account;
    
    [request performRequestWithHandler:handler];
}

+ (void)userTimelineWithScreenName:(NSString *)screenName
                           account:(ACAccount *)account
                           handler:(SLRequestHandler)handler
{
    [TwitterAPIHelper userTimelineWithScreenName:screenName
                                           count:20 // default by Twitter
                                         sinceId:nil
                                         account:account
                                         handler:handler];
}


// =============================================================================
#pragma mark - GET users/show

+ (void)userInformationWithScreenName:(NSString *)screenName
                       account:(ACAccount *)requestAccount
                              handler:(SLRequestHandler)handler
{
    NSURL *url = [NSURL URLWithPath:@"users/show.json"];
    NSDictionary *parameters = @{@"screen_name": screenName,
                                 @"include_entities": @"false"};
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:parameters];
    
    request.account = requestAccount;
    
    [request performRequestWithHandler:handler];
}

+ (void)userInformationForAccount:(ACAccount *)account
                          handler:(SLRequestHandler)completion
{
    [TwitterAPIHelper userInformationWithScreenName:account.username
                                     account:account
                                            handler:completion];
}


// =============================================================================
#pragma mark - GET friends/list

+ (void)friendsListForAccount:(ACAccount *)account
                   nextCursor:(NSString *)nextCursor
                      handler:(SLRequestHandler)handler
{
    NSURL *url = [NSURL URLWithPath:@"friends/list.json"];
    
    NSDictionary *parameters;
    if (nextCursor.intValue > 0) {
        
        parameters = @{@"cursor": nextCursor,
                       @"skip_status": @"true"};
    }
    else {
        
        parameters = @{@"skip_status": @"true"};
    }

    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:parameters];
    
    request.account = account;
    
    [request performRequestWithHandler:handler];
}


// =============================================================================
#pragma mark - GET friends/ids

+ (void)friendsIdsForAccount:(ACAccount *)account
                  nextCursor:(NSString *)nextCursor
                     handler:(SLRequestHandler)handler
{
    NSURL *url = [NSURL URLWithPath:@"friends/ids.json"];
    
    NSDictionary *parameters;
    if (nextCursor.intValue > 0) {
        
        parameters = @{@"cursor": nextCursor};
    }
    else {
        
        parameters = @{};
    }
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:parameters];
    
    request.account = account;
    
    [request performRequestWithHandler:handler];
}


// =============================================================================
#pragma mark - GET users/lookup

// https://dev.twitter.com/docs/api/1.1/get/users/lookup
+ (void)userInformationsForIDs:(NSArray *)ids
                requestAccount:(ACAccount *)requestAccount
                       handler:(SLRequestHandler)handler
{
    NSAssert([ids count], @"no IDs");
    NSAssert([ids count] <= 100, @"too many IDs");
    
    NSMutableString *idsStr = @"".mutableCopy;
    for (NSString *anID in ids) {
        
        [idsStr appendFormat:@"%@,", anID];
    }
    if ([idsStr hasSuffix:@","]) {
        [idsStr deleteCharactersInRange:NSMakeRange([idsStr length] - 1, 1)];
    }
    
    NSURL *url = [NSURL URLWithPath:@"users/lookup.json"];
    NSDictionary *parameters = @{@"user_id": idsStr,
                                 @"include_entities": @"false"};

    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:parameters];
    
    request.account = requestAccount;
    
    [request performRequestWithHandler:handler];
}


// =============================================================================
#pragma mark - POST statuses/update

+ (void)updateStatus:(NSString *)status
               image:(UIImage *)image
             account:(ACAccount *)account
             handler:(SLRequestHandler)handler
{
    BOOL withMedia = [image isKindOfClass:[UIImage class]] ? YES : NO;
    
    NSURL *url;
    NSDictionary *params = @{@"status": status};
    
    // 画像あり
    if (withMedia) {
        
        url = [NSURL URLWithPath:@"statuses/update_with_media.json"];
    }
    // 画像なし
    else {
        
        url = [NSURL URLWithPath:@"statuses/update.json"];
    }
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodPOST
                                                      URL:url
                                               parameters:params];
    
    if (withMedia) {
        
        NSData *imageData = UIImageJPEGRepresentation(image, 1.f);
        [request addMultipartData:imageData
                         withName:@"media[]"
                             type:@"image/jpeg"
                         filename:@"image.jpg"];
    }
    
    request.account = account;

    [request performRequestWithHandler:handler];
}


// =============================================================================
#pragma mark - POST direct_messages/new

+ (void)sendDirectMessageToScreenName:(NSString *)screenName
                              message:(NSString *)message
                              account:(ACAccount *)account
                              handler:(SLRequestHandler)handler
{
    NSURL *url = [NSURL URLWithPath:@"direct_messages/new.json"];
    
    NSDictionary *parameters = @{@"text": message,
                                 @"screen_name": screenName};
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodPOST
                                                      URL:url
                                               parameters:parameters];
    
    request.account = account;
    
    [request performRequestWithHandler:handler];
}

@end
