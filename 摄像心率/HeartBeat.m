//
//  HeartBeat.m
//  摄像心率
//
//  Created by xiekang on 17/3/24.
//  Copyright © 2017年 ZM. All rights reserved.
//

#import "HeartBeat.h"
static HeartBeat *plugin = nil;

// 周期
static float T = 10;



@implementation HeartBeat

- (instancetype)init {
    
    if (self = [super init]) {
        // 初始化
        self.device     = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        self.session    = [[AVCaptureSession alloc]init];
        self.input      = [[AVCaptureDeviceInput alloc]initWithDevice:self.device error:nil];
        self.output     = [[AVCaptureVideoDataOutput alloc]init];
        self.points     = [[NSMutableArray alloc]init];
    }
    return self;
}

+ (instancetype)shareManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        plugin = [[self alloc]init];
    });
    return plugin;
}

- (void)startHeartRatePoint:(void(^)(NSDictionary *point))backPoint
                  Frequency:(void(^)(NSInteger fre))frequency
                      Error:(void(^)(NSError *error))error {
    self.backPoint = backPoint;
    self.frendency
    = frequency;
    self.Error = error;
    [self start];
}

#pragma mark - 开始

- (void)start {
    [self createDevice];
    [self.session startRunning];
}

#pragma mark - 结束

- (void)stop {
    count = 0;
    lastH = 0;
   
    [self.points removeAllObjects];
    [self.session stopRunning];
}
-(void)createDevice
{
    
//    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSString *media = AVMediaTypeVideo;
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:media];
    
    if (authStatus  == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        NSString *error = @"相机不可用";
        
        NSError *err = [NSError errorWithDomain:error code:100 userInfo:@{@"content":@""}];
        
        
        
        
        
        if (self.backPoint)
            self.Error(err);
        if ([self.delegate respondsToSelector:@selector(startHeartDelegateRateError:)])
            [self.delegate startHeartDelegateRateError:err];
        
        return;
    }
    
    // 开启闪光灯
    if ([self.device isTorchModeSupported:AVCaptureTorchModeOn]) {
        [self.device lockForConfiguration:nil];
        // 开启闪光灯
        self.device.torchMode=AVCaptureTorchModeOn;
        // 调低闪光灯亮度
        [self.device setTorchModeOnWithLevel:0.01 error:nil];
        [self.device unlockForConfiguration];
    }
     [self.session beginConfiguration];
    
    // 设置像素输出格式
    NSNumber *BGRA32Format = [NSNumber numberWithInt:kCVPixelFormatType_32BGRA];
    NSDictionary *setting  =@{(id)kCVPixelBufferPixelFormatTypeKey:BGRA32Format};
    [self.output setVideoSettings:setting];
    // 抛弃延迟的帧
    [self.output setAlwaysDiscardsLateVideoFrames:YES];
    //开启摄像头采集图像输出的子线程
    dispatch_queue_t outputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    // 设置子线程执行代理方法
    [self.output setSampleBufferDelegate:self queue:outputQueue];
    
    // 向session添加
    if ([self.session canAddInput:self.input])   [self.session addInput:self.input];
    if ([self.session canAddOutput:self.output]) [self.session addOutput:self.output];
    
    // 降低分辨率，减少采样率
    self.session.sessionPreset = AVCaptureSessionPreset640x480;
    // 设置最小的视频帧输出间隔
    self.device.activeVideoMinFrameDuration = CMTimeMake(1, 10);
    
    // 用当前的output 初始化connection
    AVCaptureConnection *connection =[self.output connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    // 完成编辑
    [self.session commitConfiguration];

}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;
{

    //获取图层缓冲
    CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    uint8_t*buf = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    float r = 0, g = 0,b = 0;
    float h,s,v;
    // 计算RGB
    TORGB(buf, width, height, bytesPerRow, &r, &g, &b);
    // RGB转HSV
    RGBtoHSV(r, g, b, &h, &s, &v);
    float p = 0;
    // 获取当前时间戳（精确到毫秒）
    double t = [[NSDate date] timeIntervalSince1970]*1000;
    // 返回处理后的浮点值
    
    
    if (_type == heartBeatTypeHeartRate) {
       p =  HeartRate(h);
    }
    else if (_type == heartBeatTypeOxygen){
    
        /*血氧*/
       p =  r;

    
    }
    else if (_type == heartBeatTypeBloodPressure){
        
        
        
    }

    else {
        
        
        
    }

    
    
    
      // 绑定浮点和时间戳
    NSDictionary *point = @{[NSNumber numberWithDouble:t]:[NSNumber numberWithFloat:p]};
    
    NSLog(@"RGB:---%f-%f-%f-%f---%f---%f-%f",r,g,b,h,s,v,p);
    
    // 范围之外
    if (p >= 1.0f || p<= -1.0f) {
      
        NSString *errStr = @"请将手指覆盖住后置摄像头和闪光灯";
        NSError *err = [NSError errorWithDomain: errStr code:101 userInfo:@{@"content":errStr}];
        if (self.Error)
            self.Error(err);
        if ([self.delegate respondsToSelector:@selector(startHeartDelegateRateError:)])
            [self.delegate startHeartDelegateRateError:err];
        
        // 清除数据
        count = 0;
        lastH = 0;
        [self.points removeAllObjects];
        
    } else {
      
        // Block回调方法
        if (self.backPoint)
            self.backPoint(point);
        // 代理回调方法
        if ([self.delegate respondsToSelector:@selector(startHeartDelegateRatePoint: heartType:)])
            
        {
            [self.delegate startHeartDelegateRatePoint:point heartType:_type];
        }
        
        // 分析波峰波谷
        [self analysisPointsWith:point];
    }




}


