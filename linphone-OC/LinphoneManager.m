//
//  LinphoneManager.m
//  LinPhoneCall
//
//  Created by zhaofei on 2017/8/24.
//  Copyright © 2017年 zhaofei. All rights reserved.
//

#import "LinphoneManager.h"
#import <AVFoundation/AVFoundation.h>

static LinphoneCore *lc = nil;
static  CXProvider *provider = nil;

extern void libmsamr_init(MSFactory *factory);
extern void libmsx264_init(MSFactory *factory);
extern void libmsopenh264_init(MSFactory *factory);
extern void libmssilk_init(MSFactory *factory);
extern void libmswebrtc_init(MSFactory *factory);

@interface LinphoneManager () <CXProviderDelegate>
@property (nonatomic, strong) NSTimer *iterateTimer;

@property(nonatomic, strong) CXProvider *provider;
@end

@implementation LinphoneManager

+ (instancetype)instance {
    
    static LinphoneManager *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (LinphoneCore *)getLc {
    return lc;
}

- (CXProvider *)getCXProvider {
    return provider;
}

- (void)configureLinphone {
    
    CXProviderConfiguration *config = [[CXProviderConfiguration alloc]
                                       initWithLocalizedName: @"Fuck you"];
    config.ringtoneSound = @"notes_of_the_optimistic.caf";
    config.supportsVideo = FALSE;
    config.iconTemplateImageData = UIImagePNGRepresentation([UIImage imageNamed:@"callkit_logo"]);
    
    NSArray *ar = @[ [NSNumber numberWithInt:(int)CXHandleTypeGeneric] ];
    NSSet *handleTypes = [[NSSet alloc] initWithArray:ar];
    [config setSupportedHandleTypes:handleTypes];
    [config setMaximumCallGroups:2];
    [config setMaximumCallsPerCallGroup:1];
    provider = [[CXProvider alloc] initWithConfiguration: config];
    [provider setDelegate: self queue: nil];
    
    
//    ms_factory_new_with_voip_and_directories("liblinphone-sdk/apple-darwin/lib/mediastreamer/plugins", NULL);
    
    
    
    // 打印debug信息
    linphone_core_set_log_level(ORTP_DEBUG);
    
    // 单例工厂
    LinphoneFactory *factory = linphone_factory_get();
    
    // 回调对象
    LinphoneCoreCbs *cbs = linphone_factory_create_core_cbs(factory);
    
    // 核心
    NSString *config_path = [[NSBundle mainBundle] pathForResource:@"linphonerc" ofType: nil];
    NSString *factory_config_path = [[NSBundle mainBundle] pathForResource:@"linphonerc-factory" ofType: nil];
    lc = linphone_factory_create_core(factory, cbs, [config_path cStringUsingEncoding: NSUTF8StringEncoding], [factory_config_path cStringUsingEncoding: NSUTF8StringEncoding]);
    
    
    // Load plugins if available in the linphone SDK - otherwise these calls will do nothing
    MSFactory *f = linphone_core_get_ms_factory(lc);
    libmssilk_init(f);
    libmsamr_init(f);
    libmsx264_init(f);
    libmsopenh264_init(f);
    libmswebrtc_init(f);
    linphone_core_reload_ms_plugins(lc, NULL);
    
    // 设置铃声
    NSString *ringPath = [[NSBundle mainBundle] pathForResource: @"shortring.caf" ofType: nil];
    linphone_core_set_ring(lc, [ringPath cStringUsingEncoding: NSUTF8StringEncoding]);
    
    NSString *ringbackPath = [[NSBundle mainBundle] pathForResource: @"ringback.wav" ofType: nil];
    linphone_core_set_ringback(lc, [ringbackPath cStringUsingEncoding: NSUTF8StringEncoding]);
    
    // 代理配置
    LinphoneProxyConfig *proxyCf = linphone_core_create_proxy_config(lc);
    
    // 监听各种状态
        // 监听注册状态
    linphone_core_cbs_set_registration_state_changed(cbs, registerationStateChangeCb);
    
        // 监听电话的状态
    linphone_core_cbs_set_call_state_changed(cbs, callStateChangedCb);
    
    
    NSString *username = @"1000";
    NSString *password = @"1234";
    NSString *domain = @"10.71.201.160";
    NSString *server_addr = [NSString stringWithFormat:@"%@%@;transport=%@", @"10.71.201.160", @"", @"udp"];
    
    // 用户
    char *normalize_phone_number = linphone_proxy_config_normalize_phone_number(proxyCf, [username cStringUsingEncoding: NSUTF8StringEncoding]);
    
    // 地址
    const char *identity = [@"sip:1000@10.71.201.160" cStringUsingEncoding:NSUTF8StringEncoding];
    LinphoneAddress* linphoneAddress = linphone_address_new(identity);
    linphone_address_set_username(linphoneAddress, normalize_phone_number);
    
    // 服务器地址
    linphone_proxy_config_set_server_addr(proxyCf, [server_addr cStringUsingEncoding: NSUTF8StringEncoding]);

    // 域名
    linphone_address_set_domain(linphoneAddress, [domain cStringUsingEncoding: NSUTF8StringEncoding]);
    
    // 授权信息
    LinphoneAuthInfo *info = linphone_auth_info_new(normalize_phone_number, NULL, [password cStringUsingEncoding: NSUTF8StringEncoding], NULL, NULL, [domain cStringUsingEncoding: NSUTF8StringEncoding]);
    
    linphone_proxy_config_set_identity_address(proxyCf, linphoneAddress);
    //    linphone_proxy_config_set_expires(proxyCfg, 2000);
    linphone_proxy_config_enable_register(proxyCf, true);
    
    // 添加授权信息
    linphone_core_add_auth_info(lc, info);
    // 添加代理配置
    linphone_core_add_proxy_config(lc, proxyCf);
    // 设置默认的代理配置
    linphone_core_set_default_proxy_config(lc, proxyCf);
    
    // 视频
    linphone_core_enable_video_capture(lc, true);
    linphone_core_enable_video_display(lc, true);
    linphone_core_enable_video_preview(lc, true);
    linphone_core_use_preview_window(lc, true);
    linphone_core_self_view_enabled(lc);
    
    // 摄像头 默认前置
    linphone_core_set_video_device(lc, FRONT_CAM_NAME);
    
    self.iterateTimer = [NSTimer timerWithTimeInterval:0.02 target:self selector:@selector(interate) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer: self.iterateTimer forMode: NSRunLoopCommonModes];
}

- (void)interate{
    if (lc) {
        linphone_core_iterate(lc);
    }
}

// MARK: linphone 注册状态
void registerationStateChangeCb(LinphoneCore *lc, LinphoneProxyConfig *cfg, LinphoneRegistrationState cstate, const char *message) {
    NSLog(@"%d", cstate);
    
//    typedef enum _LinphoneRegistrationState {
//        LinphoneRegistrationNone, /**< Initial state for registrations */
//        LinphoneRegistrationProgress, /**< Registration is in progress */
//        LinphoneRegistrationOk,    /**< Registration is successful */
//        LinphoneRegistrationCleared, /**< Unregistration succeeded */
//        LinphoneRegistrationFailed    /**< Registration failed */
//    } LinphoneRegistrationState;

    switch (cstate) {
        case LinphoneRegistrationNone:
            NSLog(@"还没有注册");
            break;
        case LinphoneRegistrationProgress:
            NSLog(@"正在注册");
            break;

        case LinphoneRegistrationOk:
            NSLog(@"注册完成");
            break;

        case LinphoneRegistrationCleared:
            NSLog(@"注册被取消");
            break;

        case LinphoneRegistrationFailed:
            NSLog(@"注册失败");
            break;
        default:
            break;
    }
    
}

// MARK: 监听电话的状态
void callStateChangedCb(LinphoneCore *lc, LinphoneCall *call, LinphoneCallState cstate, const char *message) {
    
    NSLog(@"=======");
    
    const char *remoteContact = linphone_call_get_remote_contact(call);
    NSLog(@"remoteContact: %s", remoteContact);
    
    NSLog(@"cstate: %d", cstate);
    logCallState(cstate);
    NSLog(@"message: %s", message);
    NSLog(@"=======");
    
    if (cstate == LinphoneCallIncomingReceived) {
        NSLog(@"收到来电");
        
        // Create update to describe the incoming call and caller
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
//                                              NSLog(error);
                                          }];
        
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"收到来电" message: [NSString stringWithFormat: @"%s", remoteContact] delegate: [LinphoneManager instance] cancelButtonTitle: @"拒绝" otherButtonTitles: @"接收", nil];
//        [alertView show];
    }
}


