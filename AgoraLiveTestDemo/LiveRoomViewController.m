//
//  LiveRoomViewController.m
//  AgoraLiveDemo
//
//  Created by 1 on 2019/6/19.
//  Copyright © 2019 1. All rights reserved.
//

#import "LiveRoomViewController.h"
#import "VideoSession.h"
#import "VideoViewLayouter.h"

@interface LiveRoomViewController ()<AgoraRtcEngineDelegate>

@property (nonatomic,strong)UIView *remoteContainerView;
@property (strong, nonatomic) NSMutableArray<VideoSession *> *videoSessions;
@property (strong, nonatomic) VideoSession *fullSession;
@property (strong, nonatomic) VideoViewLayouter *viewLayouter;
@property (assign, nonatomic) NSUInteger highPriorityRemoteUid;
@property (assign, nonatomic) BOOL isEnableSuperResolution;
@property (assign, nonatomic) BOOL shouldEnhancer;

@end


@implementation LiveRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
 
    self.remoteContainerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 500, 500)];
    self.remoteContainerView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.remoteContainerView];
    
    
    self.videoSessions = [[NSMutableArray alloc] init];
    
    
    [self loadAgoraKit];
    
}


- (BOOL)isBroadcaster {
    return self.clientRole == AgoraClientRoleBroadcaster;
}

- (VideoViewLayouter *)viewLayouter {
    if (!_viewLayouter) {
        _viewLayouter = [[VideoViewLayouter alloc] init];
    }
    return _viewLayouter;
}

- (void)setClientRole:(AgoraClientRole)clientRole {
    _clientRole = clientRole;
    
    if (self.isBroadcaster) {
        self.shouldEnhancer = YES;
    }
}



- (void)setVideoSessions:(NSMutableArray<VideoSession *> *)videoSessions {
    _videoSessions = videoSessions;
    if (self.remoteContainerView) {
        [self updateInterfaceWithAnimation:YES];
    }
}



- (void)setFullSession:(VideoSession *)fullSession {
    _fullSession = fullSession;
    if (self.remoteContainerView) {
        [self updateInterfaceWithAnimation:YES];
    }
}

- (void)setIsEnableSuperResolution:(BOOL)isEnableSuperResolution {
    _isEnableSuperResolution = isEnableSuperResolution;
    
}

- (void)setHighPriorityRemoteUid:(NSUInteger)highPriorityRemoteUid {
    _highPriorityRemoteUid = highPriorityRemoteUid;
    for (VideoSession *session in self.videoSessions) {
        [self.rtcEngine enableRemoteSuperResolution:session.uid enabled:NO];
        [self.rtcEngine setRemoteUserPriority:session.uid type:AgoraUserPriorityNormal];
    }
    if (highPriorityRemoteUid != 0) {
        if (self.isEnableSuperResolution) {
            [self.rtcEngine enableRemoteSuperResolution:highPriorityRemoteUid enabled:YES];
        }
        [self.rtcEngine setRemoteUserPriority:highPriorityRemoteUid type:AgoraUserPriorityHigh];
    }
}


- (void)setIdleTimerActive:(BOOL)active {
    [UIApplication sharedApplication].idleTimerDisabled = !active;
}

