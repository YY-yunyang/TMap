//
//  TMapViewController.m
//  TMap
//
//  Created by 张刘洋 on 2018/4/8.
//  Copyright © 2018年 张刘洋. All rights reserved.
//

#import "TMapViewController.h"
#import "SeacherResultTableViewController.h"

#define WScreen [UIScreen mainScreen].bounds.size.width
#define HScreen [UIScreen mainScreen].bounds.size.height
#define HsearchBar self.searchController.searchBar.frame.size.height

#define HMapView (292/667.0*HScreen)
#define NHMapView (HMapView*0.5)

#define YTableView (HsearchBar + HMapView)
#define HTableView (HScreen - ([self hightAboutStatusbarAndNavigationbar] + YTableView))

#define NYTableView (HsearchBar + NHMapView)
#define NHTableView (HScreen - ([self hightAboutStatusbarAndNavigationbar] + NYTableView))

#define TMapCenter CGPointMake(self.mapView.frame.size.width * 0.5, self.mapView.frame.size.height * 0.5 - 16)

#define TTintColor [UIColor colorWithRed:31/255.0 green:185/255.0 blue:34/255.0 alpha:1.0]
#define TBarTintColor [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0]

@interface TMapViewController ()<CLLocationManagerDelegate,UISearchResultsUpdating,UISearchControllerDelegate,UITableViewDelegate,UITableViewDataSource,QMapViewDelegate,QMSSearchDelegate,SeacherResultTableViewControllerDelegete,UISearchBarDelegate>

// 管理定位权限
@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) UISearchController *searchController;
// 地图
@property (nonatomic, strong) QMapView *mapView;
// 地理信息搜索
@property (nonatomic, strong) QMSSearcher *mapSearcher;
// 逆地理编码结果
@property (nonatomic, strong) QMSReverseGeoCodeSearchResult *reGeoResult;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIImageView *redPinImageView;
@property (nonatomic, strong) UIButton *foucsBtn;

// 记录第一次进入地图界面的坐标
@property (nonatomic, assign) CLLocationCoordinate2D userCoordinate2D;
// 记录坐标变化前的最后一次的坐标
@property (nonatomic, assign) CLLocationCoordinate2D lastCoordinate2D;
// 记录查询界面返回的结果
@property (nonatomic, strong) QMSSuggestionPoiData *searcherPoiData;

// 记录被选中的行数
@property (nonatomic, assign) NSInteger selectRow;
// 缓存位移，用于判断是向下偏移还是向下偏移
@property (nonatomic, assign) CGFloat oldOffset;
// 记录地图放缩前的大小
@property (nonatomic, assign) double zoomLevel;
// 用于标记是否是点击cell造成的位移，如果是，则不进行反地理编码操作，默认为NO
@property (nonatomic, assign) BOOL isDidSelectRow;
// 用于标记是否是搜索界面回掉产生的位移，默认为NO
@property (nonatomic, assign) BOOL isSearchResult;
// 用于标记是否是因为拖拽tableView产生的位移
@property (nonatomic, assign) BOOL isDraggingTableView;

@end

@implementation TMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"地图位置选点";
    
    UIBarButtonItem *leftBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleDone target:self action:@selector(clickLeftBarBtn)];
    leftBarBtn.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = leftBarBtn;

    UIBarButtonItem *rightBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"发送" style:UIBarButtonItemStyleDone target:self action:@selector(clickRightBarBtn)];
    rightBarBtn.tintColor = TTintColor;
    self.navigationItem.rightBarButtonItem = rightBarBtn;
    
    self.navigationController.navigationBar.translucent = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self locationManager];
}

