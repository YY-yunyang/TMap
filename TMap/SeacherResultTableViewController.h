//
//  SeacherResultTableViewController.h
//  TMap
//
//  Created by 张刘洋 on 2018/4/9.
//  Copyright © 2018年 张刘洋. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SeacherResultTableViewControllerDelegete <NSObject>

/*
 *@brief 用于获取搜索界面的择值
 *
 *@param Poi 位置的具体信息，包含名字、经纬度等
 */
- (void)SeacherResultBlockData:(QMSSuggestionPoiData *)Poi;

@end

@interface SeacherResultTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray<QMSSuggestionPoiData *> *resultArr;
@property (nonatomic, weak) id<SeacherResultTableViewControllerDelegete> SeacherResultDelegate;
@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, weak) UISearchController *searchController;

@end
