//
//  LiveRoomViewController.h
//  AgoraLiveDemo
//
//  Created by 1 on 2019/6/19.
//  Copyright © 2019 1. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveRoomViewController : UIViewController
@property (copy, nonatomic) NSString *roomName;
@property (strong, nonatomic) AgoraRtcEngineKit *rtcEngine;
@property (assign, nonatomic) AgoraClientRole clientRole;
@property (assign, nonatomic) CGSize videoProfile;
@end

NS_ASSUME_NONNULL_END
