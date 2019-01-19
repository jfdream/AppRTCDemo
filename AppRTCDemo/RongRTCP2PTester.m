//
//  RongRTCP2PTester.m
//  RongRTCLib
//
//  Created by jfdreamyang on 2019/1/16.
//  Copyright © 2019 Bailing Cloud. All rights reserved.
//

#import "RongRTCP2PTester.h"
#import <RongIMLib/RongIMLib.h>
#import <WebRTC/WebRTC.h>
#import "RTCSessionDescription+JSON.h"
#import "RTCICECandidate+JSON.h"
#import "ARDCaptureController.h"

@interface RongRTCP2PTester()<RCIMClientReceiveMessageDelegate,RTCPeerConnectionDelegate,RTCDataChannelDelegate,RTCVideoViewDelegate>
{
    RTCPeerConnection * _pc;
    RTCDataChannel * _dc;
    BOOL caller;
//    RTCManualVideoSource * _videoSource;
//    RTCCameraVideoCapturer * capturer;
    RTCPeerConnectionFactory * _factory;
    RTCDataChannelConfiguration * dataChannelConfiguration;
    
    RTCVideoSource * _videoSource;
    
    ARDCaptureController * capture;
    RTCVideoTrack * track;
}
@property (nonatomic,strong)dispatch_queue_t workQueue;
@end


@implementation RongRTCP2PTester
+(RongRTCP2PTester *)sharedTester{
    static RongRTCP2PTester * _tester = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _tester = [[self alloc]init];
        _tester.workQueue = dispatch_queue_create("helloccc", DISPATCH_QUEUE_SERIAL);
        [[RCIMClient sharedRCIMClient] setReceiveMessageDelegate:_tester object:nil];
    });
    
    return _tester;
    
}

-(void)onReceived:(RCMessage *)message left:(int)nLeft object:(id)object{
    
    RCTextMessage * msg = (RCTextMessage *)message.content;
    NSString * s = msg.content;
    
    NSData * info = [s dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary * sdpInfo = [NSJSONSerialization JSONObjectWithData:info options:NSJSONReadingMutableContainers error:nil];
    
    if ([sdpInfo[@"type"] isEqualToString:@"sdp"]) {
        // sdp
        if (!caller) {
            [self createPC];
            
            NSDictionary *mandatoryConstraints = @{
                                                   @"OfferToReceiveAudio" : @"true",
                                                   @"OfferToReceiveVideo" : @"true"
                                                   };
            RTCMediaConstraints *cons = [[RTCMediaConstraints alloc]initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:nil];
            __weak typeof(RTCPeerConnection *) weakPc = _pc;
            __weak typeof(self) weakSelf = self;
            
            RTCSessionDescription * sdp = [RTCSessionDescription descriptionFromJSONDictionary:sdpInfo[@"info"]];
            [_pc setRemoteDescription:sdp completionHandler:^(NSError * _Nullable error) {
                
            }];
            
            [_pc answerForConstraints:cons completionHandler:^(RTCSessionDescription * _Nullable oosdp, NSError * _Nullable error) {
                [weakPc setLocalDescription:oosdp completionHandler:^(NSError * _Nullable error) {
                    
                }];
                [weakSelf didSetSDP:oosdp];
            }];
        }
        else{
            RTCSessionDescription * sdp = [RTCSessionDescription descriptionFromJSONDictionary:sdpInfo[@"info"]];
            [_pc setRemoteDescription:sdp completionHandler:^(NSError * _Nullable error) {
                
            }];
        }
    }
    else{
        // candidate
        RTCIceCandidate * candiate = [RTCIceCandidate candidateFromJSONDictionary:sdpInfo[@"info"]];
        [_pc addIceCandidate:candiate];
    }
    
}

-(void)startCall{
    caller = YES;
    
    dispatch_async(self.workQueue, ^{
         [self _startCall];
    });
    
   
}

-(void)createPC{
   
    RTCDefaultVideoDecoderFactory *decoderFactory = [[RTCDefaultVideoDecoderFactory alloc] init];// 视频解码工厂
    NSArray * supportedCodecs = [RTCDefaultVideoEncoderFactory supportedCodecs];
    RTCDefaultVideoEncoderFactory *encoderFactory = [[RTCDefaultVideoEncoderFactory alloc] init];// 视频编码工厂
    encoderFactory.preferredCodec = supportedCodecs.lastObject;
    _factory = [[RTCPeerConnectionFactory alloc] initWithEncoderFactory:encoderFactory decoderFactory:decoderFactory];
    
    RTCConfiguration * config = [[RTCConfiguration alloc]init];
    
    RTCIceServer * ice = [[RTCIceServer alloc]initWithURLStrings:@[@"stun:39.106.53.53:3478"] username:nil credential:nil];
    config.iceServers = @[ice];
    
    RTCMediaConstraints * cons = [[RTCMediaConstraints alloc]initWithMandatoryConstraints:@{} optionalConstraints:@{}];
    _pc = [_factory peerConnectionWithConfiguration:config constraints:cons delegate:self];
    
    RTCMediaStream * ms = [_factory mediaStreamWithStreamId:@"88060000"];
    if (caller) {
        _videoSource = [_factory videoSource];
        RTCVideoTrack * track = [_factory videoTrackWithSource:(RTCVideoSource *)_videoSource trackId:@"demo"];
        [ms addVideoTrack:track];
        
        RTCAudioTrack * a = [_factory audioTrackWithTrackId:@"hello"];
        [ms addAudioTrack:a];
        
        RTCCameraVideoCapturer * capturer = [[RTCCameraVideoCapturer alloc]initWithDelegate:_videoSource];
        
        capture = [[ARDCaptureController alloc]initWithCapturer:capturer];
        [capture startCapture];
    }
    [_pc addStream:ms];
    
}

//- (void)onCaptureSampleBuffer:(CMSampleBufferRef)sampleBuffer rotation:(int)rotation{
//    [_videoSource captureSampleBuffer:sampleBuffer rotation:rotation];
//}
//- (void)captureSampleBuffer:(CMSampleBufferRef)sampleBuffer rotation:(int)rotation{
//
//}
-(void)_startCall{
    
    [self createPC];
    
    NSDictionary *mandatoryConstraints = @{
                                           @"OfferToReceiveAudio" : @"true",
                                           @"OfferToReceiveVideo" : @"true"
                                           };
    RTCMediaConstraints *cons = [[RTCMediaConstraints alloc]initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:nil];
    __weak typeof(RTCPeerConnection *) weakPc = _pc;
    __weak typeof(self) weakSelf = self;
    [_pc offerForConstraints:cons completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        [weakPc setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
            
        }];
        [weakSelf didSetSDP:sdp];
    }];
    
