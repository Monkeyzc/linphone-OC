//
//  LinphoneManager.h
//  LinPhoneCall
//
//  Created by zhaofei on 2017/8/24.
//  Copyright © 2017年 zhaofei. All rights reserved.
//

#define FRONT_CAM_NAME                                                                                                 \
"AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:1" /*"AV Capture: Front Camera"*/
#define BACK_CAM_NAME                                                                                                  \
"AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:0" /*"AV Capture: Back Camera"*/

#define LC [[LinphoneManager instance] getLc]

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include "linphone/linphonecore.h"
#import <CallKit/CallKit.h>

@interface LinphoneManager : NSObject <UIAlertViewDelegate>

+ (instancetype)instance;

- (LinphoneCore *)getLc;
- (void)configureLinphone;

- (void)makeCall: (NSString *)username;
- (void)cancelCurrentCall;
- (CXProvider *)getCXProvider;

@end
