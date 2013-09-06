//
//  MosaicLayout.m
//  MosaicCollectionView
//
//  Created by Ezequiel A Becerra on 2/16/13.
//  Copyright (c) 2013 Betzerra. All rights reserved.
//

#import "MosaicLayout.h"

#define kHeightModule 40

@interface MosaicLayout()
-(NSUInteger)shortestColumnIndex;
-(NSUInteger)longestColumnIndex;
-(BOOL)canUseDoubleColumnOnIndex:(NSUInteger)columnIndex;
@end

@implementation MosaicLayout

#pragma mark - Private

-(NSUInteger)shortestColumnIndex{
    NSUInteger retVal = 0;
    CGFloat shortestValue = MAXFLOAT;
    
    NSUInteger i=0;
    for (NSNumber *heightValue in _columns){
        if ([heightValue floatValue] < shortestValue){
            shortestValue = [heightValue floatValue];
            retVal = i;
        }
        i++;
    }
    return retVal;
}

-(NSUInteger)largestColumnIndex{
    NSUInteger retVal = 0;
    CGFloat shortestValue = 0;
    
    NSUInteger i=0;
    for (NSNumber *heightValue in _columns){
        if ([heightValue floatValue] > shortestValue){
            shortestValue = [heightValue floatValue];
            retVal = i;
        }
        i++;
    }
    return retVal;
}

-(NSUInteger)longestColumnIndex{
    NSUInteger retVal = 0;
    CGFloat longestValue = 0;
    
    NSUInteger i=0;
    for (NSNumber *heightValue in _columns){
        if ([heightValue floatValue] > longestValue){
            longestValue = [heightValue floatValue];
            retVal = i;
        }
        i++;
    }
    return retVal;
}

-(BOOL)canUseDoubleColumnOnIndex:(NSUInteger)columnIndex{
    BOOL retVal = NO;

    if (columnIndex < self.columnsQuantity-1){
        float firstColumnHeight = [_columns[columnIndex] floatValue];
        float secondColumnHeight = [_columns[columnIndex+1] floatValue];

        retVal = firstColumnHeight == secondColumnHeight;
    }
    
    return retVal;
}

#pragma mark - Properties

-(NSUInteger) columnsQuantity{
    NSUInteger retVal = [self.delegate numberOfColumnsInCollectionView:self.collectionView];
    return retVal;
}

#pragma mark - Public

-(float)columnWidth{
    float retVal = self.collectionView.bounds.size.width / self.columnsQuantity;
    retVal = roundf(retVal);
    return retVal;
}

#pragma mark UICollectionViewLayout
-(void)prepareLayout{
    
    //  Set all column heights to 0
    _columns = [NSMutableArray arrayWithCapacity:self.columnsQuantity];
    for (NSInteger i = 0; i < self.columnsQuantity; i++) {
        [_columns addObject:@(0)];
    }
    
    //  Get all the items available for the section
    NSUInteger itemsCount = [[self collectionView] numberOfItemsInSection:0];
    _itemsAttributes = [NSMutableArray arrayWithCapacity:itemsCount];
    
    int i = 0;
    NSMutableArray *skippedArray = [NSMutableArray array];
    while ([_itemsAttributes count] != itemsCount) {
        NSIndexPath *indexPath;
        if (arc4random() % 2 == 0 && i < itemsCount) {
            indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            i++;
        } else {
            indexPath = [skippedArray lastObject];
            if ([_itemsAttributes count] + [skippedArray count] == itemsCount) {
                [self normalizeColumns];
            }
            [skippedArray removeLastObject];
            if (!indexPath &&  i < itemsCount) {
                indexPath = [NSIndexPath indexPathForItem:i inSection:0];
                i++;
            }
        }
        
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForIndexPath:indexPath];
        if (attributes) {
            [_itemsAttributes addObject:attributes];
        } else {
            [skippedArray addObject:indexPath];
        }
        
    }
}

-(void)normalizeColumns {
    NSUInteger columnIndex = [self shortestColumnIndex];
    NSUInteger largestColumnIndex = [self largestColumnIndex];
    _columns[columnIndex] = @([_columns[largestColumnIndex] floatValue]);
}

-(UICollectionViewLayoutAttributes *)layoutAttributesForIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes;
    NSUInteger columnIndex = [self shortestColumnIndex];
    NSUInteger xOffset = columnIndex * [self columnWidth];
    NSUInteger yOffset = [[_columns objectAtIndex:columnIndex] integerValue];
    
    NSUInteger itemWidth = 0;
    NSUInteger itemHeight = 0;
    
    float itemRelativeHeight = [self.delegate collectionView:self.collectionView relativeHeightForItemAtIndexPath:indexPath];
    
    if ([self.delegate collectionView:self.collectionView isDoubleColumnAtIndexPath:indexPath]){
        if ([self canUseDoubleColumnOnIndex:columnIndex]) {
            itemWidth = [self columnWidth] * 2;
            itemHeight = itemRelativeHeight * itemWidth;
            itemHeight = itemHeight - (itemHeight % kHeightModule);
            
            _columns[columnIndex] = @(yOffset + itemHeight);
            _columns[columnIndex+1] = @(yOffset + itemHeight);
            attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            attributes.frame = CGRectMake(xOffset, yOffset, itemWidth, itemHeight);
        }
    } else {
        itemWidth = [self columnWidth];
        itemHeight = itemRelativeHeight * itemWidth;
        itemHeight = itemHeight - (itemHeight % kHeightModule);
        
        _columns[columnIndex] = @(yOffset + itemHeight);
        
        attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        attributes.frame = CGRectMake(xOffset, yOffset, itemWidth, itemHeight);
    }
    return attributes;    
}

-(NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{    
    NSPredicate *filterPredicate = [NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes * evaluatedObject, NSDictionary *bindings) {
        BOOL predicateRetVal = CGRectIntersectsRect(rect, [evaluatedObject frame]);
        return predicateRetVal;
    }];
    
    NSArray *retVal = [_itemsAttributes filteredArrayUsingPredicate:filterPredicate];
    return retVal;
}

-(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewLayoutAttributes *retVal = [_itemsAttributes objectAtIndex:indexPath.row];
    return retVal;
}

-(CGSize)collectionViewContentSize{
    CGSize retVal = self.collectionView.bounds.size;
    
    NSUInteger columnIndex = [self longestColumnIndex];
    float columnHeight = [_columns[columnIndex] floatValue];
    retVal.height = columnHeight;
    
    return retVal;
}

@end