//    NSDictionary * candidate1 = @{@"candidate":@"candidate:1986231479 1 tcp 1518280447 10.13.10.121 58762 typ host tcptype passive generation 0 ufrag J5uI network-id 1 network-cost 10",@"id":@"video",@"label":@(1),@"type":@"candidate"};
//
//    NSDictionary * candidate2 = @{@"candidate":@"candidate:1986231479 1 tcp 1518280447 10.13.10.121 58758 typ host tcptype passive generation 0 ufrag J5uI network-id 1 network-cost 10",@"id":@"audio",@"label":@(0),@"type":@"candidate"};
//
//    NSDictionary * candidate3 = @{@"candidate":@"candidate:1986231479 1 tcp 1518280447 10.13.10.121 58758 typ host tcptype passive generation 0 ufrag J5uI network-id 1 network-cost 10",@"id":@"audio",@"label":@(0),@"type":@"candidate"};
    
}

-(void)didSetSDP:(RTCSessionDescription *)SDP{
    if (caller) {
        NSDictionary * sdp = [SDP JSONDictionary];
        NSMutableDictionary * ss = [@{@"type":@"sdp",@"info":sdp} mutableCopy];
        NSData * jsonSdp = [NSJSONSerialization dataWithJSONObject:ss options:NSJSONWritingPrettyPrinted error:nil];
        NSString * s = [[NSString alloc]initWithData:jsonSdp encoding:NSUTF8StringEncoding];
        RCTextMessage *message = [RCTextMessage messageWithContent:s];
        [[RCIMClient sharedRCIMClient] sendMessage:ConversationType_PRIVATE targetId:@"88060001" content:message pushContent:nil pushData:nil success:^(long messageId) {
            NSLog(@"success=======>%ld",messageId);
        } error:^(RCErrorCode nErrorCode, long messageId) {
            
        }];
    }
    else{
        NSDictionary * sdp = [SDP JSONDictionary];
        NSMutableDictionary * ss = [@{@"type":@"sdp",@"info":sdp} mutableCopy];
        NSData * jsonSdp = [NSJSONSerialization dataWithJSONObject:ss options:NSJSONWritingPrettyPrinted error:nil];
        NSString * s = [[NSString alloc]initWithData:jsonSdp encoding:NSUTF8StringEncoding];
        RCTextMessage *message = [RCTextMessage messageWithContent:s];
        [[RCIMClient sharedRCIMClient] sendMessage:ConversationType_PRIVATE targetId:@"88060000" content:message pushContent:nil pushData:nil success:^(long messageId) {
            NSLog(@"success=======>%ld",messageId);
        } error:^(RCErrorCode nErrorCode, long messageId) {
            
        }];
    }
    
}
/** The data channel state changed. */
- (void)dataChannelDidChangeState:(RTCDataChannel *)dataChannel{
    //NSLog(@"===========>%ld",dataChannel.readyState);
    if (dataChannel.readyState == RTCDataChannelStateOpen) {
        NSData * s = [@"yangyudong" dataUsingEncoding:NSUTF8StringEncoding];
        RTCDataBuffer * buffer = [[RTCDataBuffer alloc]initWithData:s isBinary:NO];
        [dataChannel sendData:buffer];
    }
}
/** The data channel successfully received a data buffer. */
- (void)dataChannel:(RTCDataChannel *)dataChannel
didReceiveMessageWithBuffer:(RTCDataBuffer *)buffer{
    NSLog(@"===============>%@",buffer);
}

