//
//  PlayViewController.m
//  VideoPlayer
//
//  Created by 峰哥哥-.- on 15/12/7.
//  Copyright (c) 2015年 峰哥哥-.-. All rights reserved.
//

#import "PlayViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Tools.h"
#import "FGGReachability.h"

@interface PlayViewController ()
{
//    MPMoviePlayerViewController *_payeController;
}
@property(nonatomic,strong)AVPlayer *player;
@property(nonatomic,strong)AVPlayerItem *item;
@property(nonatomic,strong)NSString *totalTime;
@property(nonatomic,assign)BOOL isPlaying;
@property(nonatomic,strong)id timeObserver;
@property(nonatomic,strong)UIProgressView *progress;

@property(nonatomic,strong)UISlider *slider;      //进度slider
@property(nonatomic,strong)UISlider *volumeSlider;//音量slider

@property(nonatomic,strong)UIButton *playBtn;
@property(nonatomic,strong)UILabel *timeLabel;
@property(nonatomic,strong)id playbackTimeObserver;

//快进
@property(nonatomic,strong)UIImageView *forward;
//快退
@property(nonatomic,strong)UIImageView *backward;

@property(nonatomic,strong)UILabel *volumeLabel;//调节音量时显示当前音量
@property(nonatomic,strong)UIButton *shareBtn;//分享

//加载指示器
@property(nonatomic,strong)UIActivityIndicatorView *indicator;

//判断网络
@property(nonatomic,strong)Reachability *reach;


@end

#define kWidth ([UIScreen mainScreen].bounds.size.width)
#define kHeight ([UIScreen mainScreen].bounds.size.height)

@implementation PlayViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    隐藏导航栏
    self.navigationController.navigationBarHidden=YES;
}
-(void)showIndicator
{
    _indicator=[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _indicator.center=CGPointMake(kHeight/2, kWidth/2);
    [self.view addSubview:_indicator];
    [_indicator startAnimating];
}
//隐藏状态栏
- (BOOL)prefersStatusBarHidden
{
    return YES;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor blackColor];
    //显示网络记载指示器
    [self showIndicator];
    NSLog(@"\n-->%@\n-->%@",self.urlString,self.videoTitle);
    
    //通知中心注册一条监听网络状态的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(estimateNetworkStatus) name:kReachabilityChangedNotification object:nil];
    _reach=[Reachability reachabilityForInternetConnection];
    [_reach startNotifier];
    
    [self estimateNetworkStatus];
    
    _item=[[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:self.urlString]];
    _player=[[AVPlayer alloc]initWithPlayerItem:_item];
    
    [_item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];// 监听status属性
    [_item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];// 监听loadedTimeRanges属性
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_item];
    
    AVPlayerLayer *layer=[AVPlayerLayer playerLayerWithPlayer:_player];
    layer.videoGravity=AVLayerVideoGravityResizeAspect;
    layer.frame=CGRectMake(0, 0, kHeight, kWidth);
    layer.backgroundColor=[UIColor clearColor].CGColor;
    
    [self.view.layer addSublayer:layer];
    
    //    标题
    [self createTitleView];
    //    界面
    [self createUI];
    
    //旋转视图
    //self.view.transform=CGAffineTransformMakeRotation(3*M_PI_2);
    //layer.transform=CATransform3DMakeRotation(M_PI/2, 0, 0, 1);
    self.view.layer.transform=CATransform3DMakeRotation(3*M_PI_2, 0, 0, 1);
    
    [self addGestures];

}
/**
 *  添加手势
 */
-(void)addGestures
{
    //添加一个手势 隐藏与显示进度条
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(shiftStatus)];
    [self.view addGestureRecognizer:tap];
    
    //增加音量的手势
    UISwipeGestureRecognizer *increaseGesture=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(increaseVolume:)];
    increaseGesture.direction=UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:increaseGesture];
    
    //减小音量的手势
    UISwipeGestureRecognizer *decreaseGesture=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(decreaseVolume:)];
    decreaseGesture.direction=UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:decreaseGesture];
    
    //快进
    UISwipeGestureRecognizer *stepForward=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(stepForward10Seconds)];
    stepForward.direction=UISwipeGestureRecognizerDirectionRight;
    //快退
    UISwipeGestureRecognizer *stepBackward=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(stepBackward10Senconds)];
    stepBackward.direction=UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:stepForward];
    [self.view addGestureRecognizer:stepBackward];
}
/**
 *  评估网络状态
 */
