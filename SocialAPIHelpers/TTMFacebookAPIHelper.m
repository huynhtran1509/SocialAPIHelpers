//
//  FacebookAPIHelper.m
//
//  Created by Shuichi Tsutsumi on 8/6/13.
//  Copyright (c) 2013 Shuichi Tsutsumi. All rights reserved.
//

#import "TTMFacebookAPIHelper.h"
#import "NSString+URL.h"


#define kBaseURL @"https://graph.facebook.com"


@implementation TTMFacebookAPIHelper

// =============================================================================
#pragma mark - User

// The user's profile
+ (void)userProfileWithUserId:(NSString *)userId
               requestAccount:(ACAccount *)requestAccount
                      handler:(TTMRequestHandler)handler
{
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@", kBaseURL, userId];
    NSURL *url = [NSURL URLWithString:urlStr];
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:nil];

    request.account = requestAccount;
    
    [request performAsyncRequestWithHandler:handler];
}

+ (void)userProfileForAccount:(ACAccount *)account
                      handler:(void (^)(TTMFacebookProfile *profile, NSDictionary *result, NSError *error))handler
{
    // https://developers.facebook.com/docs/reference/api/using-pictures/
    NSString *urlStr = [NSString stringWithFormat:@"%@/me", kBaseURL];
    NSURL *url = [NSURL URLWithString:urlStr];

    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:nil];
    
    request.account = account;
    
    [request performAsyncRequestWithHandler:^(id result, NSError *error) {
        
        if (error) {
            handler(nil, nil, error);
            return;
        }
        
        TTMFacebookProfile *profile = [[TTMFacebookProfile alloc] initWithDictionray:result];
        handler(profile, result, nil);
    }];
}

// The user's friends.
+ (void)friendsForAccount:(ACAccount *)account
                  handler:(void (^)(NSArray<TTMFacebookProfile *> *friends, NSDictionary *result, NSError *error))handler
{
    NSString *urlStr = [NSString stringWithFormat:@"%@/me/friends", kBaseURL];
    NSURL *url = [NSURL URLWithString:urlStr];
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:nil];

    request.account = account;
    
    [request performAsyncRequestWithHandler:^(id result, NSError *error) {
        
        if (error) {
            handler(nil, nil, error);
            return;
        }
        
        NSArray<NSDictionary *> *friendDics = result[@"data"];
        NSMutableArray<TTMFacebookProfile *> *arr = @[].mutableCopy;
        for (NSDictionary *aDic in friendDics) {
            
            TTMFacebookProfile *aProfile = [[TTMFacebookProfile alloc] initWithDictionray:aDic];
            if (aProfile) {
                [arr addObject:aProfile];
            }
        }
        
        handler(arr, result, error);
    }];
}


// =============================================================================
#pragma mark - Pictures

+ (NSString *)profilePictureURLForUserId:(NSString *)userId {

    NSString *urlStr = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=square", userId];
    
    return urlStr;
}


// =============================================================================
#pragma mark - News Feed

+ (void)newsfeedForAccount:(ACAccount *)account
                parameters:(NSDictionary *)parameters
              withLocation:(BOOL)withLocation
                   handler:(TTMRequestHandler)handler
{
    // https://developers.facebook.com/docs/reference/api/user/#home
    NSString *urlStr = [NSString stringWithFormat:@"%@/me/home", kBaseURL];
    
    NSURL *url = [NSURL URLWithString:urlStr];
    
    NSMutableDictionary *params = parameters.mutableCopy;
    if (withLocation) {
        params[@"with"] = @"location";
    }
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:params];
    
    request.account = account;

    [request performAsyncRequestWithHandler:handler];
}

+ (void)newsfeedForAccount:(ACAccount *)account
                   handler:(TTMRequestHandler)handler
{
    [TTMFacebookAPIHelper newsfeedForAccount:account
                               parameters:@{}
                             withLocation:NO
                                  handler:handler];
}

+ (void)newsfeedWithPreviousURL:(NSString *)previousUrl
                        account:(ACAccount *)account
                   withLocation:(BOOL)withLocation
                        handler:(TTMRequestHandler)handler
{
    NSDictionary *allParams = [previousUrl dictionaryFromURLString];
    
    NSDictionary *params = @{@"since": allParams[@"since"],
                             @"__previous": allParams[@"__previous"]};
    
    [TTMFacebookAPIHelper newsfeedForAccount:account
                               parameters:params
                             withLocation:withLocation
                                  handler:handler];
}

