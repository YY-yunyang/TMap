//
//  MyNavigationController.m
//  TMap
//
//  Created by 张刘洋 on 2018/4/10.
//  Copyright © 2018年 张刘洋. All rights reserved.
//

#import "MyNavigationController.h"

@interface MyNavigationController ()

@end

@implementation MyNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// 控制屏幕是否旋转
- (BOOL)shouldAutorotate {
    
    return [self.viewControllers.lastObject shouldAutorotate];
}

//- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//
//    return UIInterfaceOrientationMaskPortrait;
//}

//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
//
//    return [self.viewControllers.lastObject preferredInterfaceOrientationForPresentation];
//}

@end