// MARK: 拨打电话
- (void)makeCall: (NSString *)username {
    const char *calleeAccount = [username cStringUsingEncoding: NSUTF8StringEncoding];
    linphone_core_invite(lc, calleeAccount);
}

// MARK: 结束当前通话
- (void)cancelCurrentCall {
    LinphoneCall *currentCall = linphone_core_get_current_call(lc);
    if (!currentCall) {
        return;
    }
    linphone_call_terminate(currentCall);
}

void logCallState(LinphoneCallState cstate) {
    switch (cstate) {
        case LinphoneCallIdle:
            NSLog(@"初始化电话状态");
            break;
        case LinphoneCallIncomingReceived:
            NSLog(@"收到来电");
            break;
        case LinphoneCallOutgoingInit:
            NSLog(@"初始化拨出电话");
            break;
        case LinphoneCallOutgoingProgress:
            NSLog(@"拨出电话进行中......");
            break;
        case LinphoneCallOutgoingEarlyMedia:
            NSLog(@"LinphoneCallOutgoingEarlyMedia");
            break;
        case LinphoneCallConnected:
            NSLog(@"电话接通");
            break;
        case LinphoneCallStreamsRunning:
            NSLog(@"电话流 稳定运行中.....");
            break;
        case LinphoneCallPausing:
            NSLog(@"电话暂停");
            break;
        case LinphoneCallResuming:
            NSLog(@"电话恢复");
            break;
        case LinphoneCallRefered:
            NSLog(@"LinphoneCallRefered");
            break;
        case LinphoneCallError:
            NSLog(@"电话错误");
            break;
        case LinphoneCallEnd:
            NSLog(@"电话结束");
            break;
        case LinphoneCallPausedByRemote:
            NSLog(@"电话被远程暂停");
            break;
        case LinphoneCallUpdatedByRemote:
            NSLog(@"LinphoneCallUpdatedByRemote used for example when video is added by remote");
            break;
        case LinphoneCallIncomingEarlyMedia:
            NSLog(@"LinphoneCallIncomingEarlyMedia");
            break;
        case LinphoneCallUpdating:
            NSLog(@"LinphoneCallUpdating");
            break;
        case LinphoneCallReleased:
            NSLog(@"LinphoneCallReleased");
            break;
        case LinphoneCallEarlyUpdatedByRemote:
            NSLog(@"LinphoneCallEarlyUpdatedByRemote");
            break;
        case LinphoneCallEarlyUpdating:
            NSLog(@"LinphoneCallEarlyUpdating");
            break;
        default:
            break;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"%@", [NSThread currentThread]);
    LinphoneCall *call = linphone_core_get_current_call(lc);
    
    if (!call) {
        return ;
    }
    
    if (buttonIndex == 0) {
        // 拒绝来电
        linphone_call_decline(call, LinphoneReasonDeclined);
    } else if (buttonIndex == 1) {
        // 接收来电
        linphone_call_params_enable_video(linphone_call_get_current_params(call), true);
        linphone_call_accept(call);
    }
}

- (void)dealloc {
    [self.iterateTimer invalidate];
    self.iterateTimer = nil;
}

- (void)providerDidReset:(nonnull CXProvider *)provider {
    
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    NSLog(@"performAnswerCallAction");
    LinphoneCall *call = linphone_core_get_current_call(lc);
    
    if (!call) {
        return ;
    }

    linphone_call_accept(call);
}



- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {
    NSLog(@"performStartCallAction");
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    NSLog(@"performEndCallAction");
    
    LinphoneCall *call = linphone_core_get_current_call(lc);
    
    if (!call) {
        return ;
    }
    
    linphone_call_decline(call, LinphoneReasonDeclined);
}

@end