+ (void)newsfeedWithNextURL:(NSString *)nextUrl
                    account:(ACAccount *)account
               withLocation:(BOOL)withLocation
                    handler:(TTMRequestHandler)handler
{
    NSDictionary *allParams = [nextUrl dictionaryFromURLString];
    
    NSDictionary *params = @{@"until": allParams[@"until"]};
    
    [TTMFacebookAPIHelper newsfeedForAccount:account
                               parameters:params
                             withLocation:withLocation
                                  handler:handler];
}


// =============================================================================
#pragma mark - Posts

+ (void)postsOfUserId:(NSString *)userId
              account:(ACAccount *)account
              handler:(TTMRequestHandler)handler
{
    // https://developers.facebook.com/docs/graph-api/reference/user/
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@/posts", kBaseURL, userId];
    
    NSURL *url = [NSURL URLWithString:urlStr];
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:nil];
    
    request.account = account;

    [request performAsyncRequestWithHandler:handler];
}


// =============================================================================
#pragma mark - Publish

// Publish a new post or Upload a photo
+ (void)postMessage:(NSString *)message
              image:(UIImage *)image
            account:(ACAccount *)account
            handler:(TTMRequestHandler)handler
{
    NSDictionary *params = @{@"message": message};
    
    BOOL withMedia = [image isKindOfClass:[UIImage class]] ? YES : NO;
    
    NSString *urlStr;
    
    if (withMedia) {
        
        // https://developers.facebook.com/docs/reference/api/photo/
        urlStr = @"https://graph.facebook.com/me/photos";
    }
    else {
        
        // https://developers.facebook.com/docs/reference/api/post/
        urlStr = @"https://graph.facebook.com/me/feed";
    }
    
    NSURL *url = [NSURL URLWithString:urlStr];
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                            requestMethod:SLRequestMethodPOST
                                                      URL:url
                                               parameters:params];
    
    if (withMedia) {
        
        NSData* photo = [[NSData alloc] initWithData:UIImagePNGRepresentation(image)];
        [request addMultipartData:photo
                         withName:@"name"
                             type:@"multipart/form-data"
                         filename:@"@image.png"];
    }
    
    request.account = account;

    [request performAsyncRequestWithHandler:handler];
}



// =============================================================================
#pragma mark - App Request

// Post an apprequest
// https://developers.facebook.com/docs/reference/api/user/#apprequests
+ (void)postAppRequestToUserId:(NSString *)userId
                       message:(NSString *)message
                    trackingId:(NSString *)trackingId
                       account:(ACAccount *)account
                       handler:(TTMRequestHandler)handler
{
    NSAssert(message, @"message is required");
    
    NSMutableDictionary *params = @{@"message": message}.mutableCopy;
    
    if (trackingId) {
        
        params[@"data"] = trackingId;
    }
    
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@/apprequests", kBaseURL, userId];
    
    NSURL *url = [NSURL URLWithString:urlStr];
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                            requestMethod:SLRequestMethodPOST
                                                      URL:url
                                               parameters:params];
    
    request.account = account;

    [request performAsyncRequestWithHandler:handler];
}


// =============================================================================
#pragma mark - Others

+ (NSDate *)dateOfPost:(NSDictionary *)post {
    
    NSString *dateStr = post[@"created_time"];
    
    NSDateFormatter *inputFormat = [[NSDateFormatter alloc] init];
    inputFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    inputFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZ";
    NSDate *date = [inputFormat dateFromString:dateStr];
    
    return date;
}

+ (NSArray<NSDictionary *> *)sortedPostsWithLikes:(NSArray<NSDictionary *> *)posts {
    
    NSMutableArray<NSDictionary *> *sorted = @[].mutableCopy;
    
    for (NSDictionary *aPost in posts) {

        NSArray<NSDictionary *> *likes = aPost[@"likes"][@"data"];

        BOOL inserted = NO;
        for (int i=0; i<sorted.count; i++) {
            
            NSDictionary *aSortedPost = sorted[i];
            NSArray<NSDictionary *> *compareLikes = aSortedPost[@"likes"][@"data"];
            if (likes.count > compareLikes.count) {
                
                [sorted insertObject:aPost atIndex:i];
                
                inserted = YES;
                break;
            }
        }
        
        if (!inserted) {
            [sorted addObject:aPost];
        }
    }
    
    return sorted;
}

@end
