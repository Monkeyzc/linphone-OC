//
//  AppDelegate.m
//  linphone-OC
//
//  Created by zhaofei on 2017/8/29.
//  Copyright © 2017年 zhaofei. All rights reserved.
//

#import "AppDelegate.h"
#import "LinphoneManager.h"
#import <PushKit/PushKit.h>
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import <CallKit/CallKit.h>
#import "IQKeyboardManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AppDelegate () <PKPushRegistryDelegate, UNUserNotificationCenterDelegate>
@property PKPushRegistry *voipRegistry;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UIApplication *app = [UIApplication sharedApplication];
    
    LinphoneManager *manager = [[LinphoneManager alloc] init];
    [manager configureLinphone];
    
    [self registerForNotifications:app];

    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleLinphoneCallStateChangeCbNotification:) name:@"LinphoneCallStateChangeCbNotification" object:nil];
    
    [self setNotificationCategory];
    
    return YES;
}

#pragma mark --- Init IQKeyboardManager
- (void)initIQKeyboardManager{
    [IQKeyboardManager sharedManager].keyboardDistanceFromTextField = 0;
    [IQKeyboardManager sharedManager].shouldResignOnTouchOutside = YES;
    [IQKeyboardManager sharedManager].enableAutoToolbar = YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - registerForNotifications
- (void)registerForNotifications:(UIApplication *)app {
    
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    self.voipRegistry = [[PKPushRegistry alloc] initWithQueue:mainQueue];
    self.voipRegistry.delegate = self;
    
    // Initiate registration.
    self.voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

#pragma mark - PushKit Functions

- (void)pushRegistry:(PKPushRegistry *)registry
didInvalidatePushTokenForType:(NSString *)type {
    NSLog(@"PushKit Token invalidated");
//    dispatch_async(dispatch_get_main_queue(), ^{[LinphoneManager.instance setPushNotificationToken:nil];});
}

- (void)pushRegistry:(PKPushRegistry *)registry
didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
             forType:(NSString *)type {
    
    NSLog(@"PushKit: incoming voip notfication: %@", payload.dictionaryPayload);
    
    // 重新启动 linphone
    LinphoneCore *lc = [[LinphoneManager instance] getLc];
    linphone_core_unref(lc);
    lc = nil;
    [[LinphoneManager instance] configureLinphone];
}

void systemAudioCallback() {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)pushRegistry:(PKPushRegistry *)registry
didUpdatePushCredentials:(PKPushCredentials *)credentials
             forType:(PKPushType)type {
    
    NSString *str = [NSString stringWithFormat:@"%@",credentials.token];
    str = [[[str stringByReplacingOccurrencesOfString:@"<" withString:@""]
                  stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"voip token: %@", str);
    
    // TODO: send voip notification device token to server
}

#pragma mark - handleLinphoneCallStateChangeCbNotification
- (void)handleLinphoneCallStateChangeCbNotification: (NSNotification *)notification {
    
    NSLog(@"handleLinphoneCallStateChangeCbNotification");
    NSInteger state = [notification.object integerValue];
    
    UIApplicationState applicationState = [[UIApplication sharedApplication] applicationState];
    double systemVersion = [[[UIDevice currentDevice] systemVersion] doubleValue];
    
    if (state == LinphoneCallIncomingReceived) {
        
        // iOS10.0以上系统使用CallKit, 以下使用 notification
        if (systemVersion >= 10.0) {
            //  Create update to describe the incoming call and caller
            CXCallUpdate *update = [[CXCallUpdate alloc] init];
            update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value: @"FUCK"];
            update.supportsDTMF = TRUE;
            update.supportsHolding = TRUE;
            update.supportsGrouping = TRUE;
            update.supportsUngrouping = TRUE;
            update.hasVideo = FALSE;

            // Report incoming call to system
            NSLog(@"CallKit: report new incoming call");
            [[[LinphoneManager instance] getCXProvider] reportNewIncomingCallWithUUID: [NSUUID UUID]
                                                                                update:update
                                                                            completion:^(NSError *error) {
//                                                                                  NSLog(error);
                                                                            }
             ];
        } else {
            UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
            content.title = @"APN Pusher";
            content.body = @"Push notification received !";
            content.categoryIdentifier = @"call_notification_category";
            UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"call_request" content:content trigger:NULL];
            [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:req withCompletionHandler:^(NSError * _Nullable error) {
                // Enable or disable features based on authorization.
                if (error) {
                    NSLog(@"Error while adding notification request :");
                    NSLog(error.description);
                }
                
                // 播放震动 5s
                AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, systemAudioCallback, NULL);
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                //            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //                AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate);
                //            });
            }];
        }
    }
    
    if (state == LinphoneCallDeclined || state == LinphoneCallEnd) {
        [[[LinphoneManager instance] getCXProvider] invalidate];
    }
}

#pragma mark - PushNotification Functions
- (void) userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionAlert);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    
    // 关闭震动
    AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate);
    
    LinphoneCall *call = linphone_core_get_current_call(LC);
    
    if (!call) {
        return ;
    }
    
    NSString *actionIdentifier = response.actionIdentifier;
    
    if ([actionIdentifier isEqualToString: @"Accept"]) {
        linphone_call_accept(call);
    } else if ([actionIdentifier isEqualToString: @"Decline"]) {
        linphone_call_decline(call, LinphoneReasonDeclined);
    }
}

- (void)setNotificationCategory {
    //Call Category
    UNNotificationAction *action_accept_call = [UNNotificationAction actionWithIdentifier: @"Accept"
                                                                                    title: NSLocalizedString(@"Accept", nil)
                                                                                  options: UNNotificationActionOptionAuthenticationRequired | UNNotificationActionOptionForeground];
    
    UNNotificationAction *action_decline_call = [UNNotificationAction actionWithIdentifier: @"Decline"
                                         title: NSLocalizedString(@"Decline", nil)
                                       options: UNNotificationActionOptionAuthenticationRequired | UNNotificationActionOptionForeground | UNNotificationActionOptionDestructive];

    UNNotificationCategory *category_call = [UNNotificationCategory categoryWithIdentifier:@"call_notification_category"
                                           actions: @[action_accept_call, action_decline_call]
                                 intentIdentifiers: [[NSMutableArray alloc] init]
                                           options: UNNotificationCategoryOptionCustomDismissAction];
    
    
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    [[UNUserNotificationCenter currentNotificationCenter]
     requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound |
                                      UNAuthorizationOptionBadge)
     completionHandler:^(BOOL granted, NSError *_Nullable error) {
         // Enable or disable features based on authorization.
         if (error) {
             NSLog(error.description);
         }
     }];
    NSSet *categories = [NSSet setWithObjects: category_call, nil];
    [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:categories];
}
@end
