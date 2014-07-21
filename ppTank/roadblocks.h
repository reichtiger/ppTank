//
//  roadblocks.h
//  ppTank
//
//  Created by williamzhao on 14-7-21.
//  Copyright 2014年 williamzhao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface roadblocks : CCNode {
    cpSpace* _space;
    cpConstraint* consWheel;
    CCTexture2D *_spriteTexture; // weak ref
}


// 碉堡，是否带战士
- (void) blockhouseAtPos:(CGPoint)pos withWarrior:(BOOL)hasWarrior;
// 轿车，是否带警察
- (void) carAtPos:(CGPoint)pos withPolice:(BOOL)hasPolice;
// 喀秋莎火箭炮车，带炮弹数目
- (void) bazookaAtPos:(CGPoint)pos withBullet:(int)num;


@end