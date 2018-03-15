//
//  ViewController.m
//  摄像心率
//
//  Created by xiekang on 17/3/23.
//  Copyright © 2017年 ZM. All rights reserved.
//

#import "ViewController.h"
#import "HeartBeat.h"
#import "HeartLive.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()<HeartBeatPluginDelegate>

@property (strong, nonatomic) HeartLive *live;
@property (strong, nonatomic) UILabel *label;

@property (strong,nonatomic) NSTimer *timer;
@end
static int counts = 0;
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(reapTime) userInfo:nil repeats:YES];
    
    
    
   // for (int i = 0; i<3; i++) {
        //创建了一个心电图的View
        self.live = [[HeartLive alloc]initWithFrame:CGRectMake(10, 100, self.view.frame.size.width-20, 150)];
        [self.view addSubview:self.live];
        
        self.label = [[UILabel alloc]initWithFrame:CGRectMake(0, 300, self.view.frame.size.width, 30)];
        self.label.layer.borderColor = [UIColor blackColor].CGColor;
        self.label.layer.borderWidth = 1;
        self.label.textColor = [UIColor blackColor];
        self.label.font = [UIFont systemFontOfSize:28];
        self.label.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:self.label];
        
        //开启测心率方法
        [HeartBeat shareManager].delegate = self;
        [HeartBeat shareManager].type = heartBeatTypeOxygen;
        [[HeartBeat shareManager] start];
    
    
        [[HeartBeat shareManager] stop];

    //}
    
    
}

-(void)reapTime
{

    counts++;
    


}


#pragma mark - 测心率回调

- (void)startHeartDelegateRatePoint:(NSDictionary *)point heartType:(heartBeatType)type;{
    NSNumber *n = [[point allValues] firstObject];
    //拿到的数据传给心电图View
    [self.live drawRateWithPoint:n];
    //NSLog(@"%@",point);
}

- (void)startHeartDelegateRateError:(NSError *)error {
    NSLog(@"%@",error);
}

- (void)startHeartDelegateRateFrequency:(NSInteger)frequency {
    NSLog(@"\n瞬时心率：%ld",frequency);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.label.text = [NSString stringWithFormat:@"%ld",(long)frequency];
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