- (void)clickLeftBarBtn {
    
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)clickRightBarBtn {
    
    NSString *massageStr;
    if (self.selectRow == 0) {
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        if (self.searcherPoiData != nil) {
            
            massageStr = [NSString stringWithFormat:@"地名:%@\n坐标:<%lf,%lf>\n详细地址:%@",cell.textLabel.text,self.searcherPoiData.location.latitude,self.searcherPoiData.location.longitude,cell.detailTextLabel.text];
        } else {
            
            massageStr = [NSString stringWithFormat:@"地名:%@\n坐标:<%lf,%lf>\n详细地址:%@",self.reGeoResult.formatted_addresses.recommend,self.lastCoordinate2D.latitude,self.lastCoordinate2D.longitude,self.reGeoResult.address];
        }
    } else {
        
        QMSReGeoCodePoi *poi = ((QMSReGeoCodePoi *)self.reGeoResult.poisArray[self.selectRow - 1]);
        massageStr = [NSString stringWithFormat:@"地名:%@\n坐标:<%lf,%lf>\n详细地址:%@",poi.title,poi.location.latitude,poi.location.longitude,poi.address];
    }
    
    // 分享
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"分享你的位置"
                                                                   message:massageStr
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *leftAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault
                                                          handler:nil];
    UIAlertAction *rightAction = [UIAlertAction actionWithTitle:@"发送" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:leftAction];
    [alert addAction:rightAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// 禁止旋转
- (BOOL)shouldAutorotate {
    
    return NO;
}

#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    switch (status) {
            
        case kCLAuthorizationStatusNotDetermined:
            break;
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
        {
            [self showLocationAlert];
        }
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways:
        {
           [self initTMapView];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark ---- QMapView 代理方法区
/* 触发条件：地图显示区域大小发生变化或者拖动地图内容视图 */
- (void)mapView:(QMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    
    self.zoomLevel = self.mapView.zoomLevel;
}
/* 触发条件：地图显示区域大小发生变化或者拖动地图内容视图 */
- (void)mapView:(QMapView *)mapView regionDidChangeAnimated:(BOOL)animated {

    // 如果正在放缩，则不查询
    if (self.mapView.zoomLevel != self.zoomLevel) {return;}
    
    // 如果是点击cell造成的移动，则不查询
    if (self.isDidSelectRow) {
        
        self.isDidSelectRow = NO;
        [self changeFoucsBtnStatusWithCoordinate2D:self.mapView.centerCoordinate];
        return;
    }
    
    // 如果是拖拽tableView产生的位移，不查询
    if (self.isDraggingTableView) {return;}
    
    // 如果不是点击cell造成的移动，则应更新地理信息
    // 如果不是搜索界面造成的位移，则应消除相关数据
    // 如果是搜索界面造成的位移，则应在数据使用后（生成相应的cell后）标记为NO
    if(!self.isSearchResult){
        
        self.searcherPoiData = nil;
    }
    
    // 无效定位数据,不做任何响应
    if (self.lastCoordinate2D.latitude == 0 && self.lastCoordinate2D.longitude == 0) {
        return;
    }
    
    // 如果最后一次有效定位与当前因响应若干因素而返回的坐标不一致，那么就扩大地图显示区域，更新lastCoordinate2D和foucsBtn.selected的状态，需要注意的是：当界面中心地址确为用户地址时状态应为yes
    if (self.lastCoordinate2D.latitude != self.mapView.centerCoordinate.latitude || self.lastCoordinate2D.longitude != self.mapView.centerCoordinate.longitude) {
        
        self.lastCoordinate2D = self.mapView.centerCoordinate;
        [self mapViewBigTableViewSmall];
        [self changeFoucsBtnStatusWithCoordinate2D:self.lastCoordinate2D];
    }
    
    // 配置"经纬度"搜索参数(注：代理方法最多只返回周边十条数据)
    QMSReverseGeoCodeSearchOption *reGeoSearchOption = [[QMSReverseGeoCodeSearchOption alloc] init];
    [reGeoSearchOption setLocationWithCenterCoordinate:self.lastCoordinate2D];
    [reGeoSearchOption setGet_poi:YES];
    [self.mapSearcher searchWithReverseGeoCodeSearchOption:reGeoSearchOption];
}

/// 变更按钮状态
- (void)changeFoucsBtnStatusWithCoordinate2D:(CLLocationCoordinate2D)coordinate2D {
    
    /* 此更新foucsBtn.selected状态的方式要允许存在偏差 */
    CLLocationDegrees latitude = self.userCoordinate2D.latitude - coordinate2D.latitude;
    CLLocationDegrees longitude = self.userCoordinate2D.longitude - coordinate2D.longitude;
    
    if(latitude > -0.00001 && latitude < 0.00001  && longitude > -0.00001 && longitude < 0.00001){
        
        self.foucsBtn.selected = YES;
    } else {
        
        self.foucsBtn.selected = NO;
    }
}

/* 触发条件：定位，返回用户当前位置 */
- (void)mapView:(QMapView *)mapView didUpdateUserLocation:(QUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation {

    self.userCoordinate2D = userLocation.coordinate;
    
    // lastCoordinate2D 第一次出现事应该是用户的定位数据，且此数据只在此处获取一次，后面会在其他位置被其他数据覆盖
    if (self.lastCoordinate2D.latitude == 0 && self.lastCoordinate2D.longitude == 0) {
        self.lastCoordinate2D = userLocation.coordinate;
    }
}

#pragma mark ---- QMSSearch 代理方法区
// 搜索异常
- (void)searchWithSearchOption:(QMSSearchOption *)searchOption didFailWithError:(NSError *)error {
    
    NSLog(@"error:%@", error);
}

// 反地理编码查询结果(经纬度查询位置信息)
- (void)searchWithReverseGeoCodeSearchOption:(QMSReverseGeoCodeSearchOption *)reverseGeoCodeSearchOption didReceiveResult:(QMSReverseGeoCodeSearchResult *)reverseGeoCodeSearchResult {
    
    self.reGeoResult = reverseGeoCodeSearchResult;
    [self mapViewRedPinImageViewAnimate];
    [self.tableView reloadData];
    self.selectRow = 0;
    // 更新数据后应回滚到一个Cell
    NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:self.selectRow inSection:0];
    [self.tableView scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

// 关键词查询结果
- (void)searchWithSuggestionSearchOption:(QMSSuggestionSearchOption *)suggestionSearchOption didReceiveResult:(QMSSuggestionResult *)suggestionSearchResult {
    
    NSLog(@"suggest result:%@", suggestionSearchResult);
    ((SeacherResultTableViewController *)(self.searchController.searchResultsController)).searchBar = self.searchController.searchBar;
    ((SeacherResultTableViewController *)(self.searchController.searchResultsController)).searchController = self.searchController;
    ((SeacherResultTableViewController *)(self.searchController.searchResultsController)).resultArr = [suggestionSearchResult.dataArray mutableCopy];
}

#pragma mark ---- UISearchResultsUpdating(输入内容时触发)
/// 搜索栏内容发生变化时触发
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    if (searchController.searchBar.text.length > 0) {
        
        // 配置"关键词查询"搜索参数
        QMSSuggestionSearchOption *suggetionOption = [[QMSSuggestionSearchOption alloc] init];
        [suggetionOption setKeyword:searchController.searchBar.text];
        
        [self.mapSearcher searchWithSuggestionSearchOption:suggetionOption];
    }
}

- (void)willPresentSearchController:(UISearchController *)searchController {
    
    [UIView animateWithDuration:0.25f animations:^{
        
        [self setPositonAdjustmentWithSearchBar:self.searchController.searchBar isCenter:NO];
    }];
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    
    [UIView animateWithDuration:0.25f animations:^{
        
        [self setPositonAdjustmentWithSearchBar:self.searchController.searchBar isCenter:YES];
    }];
}
#pragma mark ---- UISearchBarDelegate
// 点击键盘搜索按钮
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    if (searchBar.text.length > 0) {
        
        // 配置"关键词查询"搜索参数
        QMSSuggestionSearchOption *suggetionOption = [[QMSSuggestionSearchOption alloc] init];
        [suggetionOption setKeyword:searchBar.text];
        
        [self.mapSearcher searchWithSuggestionSearchOption:suggetionOption];
    }
}

#pragma mark ---- SeacherResultTableViewController 代理方法区
- (void)SeacherResultBlockData:(QMSSuggestionPoiData *)Poi {
    
    self.isSearchResult = YES;
    self.searcherPoiData = Poi;
    self.searchController.searchBar.text = @"";
    [self.searchController.searchBar resignFirstResponder];
    [self.mapView setCenterCoordinate:Poi.location animated:YES];
}

#pragma mark ---- UITableView 代理方法区
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
     return 1 + self.reGeoResult.poisArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 51;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"cellID";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    if (indexPath.row != 0) {
        
        cell.textLabel.text = ((QMSReGeoCodePoi *)self.reGeoResult.poisArray[indexPath.row - 1]).title;
        cell.detailTextLabel.text = ((QMSReGeoCodePoi *)self.reGeoResult.poisArray[indexPath.row - 1]).address;
    } else {
        
        if (self.searcherPoiData == nil) {// 用户当前定位，第一条数据不设置副标题
            
            cell.textLabel.text = self.reGeoResult.formatted_addresses.recommend;
            cell.detailTextLabel.text = @"";
        } else {
            
            if (self.isSearchResult) {
                
                cell.textLabel.text = self.searcherPoiData.title;
                cell.detailTextLabel.text = self.searcherPoiData.address;
                self.isSearchResult = NO;
            } else {
                
                cell.textLabel.text = self.reGeoResult.formatted_addresses.recommend;
                cell.detailTextLabel.text = self.reGeoResult.address;
            }
        }
    }
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.tintColor = TTintColor;
    
    if (self.selectRow == indexPath.row) {
        
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:self.selectRow inSection:0];
    UITableViewCell *tmpCell = [tableView cellForRowAtIndexPath:tmpIndexPath];
    tmpCell.accessoryType = UITableViewCellAccessoryNone;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    self.selectRow = indexPath.row;
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    self.isDidSelectRow = YES;
    if (indexPath.row == 0) {
        
        if (self.searcherPoiData == nil) {
            
            [self.mapView setCenterCoordinate:self.lastCoordinate2D animated:YES];
        } else {
            
            [self.mapView setCenterCoordinate:self.searcherPoiData.location animated:YES];
        }
    } else {
        
        [self.mapView setCenterCoordinate:((QMSReGeoCodePoi *)self.reGeoResult.poisArray[indexPath.row - 1]).location animated:YES];
    }
}

// 开始拖拽视图
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

    self.isDraggingTableView = YES;
}

