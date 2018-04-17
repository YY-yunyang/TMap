//
//  SeacherResultTableViewController.m
//  TMap
//
//  Created by 张刘洋 on 2018/4/9.
//  Copyright © 2018年 张刘洋. All rights reserved.
//

#import "SeacherResultTableViewController.h"

@interface SeacherResultTableViewController ()

@end

@implementation SeacherResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotate {
    
    return NO;
}

- (void)setResultArr:(NSMutableArray<QMSSuggestionPoiData *> *)resultArr {
    
    _resultArr = resultArr;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, self.searchBar.frame.size.height)];
    [self.tableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.resultArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"seacherCell";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = self.resultArr[indexPath.row].title;
    cell.detailTextLabel.text = self.resultArr[indexPath.row].address;
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([_SeacherResultDelegate respondsToSelector:@selector(SeacherResultBlockData:)]) {

        [_SeacherResultDelegate SeacherResultBlockData:self.resultArr[indexPath.row]];
    }
    
    // 界面跳转方式选择
    // 推出搜索结果界面
    if(_searchController) {
        
        _searchController.active = NO;
    } else {
        
        // 跳转方式
    }
}

@end
