//
//  ViewController.m
//  LinPhoneCall
//
//  Created by zhaofei on 2017/8/22.
//  Copyright © 2017年 zhaofei. All rights reserved.
//

#import "ViewController.h"
#import "VideoViewController.h"
#import "LinphoneManager.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *registerStateLabel;
@property (weak, nonatomic) IBOutlet UITextField *usernameTF;
@property (weak, nonatomic) IBOutlet UITextField *passwordTF;
@property (weak, nonatomic) IBOutlet UITextField *domainTF;
@property (weak, nonatomic) IBOutlet UITextField *detinationTF;

@end

@implementation ViewController

- (IBAction)makeACall:(UIButton *)sender {
    
    if (!self.detinationTF.text.length) {
        return ;
    }
    [[LinphoneManager instance] makeCall: self.detinationTF.text];
}

- (IBAction)cancelCurrentCall:(UIButton *)sender {
    [[LinphoneManager instance] cancelCurrentCall];
}

- (IBAction)openVideo:(id)sender {
    NSLog(@"打开视频");
    
    LinphoneCore *lc = [[LinphoneManager instance] getLc];
    LinphoneCall *call = linphone_core_get_current_call(lc);
    
    if (!call) {
        return ;
    }
    [self.navigationController pushViewController: [[VideoViewController alloc] init] animated: YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
}
@end