// 完成拖拽
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
}

// 减速停止时执行，手触摸时执行执行
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

    self.isDraggingTableView = NO;
}

// 拖动过程中触发
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (self.tableView.contentOffset.y < -20) { //地图变大，tableView变小
        
        [self mapViewBigTableViewSmall];
    }
    
    if (self.tableView.contentOffset.y > 0) { //地图变小，tableView变大

        if (self.tableView.contentOffset.y > self.oldOffset) {// 如果当前位移大于缓存位移，说明scrollView向上滑动
            
            [self mapViewSmallTableViewBig];
        }
    }
    // 将当前位移变成缓存位移
    self.oldOffset = self.tableView.contentOffset.y;
}

#pragma mark ---- 动画方法区

/// 地图变大，tableView变小
- (void)mapViewBigTableViewSmall {

    [UIView animateWithDuration:0.5f animations:^{
        
        self.mapView.frame = CGRectMake(0, HsearchBar, WScreen, HMapView);
        self.tableView.frame = CGRectMake(0, YTableView, WScreen, HTableView);
        self.redPinImageView.center = TMapCenter;
        self.foucsBtn.frame = CGRectMake(WScreen - 50 - 10, HMapView - 50 - 20, 50, 50);
    } completion:^(BOOL finished) {
    }];
}

