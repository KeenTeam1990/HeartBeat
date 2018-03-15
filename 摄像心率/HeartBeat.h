//
//  HeartBeat.h
//  摄像心率
//
//  Created by xiekang on 17/3/24.
//  Copyright © 2017年 ZM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef enum{
   heartBeatTypeHeartRate = 100,
    
   heartBeatTypeOxygen = 101,
    
   heartBeatTypeBloodPressure,
    
   heartBeatTypelungCapcity


}heartBeatType;


static float lastH = 0;


static int count = 0;
@protocol HeartBeatPluginDelegate <NSObject>

- (void)startHeartDelegateRatePoint:(NSDictionary *)point heartType:(heartBeatType)type;
@optional
- (void)startHeartDelegateRateError:(NSError *)error;
- (void)startHeartDelegateRateFrequency:(NSInteger)frequency;
@end



@interface HeartBeat : NSObject


@property (assign,nonatomic) heartBeatType type;

@property(copy,nonatomic) void (^backPoint)(NSDictionary *);

@property(copy,nonatomic) void (^frendency)(NSInteger);

@property(copy,nonatomic) void (^Error)(NSError *);

@property (strong,nonatomic) AVCaptureDevice *device;

@property (strong,nonatomic) AVCaptureSession *session;

@property (strong,nonatomic) AVCaptureInput *input;

@property (assign, nonatomic) id <HeartBeatPluginDelegate> delegate;


@property (strong,nonatomic) AVCaptureVideoDataOutput *output;


@property (strong,nonatomic) NSMutableArray *points;

+ (instancetype)shareManager;

-(void)start;


-(void)stop;
@end