- (void)analysisPointsWith:(NSDictionary *)point {
    
    [self.points addObject:point];
    if (self.points.count<=30) return;
    int count = (int)self.points.count;
    
    if (self.points.count%10 == 0) {
        
        int d_i_c = 0;          //最低峰值的位置 姑且算在中间位置 c->center
        int d_i_l = 0;          //最低峰值左面的最低峰值位置 l->left
        int d_i_r = 0;          //最低峰值右面的最低峰值位置 r->right
        
        
        float trough_c = 0;     //最低峰值的浮点值
        float trough_l = 0;     //最低峰值左面的最低峰值浮点值
        float trough_r = 0;     //最低峰值右面的最低峰值浮点值
        
        // 1.先确定数据中的最低峰值
        for (int i = 0; i < count; i++) {
            float trough = [[[self.points[i] allObjects] firstObject] floatValue];
            if (trough < trough_c) {
                trough_c = trough;
                d_i_c = i;
            }
        }
        // 2.找到最低峰值以后  以最低峰值为中心 找到前0.5-1.5周期中的最低峰值  和后0.5-1.5周期的最低峰值
        if (d_i_c >= 1.5*T) {
            
            // a.如果最低峰值处在中心位置， 即距离前后都至  少有1.5个周期
            if (d_i_c <= count-1.5*T) {
                // 左面最低峰值
                for (int j = d_i_c - 0.5*T; j > d_i_c - 1.5*T; j--) {
                    float trough = [[[self.points[j] allObjects] firstObject] floatValue];
                    if ((trough < trough_l)&&(d_i_c-j)<=T) {
                        trough_l = trough;
                        d_i_l = j;
                    }
                }
                // 右面最低峰值
                for (int k = d_i_c + 0.5*T; k < d_i_c + 1.5*T; k++) {
                    float trough = [[[self.points[k] allObjects] firstObject] floatValue];
                    if ((trough < trough_r)&&(k-d_i_c<=T)) {
                        trough_r = trough;
                        d_i_r = k;
                    }
                }
                
            }
            // b.如果最低峰值右面不够1.5个周期 分两种情况 不够0.5个周期和够0.5个周期
            else {
                // b.1 够0.5个周期
                if (d_i_c <count-0.5*T) {
                    // 左面最低峰值
                    for (int j = d_i_c - 0.5*T; j > d_i_c - 1.5*T; j--) {
                        float trough = [[[self.points[j] allObjects] firstObject] floatValue];
                        if ((trough < trough_l)&&(d_i_c-j)<=T) {
                            trough_l = trough;
                            d_i_l = j;
                        }
                    }
                    // 右面最低峰值
                    for (int k = d_i_c + 0.5*T; k < count; k++) {
                        float trough = [[[self.points[k] allObjects] firstObject] floatValue];
                        if ((trough < trough_r)&&(k-d_i_c<=T)) {
                            trough_r = trough;
                            d_i_r = k;
                        }
                    }
                }
                // b.2 不够0.5个周期
                else {
                    // 左面最低峰值
                    for (int j = d_i_c - 0.5*T; j > d_i_c - 1.5*T; j--) {
                        float trough = [[[self.points[j] allObjects] firstObject] floatValue];
                        if ((trough < trough_l)&&(d_i_c-j)<=T) {
                            trough_l = trough;
                            d_i_l = j;
                        }
                    }
                }
            }
            
        }
        // c. 如果左面不够1.5个周期 一样分两种情况  够0.5个周期 不够0.5个周期
        else {
            // c.1 够0.5个周期
            if (d_i_c>0.5*T) {
                // 左面最低峰值
                for (int j = d_i_c - 0.5*T; j > 0; j--) {
                    float trough = [[[self.points[j] allObjects] firstObject] floatValue];
                    if ((trough < trough_l)&&(d_i_c-j)<=T) {
                        trough_l = trough;
                        d_i_l = j;
                    }
                }
                // 右面最低峰值
                for (int k = d_i_c + 0.5*T; k < d_i_c + 1.5*T; k++) {
                    float trough = [[[self.points[k] allObjects] firstObject] floatValue];
                    if ((trough < trough_r)&&(k-d_i_c<=T)) {
                        trough_r = trough;
                        d_i_r = k;
                    }
                }
                
            }
            // c.2 不够0.5个周期
            else {
                // 右面最低峰值
                for (int k = d_i_c + 0.5*T; k < d_i_c + 1.5*T; k++) {
                    float trough = [[[self.points[k] allObjects] firstObject] floatValue];
                    if ((trough < trough_r)&&(k-d_i_c<=T)) {
                        trough_r = trough;
                        d_i_r = k;
                    }
                }
            }
            
        }
        /*
         2路信号合相加  vs sum  =  红光累加  开平方 平方和
         ir sum  红外光  累加
         
         110-25*R    R为平均功率
         
         */
        // 3. 确定哪一个与最低峰值更接近 用最接近的一个最低峰值测出瞬时心率 60*1000两个峰值的时间差------心率   发现色相H随脉搏的变化很明显
        if (trough_l-trough_c < trough_r-trough_c) {
            
            NSDictionary *point_c = self.points[d_i_c];
            NSDictionary *point_l = self.points[d_i_l];
            double t_c =0;
            
            double t_l = 0;
            
            NSInteger fre = 0;
            
            if (_type == heartBeatTypeHeartRate) {
                t_c = [[[point_c allKeys] firstObject] doubleValue];//   平方和开方----
                t_l = [[[point_l allKeys] firstObject] doubleValue];
                fre = (NSInteger)(60*1000)/(t_c - t_l);//由脉搏周期换成脉率 60000/sample_count  采样计数

            }
            else if (_type == heartBeatTypeOxygen){
                
                t_c = [[[point_c allValues] firstObject] doubleValue];//   平方和开方----
                t_l = [[[point_l allValues] firstObject] doubleValue];
                fre = (NSInteger)100*t_c;//(110-(25*t_c));//由脉搏周

                
            }
            else if (_type == heartBeatTypeBloodPressure){
                
                
                
            }
            
            else {
                
                
                
            }
            

            
                       NSLog(@"t_c--%f--------%ld",t_c,(long)fre);
            NSLog(@"t_c--%f-----%f---%ld",t_c,100*t_c,(long)fre);
            
            
            if (self.frendency)
                self.frendency(fre);
            if ([self.delegate respondsToSelector:@selector(startHeartDelegateRateFrequency:)])
                [self.delegate startHeartDelegateRateFrequency:fre];
        } else {
            NSDictionary *point_c = self.points[d_i_c];
            NSDictionary *point_r = self.points[d_i_r];
            
            double t_c =0;
            
            double t_r = 0;
            
            NSInteger fre = 0;

            
            if (_type == heartBeatTypeHeartRate) {
                
                double t_c = [[[point_c allKeys] firstObject] doubleValue];
                double t_r = [[[point_r allKeys] firstObject] doubleValue];
                fre = (NSInteger)(60*1000)/(t_r - t_c); //  脉率的计算
    
            }
            else if (_type == heartBeatTypeOxygen){
                
                t_c = [[[point_c allValues] firstObject] doubleValue];
                 t_r = [[[point_r allValues] firstObject] doubleValue];
                fre =  (NSInteger)100*t_c;//(110-(25*t_c)); //  脉率的计算   100
                
            }
            else if (_type == heartBeatTypeBloodPressure){
                
                
                
            }
            
            else {
                
                
                
            }

            
            
           
            NSLog(@"t_c--%f-----%f---%ld",t_c,100*t_c,(long)fre);//t_c--1490580177917.419922--------85
            
            if (self.frendency)
                self.frendency(fre);
            if ([self.delegate respondsToSelector:@selector(startHeartDelegateRateFrequency:)])
                [self.delegate startHeartDelegateRateFrequency:fre];
        }
        // 4.删除过期数据
        for (int i = 0; i< 10; i++) {
            [self.points removeObjectAtIndex:0];
        }
    }
}
#pragma mark - 根据h返回 浮点