/// 地图变小，tableView变大
- (void)mapViewSmallTableViewBig {
    
    [UIView animateWithDuration:0.5f animations:^{
        
        self.mapView.frame = CGRectMake(0, HsearchBar, WScreen, NHMapView);
        self.tableView.frame = CGRectMake(0, NYTableView, WScreen, NHTableView);
        self.redPinImageView.center = TMapCenter;
        self.foucsBtn.frame = CGRectMake(WScreen - 50 - 10, NHMapView - 50 - 20, 50, 50);
    } completion:^(BOOL finished) {
    }];
}

// 小图钉动画
- (void)mapViewRedPinImageViewAnimate {
    
    [UIView animateKeyframesWithDuration:0.5 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^{
        
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:1 / 2.0 animations:^{
            
            self.redPinImageView.center = CGPointMake(self.mapView.frame.size.width * 0.5, self.mapView.frame.size.height * 0.5 - 16 - 15);
        }];
        
        [UIView addKeyframeWithRelativeStartTime:1 / 2.0 relativeDuration:1 / 2.0 animations:^{
            self.redPinImageView.center = TMapCenter;
        }];
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark ---- 懒加载
- (CLLocationManager *)locationManager {
    
    if (!_locationManager) {
        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
        switch ([CLLocationManager authorizationStatus]) {
                
            case kCLAuthorizationStatusNotDetermined:
            {
                [self.locationManager requestWhenInUseAuthorization];
                
            }
                break;
            case kCLAuthorizationStatusDenied:
            case kCLAuthorizationStatusRestricted:
            {
                [self showLocationAlert];
            }
                break;
            case kCLAuthorizationStatusAuthorizedWhenInUse:
            case kCLAuthorizationStatusAuthorizedAlways:
            {
                [self initTMapView];
            }
                break;
                
            default:
                break;
        }
    }
    return _locationManager;
}

/// 弹窗提示
- (void)showLocationAlert {
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"提示:没有定位权限"
                                                                   message:@"请到设置中授权软件定位权限"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"返回" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                              [self.navigationController popViewControllerAnimated:YES];
                                                          }];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)initTMapView {
    
    [self.view addSubview:self.searchController.searchBar];
    [self mapView];
    [self tableView];
    [self redPinImageView];
    [self foucsBtn];
}

