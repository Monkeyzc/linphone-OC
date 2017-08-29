//
//  VideoViewController.m
//  LinPhoneCall
//
//  Created by zhaofei on 2017/8/24.
//  Copyright © 2017年 zhaofei. All rights reserved.
//

#import "VideoViewController.h"
#import "LinphoneManager.h"
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/QuartzCore.h>

@interface VideoViewController ()
@property (strong, nonatomic) UIView *videoView;
@property (strong, nonatomic) UIView *preview;

@property (strong, nonatomic) UIButton *videoBtn;
@property (strong, nonatomic) UIButton *changeCameraBtn;

@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.videoView = [[UIView alloc] initWithFrame: self.view.bounds];
    [self.view addSubview: self.videoView];
    
    self.preview = [[UIView alloc] initWithFrame: CGRectMake(0, 64, 108, 145)];
    self.preview.layer.borderColor = [[UIColor redColor] CGColor];
    self.preview.layer.borderWidth = 2;
    [self.view addSubview: self.preview];
    
    self.videoBtn = [[UIButton alloc] init];
    self.videoBtn.highlighted = NO;
    [self.videoBtn setImage: [UIImage imageNamed: @"video-camera"] forState: UIControlStateNormal];
    [self.videoBtn setImage: [UIImage imageNamed: @"video-camera-highlight"] forState: UIControlStateSelected];
    self.videoBtn.frame = CGRectMake(0, self.view.frame.size.height - 64, 64, 64);
    [self.videoBtn addTarget:self action:@selector(clickVideoBtn:) forControlEvents: UIControlEventTouchUpInside];
    [self.view addSubview:self.videoBtn];
    
    self.changeCameraBtn = [[UIButton alloc] init];
    self.changeCameraBtn.backgroundColor = [UIColor greenColor];
    [self.changeCameraBtn setTitleColor: [UIColor redColor] forState: UIControlStateNormal];
    [self.changeCameraBtn setTitle:@"Change Camera" forState:UIControlStateNormal];
    self.changeCameraBtn.frame = CGRectMake(self.view.frame.size.width - 120, self.view.frame.size.height - 64, 120, 64);
    [self.changeCameraBtn addTarget:self action:@selector(clickChangeCameraBtn:) forControlEvents: UIControlEventTouchUpInside];
    [self.view addSubview:self.changeCameraBtn];
}


/**
 切换摄像头
 */
- (void)clickChangeCameraBtn:(UIButton *)btn {
    const char *currentCamId = (char *)linphone_core_get_video_device(LC);
    const char **cameras = linphone_core_get_video_devices(LC);
    const char *newCamId = NULL;
    int i;
    
    for (i = 0; cameras[i] != NULL; ++i) {
        if (strcmp(cameras[i], "StaticImage: Static picture") == 0)
            continue;
        if (strcmp(cameras[i], currentCamId) != 0) {
            newCamId = cameras[i];
            break;
        }
    }
    if (newCamId) {
        linphone_core_set_video_device(LC, newCamId);
        LinphoneCall *call = linphone_core_get_current_call(LC);
        if (call != NULL) {
            linphone_call_update(call, NULL);
        }
    }
}

/**
 打开或关闭视频
 */
- (void)clickVideoBtn:(UIButton *)btn {
    LinphoneCall *call = linphone_core_get_current_call(LC);
    LinphoneCallParams *call_params = linphone_core_create_call_params(LC,call);
    
    if (!btn.selected) {
//         打开视频
        linphone_call_params_enable_video(call_params, TRUE);
    } else {
        linphone_call_params_enable_video(call_params, FALSE);
    }
    
    linphone_call_update(call, call_params);
    linphone_call_params_unref(call_params);
    
    btn.selected = !btn.isSelected;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    // 设置 预览视图 和 视频视图
    linphone_core_set_native_video_window_id(LC, (__bridge void *)(_videoView));
    linphone_core_set_native_preview_window_id(LC, (__bridge void *)(_preview));
    LinphoneCall *call = linphone_core_get_current_call(LC);
    linphone_call_set_user_data(call, (__bridge void *)(self));
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