- (void)alertString:(NSString *)string {
    if (!string.length) {
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:string preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateInterfaceWithAnimation:(BOOL)animation {
    if (animation) {
        [UIView animateWithDuration:0.3 animations:^{
            [self updateInterface];
            [self.view layoutIfNeeded];
        }];
    } else {
        [self updateInterface];
    }
}

- (void)updateInterface {
    NSArray *displaySessions;
    if (!self.isBroadcaster && self.videoSessions.count) {
        displaySessions = [self.videoSessions subarrayWithRange:NSMakeRange(1, self.videoSessions.count - 1)];
    } else {
        displaySessions = [self.videoSessions copy];
    }
    
    [self.viewLayouter layoutSessions:displaySessions fullSession:self.fullSession inContainer:self.remoteContainerView];
    [self setStreamTypeForSessions:displaySessions fullSession:self.fullSession];
    self.highPriorityRemoteUid = [self highPriorityRemoteUidInSessions:displaySessions fullSession:self.fullSession];
}

- (void)setStreamTypeForSessions:(NSArray<VideoSession *> *)sessions fullSession:(VideoSession *)fullSession {
    if (fullSession) {
        for (VideoSession *session in sessions) {
            if (session == self.fullSession) {
                [self.rtcEngine setRemoteVideoStream:fullSession.uid type:AgoraVideoStreamTypeHigh];
            } else {
                [self.rtcEngine setRemoteVideoStream:session.uid type:AgoraVideoStreamTypeLow];
            }
        }
    } else {
        for (VideoSession *session in sessions) {
            [self.rtcEngine setRemoteVideoStream:session.uid type:AgoraVideoStreamTypeHigh];
        }
    }
}
 
- (void)addLocalSession {
    VideoSession *localSession = [VideoSession localSession];
    [self.videoSessions addObject:localSession];
    [self.rtcEngine setupLocalVideo:localSession.canvas];
    [self updateInterfaceWithAnimation:YES];
}

- (VideoSession *)fetchSessionOfUid:(NSUInteger)uid {
    for (VideoSession *session in self.videoSessions) {
        if (session.uid == uid) {
            return session;
        }
    }
    return nil;
}

- (VideoSession *)videoSessionOfUid:(NSUInteger)uid {
    VideoSession *fetchedSession = [self fetchSessionOfUid:uid];
    if (fetchedSession) {
        return fetchedSession;
    } else {
        VideoSession *newSession = [[VideoSession alloc] initWithUid:uid];
        [self.videoSessions addObject:newSession];
        [self updateInterfaceWithAnimation:YES];
        return newSession;
    }
}

- (NSUInteger)highPriorityRemoteUidInSessions:(NSArray<VideoSession *> *)sessions fullSession:(VideoSession *)fullSession {
    if (fullSession) {
        return fullSession.uid;
    } else {
        return sessions.lastObject.uid;
    }
}

//MARK: - Agora Media SDK
- (void)loadAgoraKit {
    self.rtcEngine.delegate = self;
    [self.rtcEngine setChannelProfile:AgoraChannelProfileLiveBroadcasting];
    
    // Warning: only enable dual stream mode if there will be more than one broadcaster in the channel
    [self.rtcEngine enableDualStreamMode:YES];
    
    [self.rtcEngine enableVideo];
    
    AgoraVideoEncoderConfiguration *configuration =
    [[AgoraVideoEncoderConfiguration alloc] initWithSize:self.videoProfile
                                               frameRate:AgoraVideoFrameRateFps24
                                                 bitrate:AgoraVideoBitrateStandard
                                         orientationMode:AgoraVideoOutputOrientationModeAdaptative];
    [self.rtcEngine setVideoEncoderConfiguration:configuration];
    
    [self.rtcEngine setClientRole:self.clientRole];
    
    if (self.isBroadcaster) {
        [self.rtcEngine startPreview];
    }
    
    [self addLocalSession];
    
    int code = [self.rtcEngine joinChannelByToken:@"0068b8a9cf5393f4d459d8830ceccdf31f3IABHXQV6zBio4Xu3VMWUUBXuZJcuUWd9gzP1b3IBRksc820lkvIAAAAAEABMR5saxFcIXQEAAQDDVwhd" channelId:@"clsaaroomshengzhi" info:nil uid:0 joinSuccess:nil];
    if (code == 0) {
        [self setIdleTimerActive:NO];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertString:[NSString stringWithFormat:@"Join channel failed: %d", code]];
        });
    }
    
    if (self.isBroadcaster) {
        self.shouldEnhancer = YES;
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    VideoSession *userSession = [self videoSessionOfUid:uid];
    [self.rtcEngine setupRemoteVideo:userSession.canvas];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstLocalVideoFrameWithSize:(CGSize)size elapsed:(NSInteger)elapsed {
    if (self.videoSessions.count) {
        [self updateInterfaceWithAnimation:NO];
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason {
    VideoSession *deleteSession;
    for (VideoSession *session in self.videoSessions) {
        if (session.uid == uid) {
            deleteSession = session;
        }
    }
    
    if (deleteSession) {
        [self.videoSessions removeObject:deleteSession];
        [deleteSession.hostingView removeFromSuperview];
        [self updateInterfaceWithAnimation:YES];
        
        if (deleteSession == self.fullSession) {
            self.fullSession = nil;
        }
    }
}



//MARK: - vc
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}


@end
