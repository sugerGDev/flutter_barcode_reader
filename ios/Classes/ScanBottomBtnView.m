//
//  BottomBtnView.m
//  barcode_scan
//
//  Created by lirch on 2020/7/15.
//

#import "ScanBottomBtnView.h"

@interface ScanBottomBtnView()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
/**
 default (90,90)
 */
@property (nonatomic, assign) CGSize itemSize;
//格式 @[@{@"icon":@"",@"title":@""},@{@"icon":@"",@"title":@""}]
@property (nonatomic, strong) NSArray *dataArr;
@property (nonatomic, strong) UICollectionView *mainCollectionView;
@end


@implementation ScanBottomBtnView 
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.itemSize = CGSizeMake(90, 90);
        [self addSubview:self.mainCollectionView];
    }
    return self;
}

- (void)setDataWithArr:(NSArray *)dataArr{
    self.dataArr = dataArr;
    [self.mainCollectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.dataArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ItemCollectionViewCell *cell = [ItemCollectionViewCell cellWithCollectionView:collectionView atIndexPath:indexPath];
    [cell setDataWithDic:self.dataArr[indexPath.row]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (self.btnClickBlock) {
        self.btnClickBlock(indexPath.row);
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat w = self.itemSize.width * self.dataArr.count < self.frame.size.width ? self.itemSize.width * self.dataArr.count : self.frame.size.width;
    self.mainCollectionView.frame = CGRectMake((self.frame.size.width - w) * 0.5, 0, w, self.frame.size.height);
}

- (UICollectionView *)mainCollectionView{
    if (!_mainCollectionView) {
        UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
        flowLayout.itemSize = self.itemSize;
        [flowLayout setScrollDirection:(UICollectionViewScrollDirectionHorizontal)];
        flowLayout.minimumLineSpacing = 0;
        flowLayout.minimumInteritemSpacing = 0;
        _mainCollectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _mainCollectionView.showsVerticalScrollIndicator = NO;
        _mainCollectionView.showsHorizontalScrollIndicator = NO;
        _mainCollectionView.bounces = NO;
        _mainCollectionView.backgroundColor = [UIColor clearColor];
        _mainCollectionView.delegate = self;
        _mainCollectionView.dataSource = self;
        [_mainCollectionView registerClass:[ItemCollectionViewCell class] forCellWithReuseIdentifier:@"ItemCollectionViewCell"];
    }
    return _mainCollectionView;
}

@end





@interface ItemCollectionViewCell()

@property (nonatomic, strong) UIImageView *iconImgV;
@property (nonatomic, strong) UILabel *titleLab;
@end


@implementation ItemCollectionViewCell
+ (ItemCollectionViewCell *)cellWithCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath{
    ItemCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemCollectionViewCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self.contentView addSubview:self.iconImgV];
        [self.contentView addSubview:self.titleLab];
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    self.iconImgV.frame = CGRectMake((self.contentView.frame.size.width - 40) / 2.0, 10, 40, 40);
    self.titleLab.frame = CGRectMake(0, CGRectGetMaxY(self.iconImgV.frame) + 10, self.contentView.frame.size.width, 13);
}

- (void)setDataWithDic:(NSDictionary *)dic{
    self.iconImgV.image = [UIImage imageNamed:dic[@"icon"]];
    self.titleLab.text = dic[@"title"];
}
- (UIImageView *)iconImgV{
    if (!_iconImgV) {
        _iconImgV = [UIImageView new];
        _iconImgV.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _iconImgV;
}

- (UILabel *)titleLab{
    if (!_titleLab) {
        _titleLab = [UILabel new];
        _titleLab.textColor = [UIColor whiteColor];
        _titleLab.font = [UIFont systemFontOfSize:13];
        _titleLab.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLab;
}
@end
