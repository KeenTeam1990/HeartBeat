# HeartBeat
手机检测心率血压
 //创建了一个心电图的View
 self.live = [[HeartLive alloc]initWithFrame:CGRectMake(10, 100, self.view.frame.size.width-20, 150)];
 [self.view addSubview:self.live];
 
 - (void)startHeartDelegateRatePoint:(NSDictionary *)point {
    NSNumber *n = [[point allValues] firstObject];
    //拿到的数据传给心电图View
    [self.live drawRateWithPoint:n];
 }
 */


#pragma mark - 测心率回调

- (void)startHeartDelegateRatePoint:(NSDictionary *)point {
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
        self.label.text = [NSString stringWithFormat:@"%ld次/分",(long)frequency];
    });
}

# 展示图
![项目结构图](https://github.com/KeenTeam1990/HeartBeat/blob/master/heart/a.PNG)
