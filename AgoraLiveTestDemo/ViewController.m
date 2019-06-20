//
//  ViewController.m
//  AgoraLiveTestDemo
//
//  Created by 1 on 2019/6/20.
//  Copyright © 2019 1. All rights reserved.
//

#import "ViewController.h"
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>
#import "LiveRoomViewController.h"

#define appid @"8b8a9cf5393f4d459d8830ceccdf31f3"
#define snaptoken @"0068b8a9cf5393f4d459d8830ceccdf31f3IABHXQV6zBio4Xu3VMWUUBXuZJcuUWd9gzP1b3IBRksc820lkvIAAAAAEABMR5saxFcIXQEAAQDDVwhd"


@interface ViewController ()<AgoraRtcEngineDelegate>
@property(nonatomic,strong)AgoraRtcEngineKit * agoraKit;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:appid delegate:self];
}


- (IBAction)clickaction:(UIButton *)sender {
    LiveRoomViewController *liveroomvc = [[LiveRoomViewController alloc]init];
    [self presentViewController:liveroomvc animated:YES completion:nil];
}

@end
