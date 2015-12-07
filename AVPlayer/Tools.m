//
//  Tools.m
//  VideoPlayer
//
//  Created by 峰哥哥-.- on 15/12/7.
//  Copyright (c) 2015年 峰哥哥-.-. All rights reserved.
//

#import "Tools.h"

@implementation Tools


//创建Label
+(UILabel *)createLabelWithFrame:(CGRect)frame text:(NSString *)text textColor:(UIColor *)color textAligment:(NSTextAlignment)aligment andBgColor:(UIColor *)bgColor font:(UIFont *)font
{
    UILabel *lb=[[UILabel alloc]initWithFrame:frame];
    lb.text=text;
    lb.textColor=color;
    lb.textAlignment=aligment;
    lb.backgroundColor=bgColor;
    lb.font=font;
    return lb;
}
//创建按钮
+(UIButton *)createBtnWithFrame:(CGRect)frame title:(NSString *)title titleColor:(UIColor *)color target:(id)target action:(SEL)action
{
    UIButton *btn=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.frame=frame;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:color forState:UIControlStateNormal];
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    btn.titleLabel.font=[UIFont boldSystemFontOfSize:12];
    btn.backgroundColor=[UIColor whiteColor];
    return btn;
}

@end