float HeartRate (float h) {
    float low = 0;
    count++;
    lastH = (count==1)?h:lastH;
    low = (h-lastH);
    lastH = h;
    return low;
}

#pragma mark - 计算RGB

void TORGB (uint8_t *buf, float ww, float hh, size_t pr, float *r, float *g, float *b) {
    
    float wh = (float)(ww * hh );
    for(int y = 0; y < hh; y++) {
        for(int x = 0; x < ww * 4; x += 4) {
            *b += buf[x];
            *g += buf[x+1];
            *r += buf[x+2];
        }
        buf += pr;
    }
    *r /= 255 * wh;
    *g /= 255 * wh;
    *b /= 255 * wh;
}


#pragma mark --- 获取颜色变化的算法

void RGBtoHSV( float r, float g, float b, float *h, float *s, float *v ) {
    float min, max, delta;
    min = MIN( r, MIN(g, b ));
    max = MAX( r, MAX(g, b ));
    *v = max;
    delta = max - min;
    if( max != 0 )
        *s = delta / max;
    else {
        *s = 0;
        *h = -1;
        return;
    }
    if( r == max )
        *h = ( g - b ) / delta;
    else if( g == max )
        *h = 2 + (b - r) / delta;
    else
        *h = 4 + (r - g) / delta;
    *h *= 60;
    if( *h < 0 )
        *h += 360;
}
@end