- (UISearchController *)searchController {
    
    if (!_searchController) {
        
        SeacherResultTableViewController *seacherResultTableViewController = [[SeacherResultTableViewController alloc] init];
        _searchController = [[UISearchController alloc] initWithSearchResultsController:seacherResultTableViewController];
        _searchController.searchResultsUpdater = self;
        _searchController.delegate = self;
        ((SeacherResultTableViewController *)(self.searchController.searchResultsController)).SeacherResultDelegate = self;
        _searchController.searchBar.placeholder = @"搜索地点";
        _searchController.searchBar.tintColor = TTintColor;
        _searchController.searchBar.barTintColor = TBarTintColor;
        // 此处去除searchBar底部黑线
        _searchController.searchBar.layer.borderWidth = 1.0;
        _searchController.searchBar.layer.borderColor = TBarTintColor.CGColor;
        _searchController.searchBar.delegate = self;
        [_searchController.searchBar sizeToFit];
        
        [self setPositonAdjustmentWithSearchBar:_searchController.searchBar isCenter:YES];
        
        self.definesPresentationContext = YES;
        [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitle:@"取消"];
    }
    return _searchController;
}

/// 将放大镜和占位字符居中
- (void)setPositonAdjustmentWithSearchBar:(UISearchBar *)searchBar isCenter:(BOOL)isCenter {
    
    if (@available(iOS 11.0, *)) {
        
        if (isCenter) {
            
            [searchBar setPositionAdjustment:UIOffsetMake((WScreen - 32) * 0.5 - [self widthWithdtPlaceholder:searchBar.placeholder] * 0.5,0) forSearchBarIcon:UISearchBarIconSearch];
        } else {
            
            [searchBar setPositionAdjustment:UIOffsetZero forSearchBarIcon:UISearchBarIconSearch];
        }
        // 让动画动起来
        [self.searchController.searchBar setNeedsLayout];
        [self.searchController.searchBar layoutIfNeeded];
    }
}

