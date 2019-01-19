//
//  ViewController.m
//  AppRTCDemo
//
//  Created by jfdreamyang on 2019/1/19.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "ViewController.h"
#import "RongRTCP2PTester.h"
#import <RongIMLib/RongIMLib.h>
// 88060000
#define RONGCLOUD_IM_APPKEY @"lmxuhwagli01d" // online key
#define RONGCLOUD_IM_TOKEN @"PFXIZSdC6XvReEG2tVZ8SrRNzeFHa4P3IzvSmKhMNfGz60RTyr5rAb/BUmugTQDUZ59Lo67pOzFByRI/boyvGCAli5AdghPf"

// 88060001
#define REMOTE_IM_TOKEN @"WhFxgx2FOYkcl1sXKrOn7QRBMfi1wh6EyS7l6gJfnzYcPu3FzXIauIFJV7YobVSQdI6DgbzWuiM9ejcZrr1ORA=="

@interface ViewController ()<RongRTCP2PTesterDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    BOOL sender = NO;
    NSString * token;
    if (sender) {
        token = RONGCLOUD_IM_TOKEN;
    }
    else{
        token = REMOTE_IM_TOKEN;
    }
    
    [[RCIMClient sharedRCIMClient] initWithAppKey:RONGCLOUD_IM_APPKEY];
    //    [[RCIMClient sharedRCIMClient] useRTCOnly];
    //    [[RCIMClient sharedRCIMClient] setServerInfo:@"http://navxq.rongcloud.net" fileServer:@"xiaxie"];
    [[RCIMClient sharedRCIMClient] connectWithToken:token success:^(NSString *userId) {
        
        
    } error:^(RCConnectErrorCode status) {
        NSLog(@"链接失败了---%@",@(status));
    } tokenIncorrect:^{
        
    }];
    
    if (sender) {
        UIButton * send = [UIButton buttonWithType:UIButtonTypeSystem];
        [send addTarget:self action:@selector(sendButton) forControlEvents:UIControlEventTouchUpInside];
        send.frame = CGRectMake(10, 20, 200, 40);
        send.center = CGPointMake(self.view.frame.size.width/2, 100);
        [send setTitle:@"呼叫" forState:UIControlStateNormal];
        [self.view addSubview:send];
    }
    // 手机作为发送端
    [RongRTCP2PTester sharedTester].delegate = self;
    
}

-(void)didReceiveCall{
    
}

-(void)didConnected{
    
}

-(void)receiveButton{
    
}

-(void)didAddView:(UIView *)render{
    
    [self.view addSubview:render];
    
}

-(void)sendButton{
    
    [[RongRTCP2PTester sharedTester] startCall];
    
}


@end
