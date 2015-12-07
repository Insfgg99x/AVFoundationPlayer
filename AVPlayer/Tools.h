//
//  Tools.h
//  VideoPlayer
//
//  Created by 峰哥哥-.- on 15/12/7.
//  Copyright (c) 2015年 峰哥哥-.-. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



@interface Tools : NSObject
//创建Label
+(UILabel *)createLabelWithFrame:(CGRect)frame text:(NSString *)text textColor:(UIColor *)color textAligment:(NSTextAlignment)aligment andBgColor:(UIColor *)bgColor font:(UIFont *)font;
//创建按钮
+(UIButton *)createBtnWithFrame:(CGRect)frame title:(NSString *)title titleColor:(UIColor *)color target:(id)target action:(SEL)action;

@end