/// 计算placeholder、icon、间距的总宽度，系统默认字体大小15
- (CGFloat)widthWithdtPlaceholder:(NSString *)placeholder {

    CGSize size = [placeholder boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]} context:nil].size;
    return size.width + 20 + 10;
}

- (QMapView *)mapView {
    
    if (!_mapView) {
        
        // 此处腾讯地图重写了 -initWithFrame: 方法
        _mapView = [[QMapView alloc] initWithFrame:CGRectMake(0, HsearchBar, WScreen, HMapView + self.hightAboutStatusbarAndNavigationbar)];
        NSLog(@"%lf,%lf", WScreen, HMapView);
        _mapView.delegate = self;
        _mapView.showsUserLocation = YES;
        _mapView.userTrackingMode = QUserTrackingModeFollow;
        _mapView.keepCenterEnabled = YES;
        self.userCoordinate2D = CLLocationCoordinate2DMake(0, 0);
        self.lastCoordinate2D = CLLocationCoordinate2DMake(0, 0);
        self.searcherPoiData = nil;
        self.isDidSelectRow = NO;
        self.isSearchResult = NO;
        self.isDraggingTableView = NO;
        [self.view addSubview:_mapView];
        self.mapSearcher = [[QMSSearcher alloc] initWithDelegate:self];
    }
    return _mapView;
}

- (UITableView *)tableView {
    
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, YTableView, WScreen, HTableView) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        self.selectRow = 0;
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

/// 获取状态栏和导航栏的总高度
- (CGFloat)hightAboutStatusbarAndNavigationbar {

    // 获取状态栏的高度
    CGRect rectOfStatusbar = [[UIApplication sharedApplication] statusBarFrame];
    // 获取导航栏的高度
    CGRect rectOfNavigationbar = self.navigationController.navigationBar.frame;
    // 状态栏 + 导航栏
    return rectOfStatusbar.size.height + rectOfNavigationbar.size.height;
}

- (UIImageView *)redPinImageView {
    
    if (!_redPinImageView) {
        _redPinImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 52, 52)];
        _redPinImageView.center = CGPointMake(TMapCenter.x, TMapCenter.y - 32 - 16);
        _redPinImageView.image = [UIImage imageNamed:@"focus_center"];
        [self.mapView addSubview:_redPinImageView];
    }
    return _redPinImageView;
}

- (UIButton *)foucsBtn {
    
    if (!_foucsBtn) {
        
        _foucsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _foucsBtn.frame = CGRectMake(WScreen - 50 - 10, HMapView - 50 - 20, 50, 50);
        [self.mapView addSubview:_foucsBtn];
        _foucsBtn.selected = YES;
        [_foucsBtn setImage:[UIImage imageNamed:@"focus_0"] forState:UIControlStateNormal];
        [_foucsBtn setImage:[UIImage imageNamed:@"focus_1"] forState:UIControlStateSelected];
        [_foucsBtn setImage:[UIImage imageNamed:@"focus_2"] forState:UIControlStateHighlighted];
        [_foucsBtn addTarget:self action:@selector(foucsBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _foucsBtn;
}

- (void)foucsBtnClick:(UIButton *)btn {
    
    if (btn.selected == NO) {
        
        btn.selected = YES;
        self.searcherPoiData = nil;
        [self.mapView setCenterCoordinate:self.userCoordinate2D animated:YES];
    }
}

@end
