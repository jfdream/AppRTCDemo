//
//  RongRTCP2PTester.h
//  RongRTCLib
//
//  Created by jfdreamyang on 2019/1/16.
//  Copyright © 2019 Bailing Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol RongRTCP2PTesterDelegate <NSObject>

-(void)didReceiveCall;
-(void)didConnected;
-(void)didAddView:(UIView *)render;

@end


NS_ASSUME_NONNULL_BEGIN

@interface RongRTCP2PTester : NSObject
+(RongRTCP2PTester *)sharedTester;
@property (nonatomic,weak)id <RongRTCP2PTesterDelegate> delegate;
-(void)startCall;
-(void)sendMessage:(NSDictionary *)message;
@end

NS_ASSUME_NONNULL_END
