//
//  AppDelegate.m
//  VideoPlayer
//
//  Created by 夏桂峰 on 15/12/7.
//  Copyright (c) 2015年 夏桂峰. All rights reserved.
//

#import "AppDelegate.h"
#import "PlayViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    PlayViewController *player=[[PlayViewController alloc]init];
    
    //HLS协议视屏
    //http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8
    //HTTP视频
    //http://www.modrails.com/videos/passenger_nginx.mov
    
    player.urlString=@"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8";
    player.title=@"播放测试";
    self.window.rootViewController=player;
    
    return YES;
}

@end
