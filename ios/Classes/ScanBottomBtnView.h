//
//  BottomBtnView.h
//  barcode_scan
//
//  Created by lirch on 2020/7/15.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface ScanBottomBtnView : UIView

@property (nonatomic, copy) void(^btnClickBlock)(NSInteger tag);

//格式 @[@{@"icon":@"",@"title":@""},@{@"icon":@"",@"title":@""}]
- (void)setDataWithArr:(NSArray *)dataArr;
@end


@interface ItemCollectionViewCell : UICollectionViewCell
- (void)setDataWithDic:(NSDictionary *)dic;
+ (ItemCollectionViewCell *)cellWithCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath;
@end
NS_ASSUME_NONNULL_END