-(void)estimateNetworkStatus
{
    FGGNetWorkStatus status=[FGGReachability networkStatus];
    if(status==FGGNetWorkStatusNotReachable)
    {
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"提示"
                                                     message:@"当前网络不可用"
                                                    delegate:nil
                                           cancelButtonTitle:@"知道了"
                                           otherButtonTitles:nil, nil];
        [alert show];
    }
    else if(status!=FGGNetWorkStatusWifi)
    {
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"提示"
                                                     message:@"非Wifi环境播放视屏会耗费流量！"
                                                    delegate:nil
                                           cancelButtonTitle:@"知道了"
                                           otherButtonTitles:nil, nil];
        [alert show];
    }
}
/**
 *  向上滑动增加音量
 *
 *  @param sender 滑动手势
 */
-(void)increaseVolume:(UISwipeGestureRecognizer *)sender
{
    if(sender.direction==UISwipeGestureRecognizerDirectionUp)
    {
        if(_player.volume>=1.0)
            return;
        _player.volume+=0.1;
//        NSLog(@"+++++音量:%f++++++",10*_player.volume);
    
        __weak PlayViewController *weakSelf=self;
        _volumeLabel.text=[NSString stringWithFormat:@"音量:%d",(int)ceilf(_player.volume*10)];
        [UIView animateWithDuration:0.2 animations:^{
            weakSelf.volumeLabel.alpha=1.0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                weakSelf.volumeLabel.alpha=0.0;
            }];
        }];
    }
}
/**
 *  向下滑动减小音量
 *
 *  @param sender 滑动手势对象
 */
