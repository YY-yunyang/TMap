//
//  ViewController.m
//  TMap
//
//  Created by 张刘洋 on 2018/4/8.
//  Copyright © 2018年 张刘洋. All rights reserved.
//

#import "ViewController.h"
#import "TMapViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *btn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"中转界面";
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.btn];
    [self addConstraint];
    [self addNotificationCenter];
}

- (UIButton *)btn{
    
    if (_btn == nil) {
        
        _btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btn setTitle:@"分享地理位置" forState:UIControlStateNormal];
        _btn.backgroundColor = [UIColor grayColor];
        [_btn addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
        _btn.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _btn;
}

- (void)clickBtn:(UIButton *)btn {
    
    TMapViewController *mapVC = [[TMapViewController alloc] init];
    [self.navigationController pushViewController:mapVC animated:YES];
}

- (void)addConstraint {
    
    [self.view removeConstraints:self.view.constraints];
    
    float SW = self.view.frame.size.width;
    float SH = self.view.frame.size.height;
    
    NSArray *hCons = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-margin-[btn]" options:0 metrics:@{@"margin":@((SW - 120)/2.0)} views:@{@"btn":self.btn}];
    NSArray *vCons = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[btn]" options:0 metrics:@{@"margin":@((SH - 40)/2.0)} views:@{@"btn":self.btn}];
    
    [self.view addConstraints:hCons];
    [self.view addConstraints:vCons];
}

- (void)addNotificationCenter {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationNotification) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)statusBarOrientationNotification {
    
    NSLog(@"屏幕尺寸：%f,%f", self.view.frame.size.height, [UIScreen mainScreen].bounds.size.height);
    [self addConstraint];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
