//
//  SendVoipNotificationApi.m
//  linphoneOC
//
//  Created by zhaofei on 2017/8/31.
//  Copyright © 2017年 zhaofei. All rights reserved.
//

#import "SendVoipNotificationApi.h"

@implementation SendVoipNotificationApi

- (NSString *)requestUrl {
    return @"http://10.71.173.194:3000/sendVoipNotification";
}

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodPost;
}

- (id)requestArgument {
    return @{@"token": @"bd669088a418e1234f0f250025300d43ed81321f42f3960273507a6ebe82a9cf"};
}

@end