-(void)decreaseVolume:(UISwipeGestureRecognizer *)sender
{
    if(sender.direction==UISwipeGestureRecognizerDirectionDown)
    {
        if(_player.volume<=0.0)
            return;
        _player.volume-=0.1;
//        NSLog(@"------音量:%f------",10*_player.volume);
    
        __weak PlayViewController *weakSelf=self;
        _volumeLabel.text=[NSString stringWithFormat:@"音量:%d",(int)ceilf(_player.volume*10)];
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.volumeLabel.alpha=1.0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                weakSelf.volumeLabel.alpha=0.0;
            }];
        }];
    }
}
#pragma mark -
#pragma mark - 快退快进
//@qustion:seekToTime和seekToTime:toleranceBefore:toleranceAfter的区别是什么？
//快进10秒
-(void)stepForward10Seconds
{
    if(_isPlaying)
    {
        [_item seekToTime:CMTimeMakeWithSeconds(_item.currentTime.value/_item.currentTime.timescale+10, _item.currentTime.timescale) toleranceBefore:CMTimeMake(1, _item.currentTime.timescale) toleranceAfter:CMTimeMake(1, _item.currentTime.timescale)];
        __weak typeof(self) weakSelf=self;
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.forward.alpha=1.0;
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                weakSelf.forward.alpha=0.0;
            }];
        }];
    }
}
//快退10秒
-(void)stepBackward10Senconds
{
    if(_isPlaying)
    {
        [_item seekToTime:CMTimeMakeWithSeconds(_item.currentTime.value/_item.currentTime.timescale-10, _item.currentTime.timescale)];
        __weak typeof(self) weakSelf=self;
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.backward.alpha=1.0;
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                weakSelf.backward.alpha=0.0;
            }];
        }];
    }
}
//界面
-(void)createUI
{
    _playBtn=[[UIButton alloc]initWithFrame:CGRectMake(50, 20, 60, 40)];
    [_playBtn setTitle:@"Play" forState:UIControlStateNormal];
    [_playBtn setTitle:@"Pause" forState:UIControlStateSelected];
    [_playBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _playBtn.titleLabel.font=[UIFont boldSystemFontOfSize:16];
    [_playBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [_playBtn addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    _playBtn.backgroundColor=[UIColor clearColor];
    [self.view  addSubview:_playBtn];
    _progress=[[UIProgressView alloc]initWithFrame:CGRectMake(110, 41, kHeight-230, 2)];
    //    设置轨道颜色，将要走到的路径的颜色
    _progress.trackTintColor=[UIColor whiteColor];
    //    设置进度颜色,已经走过的路径
    _progress.progressTintColor=[UIColor blueColor];
    
    _slider=[[UISlider alloc]initWithFrame:CGRectMake(110, 26,kHeight-230, 31)];
    [_slider setThumbImage:[UIImage imageNamed:@"thumb"] forState:UIControlStateNormal];
    _slider.minimumTrackTintColor=[UIColor blueColor];//设置左边颜色
    _slider.maximumTrackTintColor=[UIColor clearColor];//设置右边颜色
    _slider.continuous=NO;
    [_slider addTarget:self action:@selector(sliderDidSlided:) forControlEvents:UIControlEventValueChanged];
    
    
    [self.view addSubview:_progress];
    [self.view addSubview:_slider];
    
    _timeLabel=[Tools createLabelWithFrame:CGRectMake(kHeight-130, 30, 110, 20) text:nil textColor:[UIColor whiteColor] textAligment:NSTextAlignmentRight andBgColor:[UIColor clearColor] font:[UIFont systemFontOfSize:14]];
    _timeLabel.text=@"--:--/--:--";
    [self.view addSubview:_timeLabel];
    
    //    音量label
    _volumeLabel=[[UILabel alloc]initWithFrame:CGRectMake(kHeight-100, kWidth/2-20, 80, 40)];
    _volumeLabel.text=[NSString stringWithFormat:@"音量:%d",(int)ceil(_player.volume)*10];
    _volumeLabel.alpha=0.0;
    _volumeLabel.backgroundColor=[UIColor clearColor];
    _volumeLabel.font=[UIFont boldSystemFontOfSize:22];
    _volumeLabel.textColor=[UIColor whiteColor];
    [self.view addSubview:_volumeLabel];
    
    //快进
    _forward=[[UIImageView alloc]initWithFrame:CGRectMake(kHeight-164, kWidth/2-32, 64, 64)];
    _forward.image=[UIImage imageNamed:@"stepforward"];
    [self.view addSubview:_forward];
    _forward.alpha=0.0;
    
    //快退
    _backward=[[UIImageView alloc]initWithFrame:CGRectMake(100, kWidth/2-32, 64, 64)];
    _backward.image=[UIImage imageNamed:@"stepbackward"];
    [self.view addSubview:_backward];
    _backward.alpha=0.0;
}

//标题视图
-(void)createTitleView
{
    UILabel *titleLabel=[Tools createLabelWithFrame:CGRectMake(50, 10, kHeight-100, 20) text:self.videoTitle textColor:[UIColor whiteColor] textAligment:NSTextAlignmentCenter andBgColor:[UIColor clearColor] font:[UIFont boldSystemFontOfSize:12]];
    [self.view addSubview:titleLabel];
    titleLabel.tag=111;
    
    //    返回按钮
    UIButton *backBtn=[[UIButton alloc]initWithFrame:CGRectMake(10, 20, 40, 40)];
    [backBtn setBackgroundImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
}
//返回
-(void)backAction
{
    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 *  滑动进度条时执行该方法
 *
 *  @param sender slider对象
 */
-(void)sliderDidSlided:(UISlider *)sender
{
    if(_player.status==AVPlayerStatusReadyToPlay)
    {
        CGFloat value=sender.value;
        [_item seekToTime:CMTimeMake(value, 1)];
    }
}
//隐藏上方的条条
-(void)hideStatusLabels
{
    __weak PlayViewController *weakSelf=self;
    
    if(!_isPlaying)
        return;
    UILabel *label=(UILabel *)[self.view viewWithTag:111];
    [UIView animateWithDuration:0.5 animations:^{
//        自动播放视频
        [weakSelf.player play];
        weakSelf.isPlaying=YES;
        
        label.alpha=0;
        weakSelf.timeLabel.alpha=0;
        weakSelf.slider.alpha=0;
        weakSelf.progress.alpha=0;
        weakSelf.playBtn.alpha=0;
    } completion:^(BOOL finished) {
        
    }];
}
//显示上方的条条
-(void)showStatusLabels
{
    __weak PlayViewController *weakSelf=self;
    
    UILabel *label=(UILabel *)[self.view viewWithTag:111];
    
    [UIView animateWithDuration:0.5 animations:^{
        
        weakSelf.timeLabel.alpha=1;
        weakSelf.slider.alpha=1;
        weakSelf.progress.alpha=1;
        weakSelf.playBtn.alpha=1;
        label.alpha=1;
    } completion:^(BOOL finished) {
    
    }];
}
//手势点击屏幕触发的方法
-(void)shiftStatus
{
    if(_playBtn.alpha==0)
    {
//        显示上方条条
       [self performSelector:@selector(showStatusLabels) withObject:nil];
//        6秒后 自动隐藏上方条条
        [self performSelector:@selector(hideStatusLabels) withObject:nil afterDelay:6];
    }
    else
//        隐藏条条
        [self performSelector:@selector(hideStatusLabels) withObject:nil];
    
}
/**
 *  点击播放按钮时执行的方法
 *
 *  @param sender 播放按钮
 */
-(void)playAction:(UIButton *)sender
{
    sender.selected=!sender.isSelected;
    if(_isPlaying)
    {
        [_player pause];
    }
    else
    {
        [_player play];
    }
    _isPlaying=!_isPlaying;
}
/**
 *  收到播放完毕的通知时执行该方法
 *
 *  @param notification 通知
 */
- (void)moviePlayDidEnd:(NSNotification *)notification
{
    NSLog(@"Play end");
    [_player seekToTime:kCMTimeZero completionHandler:^(BOOL finished)
     {
        [self updateVideoSlider:0.0];
        [_playBtn setTitle:@"Play" forState:UIControlStateNormal];
    }];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{

    AVPlayerItem *playerItem = (AVPlayerItem *)object;

    if ([keyPath isEqualToString:@"status"])
    {
    
        if ([playerItem status] == AVPlayerStatusReadyToPlay)
        {
          
            NSLog(@"AVPlayerStatusReadyToPlay");
//            开始播放视频
            [_player play];
//            播放状态置为YES
            _isPlaying=YES;
            _playBtn.selected=YES;
//            隐藏上方的条条
            [self hideStatusLabels];
//            隐藏加载指示器
            [_indicator stopAnimating];
            [_indicator removeFromSuperview];
            
            CMTime duration = _item.duration;// 获取视频总长度
    
            CGFloat totalSecond = playerItem.duration.value / playerItem.duration.timescale;// 转换成秒
          
            _totalTime = [self convertTime:totalSecond];// 转换成播放时间
          
            [self customVideoSlider:duration];
          
            NSLog(@"movie total duration:%f",CMTimeGetSeconds(duration));
         
            [self monitoringPlayback:_item];// 监听播放状态
        
        }
        else if ([playerItem status] == AVPlayerStatusFailed)
        {
            //移除网络加载指示器
            [_indicator stopAnimating];
            [_indicator removeFromSuperview];
            //NSLog(@"AVPlayerStatusFailed");
            UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"提示" message:@"加载失败" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
            [alert show];
            [alert dismissWithClickedButtonIndex:0 animated:YES];
        }
    
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
     
        NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
     
//        NSLog(@"Time Interval:%f",timeInterval);
    
        CMTime duration = _item.duration;
     
        CGFloat totalDuration = CMTimeGetSeconds(duration);
//      设置进度处理器的进度值
        [_progress setProgress:timeInterval / totalDuration animated:YES];
    
    }
}
/**
 *  获取缓冲总进度
 *
 *  @return 缓冲总进度
 */
- (NSTimeInterval)availableDuration
{
  
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
  
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
   
    float startSeconds = CMTimeGetSeconds(timeRange.start);
   
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
  
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度

    return result;
}
/**
 *  将视频播放的当前时间和总时间，格式化显示在界面上
 *
 *  @param second 播放器的当前时间
 *
 *  @return 格式化后的显示时间
 */
- (NSString *)convertTime:(CGFloat)second
{
  
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
  
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
 
    if (second/3600 >= 1)
    {
       
        [formatter setDateFormat:@"HH:mm:ss"];
      
    }
    else
    {
       
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:d];
   
    return showtimeNew;
}

- (void)monitoringPlayback:(AVPlayerItem *)playerItem
{
    __weak PlayViewController  *weakSelf=self;
    
    self.playbackTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time)
    {
        CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;// 计算当前在第几秒
        [weakSelf updateVideoSlider:currentSecond];
        NSString *timeString = [weakSelf convertTime:currentSecond];
        weakSelf.timeLabel.text = [NSString stringWithFormat:@"%@/%@",timeString,weakSelf.totalTime];
    }];
}
- (void)customVideoSlider:(CMTime)duration
{
 
    _slider.maximumValue = CMTimeGetSeconds(duration);
 
    UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
 
    UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [_slider setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
    [_slider setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
}
/**
 *  更行滑块的值
 *
 *  @param currentSecond 当前的播放时间
 */
- (void)updateVideoSlider:(CGFloat)currentSecond
{
    [_slider setValue:currentSecond animated:YES];
}
/**
 *  视图即将消失时移除观察者对象，注销通知，如果播放器在播放，让其暂停，让播放器指向nil
 *
 *  @param animated 动画效果
 */
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_item removeObserver:self forKeyPath:@"status" context:nil];
    [_item removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_item];
    [_player removeTimeObserver:self.playbackTimeObserver];
    if(_isPlaying)
    {
        [_player pause];
        _player=nil;
    }
}

@end
