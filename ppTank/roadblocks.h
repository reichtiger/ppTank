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
+ (id) blockhouseAtPos:(cpSpace*)space pos:(CGPoint)pos withWarrior:(BOOL)hasWarrior;
- (id) initWithBlockhouse:(cpSpace*)space pos:(CGPoint)pos withWarrior:(BOOL)hasWarrior;

// 轿车，是否带警察
+ (id) carAtPos:(cpSpace*)space pos:(CGPoint)pos withPolice:(BOOL)hasPolice;
- (id) initWithCar:(cpSpace*)space pos:(CGPoint)pos withPolice:(BOOL)hasPolice;
// 喀秋莎火箭炮车，带炮弹数目
+ (id) bazookaAtPos:(cpSpace*)space pos:(CGPoint)pos withBullet:(int)num;
- (id) initWithBazooka:(cpSpace*)space pos:(CGPoint)pos withBullet:(int)num;

@end