/** Called when the SignalingState changed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeSignalingState:(RTCSignalingState)stateChanged{
    
}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
          didAddStream:(RTCMediaStream *)stream{
    
    if (stream.videoTracks.count>0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            track = stream.videoTracks.firstObject;
            RTCEAGLVideoView * view = [[RTCEAGLVideoView alloc]initWithFrame:CGRectMake(30, 300, 320, 180)];
            view.delegate = self;
            [track addRenderer:view];
            [self.delegate didAddView:view];
        });
    }
}

-(void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size{
    NSLog(@"=======>%@",NSStringFromCGSize(size));
}

/** Called when a remote peer closes a stream. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       didRemoveStream:(RTCMediaStream *)stream{
    
}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection{
    
}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState{
    
    if (newState == RTCIceConnectionStateConnected) {
//        dataChannelConfiguration = [[RTCDataChannelConfiguration alloc]init];
//        dataChannelConfiguration.channelId = 3;
//        dataChannelConfiguration.isOrdered = YES;
//        dataChannelConfiguration.isNegotiated = NO;
//        _dc = [_pc dataChannelForLabel:@"88060000" configuration:dataChannelConfiguration];
//        _dc.delegate = self;

    }
    
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState{
    
}

/** New ice candidate has been found. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate{
    
    if (caller) {
        NSDictionary * sdp = [candidate JSONDictionary];
        NSLog(@"======>%@",sdp);
        NSMutableDictionary * ss = [@{@"type":@"candidate",@"info":sdp} mutableCopy];
        NSData * jsonSdp = [NSJSONSerialization dataWithJSONObject:ss options:NSJSONWritingPrettyPrinted error:nil];
        NSString * s = [[NSString alloc]initWithData:jsonSdp encoding:NSUTF8StringEncoding];
        RCTextMessage *message = [RCTextMessage messageWithContent:s];
        [[RCIMClient sharedRCIMClient] sendMessage:ConversationType_PRIVATE targetId:@"88060001" content:message pushContent:nil pushData:nil success:^(long messageId) {
            NSLog(@"success=======>%ld",messageId);
        } error:^(RCErrorCode nErrorCode, long messageId) {
            
        }];
    }
    else{
        NSDictionary * sdp = [candidate JSONDictionary];
        NSMutableDictionary * ss = [@{@"type":@"candidate",@"info":sdp} mutableCopy];
        NSData * jsonSdp = [NSJSONSerialization dataWithJSONObject:ss options:NSJSONWritingPrettyPrinted error:nil];
        NSString * s = [[NSString alloc]initWithData:jsonSdp encoding:NSUTF8StringEncoding];
        RCTextMessage *message = [RCTextMessage messageWithContent:s];
        [[RCIMClient sharedRCIMClient] sendMessage:ConversationType_PRIVATE targetId:@"88060000" content:message pushContent:nil pushData:nil success:^(long messageId) {
            NSLog(@"success=======>%ld",messageId);
        } error:^(RCErrorCode nErrorCode, long messageId) {
            
        }];
    }
    
    
}

/** Called when a group of local Ice candidates have been removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates{
    
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel{
    
}

-(void)sendMessage:(NSDictionary *)message{
    
}

@end
