//
//  trackNode
//  cpTank
//
//  Created by williamzhao on 14-6-17.
//  Copyright 2014年 williamzhao. All rights reserved.
//
/**
 *
 *  a Track of tank is segments connected one by one and with some segments rotated in some angle.
 *
    so , we define an array of angle as input , then connect those segments one by one
 *
 *
 */

#import <Foundation/Foundation.h>
#import "cocos2d.h"


enum COLLISION_TYPE {
    COLLISION_TYPE_BULLET = 1,
    COLLISION_TYPE_STONE = 2,
    COLLISION_TYPE_TRACK = 3,
    COLLISION_TYPE_OUTLINE = 4,
    COLLISION_TYPE_WHEEL = 5,
};

#define             TANK_WHEEL_MAX_SPEED            12.0f

@interface trackNode : CCNode {
    cpSpace* _space;
    cpConstraint* consWheel;
    CCTexture2D *_spriteTexture; // weak ref
	
}

/**
 *  use each segment pivot point as start to assemble link between two bodies
 *
 */

+ (id)connectBodiesWithPoints:(cpSpace*)space
                  parentLayer:(CCLayer*)parentLayer
                  connectMode:(int)connectMode
                          num:(int)num
                       points:(cpVect*)points
                    thickness:(cpFloat)thickness
                        bodyA:(cpBody*)bodyA
                        bodyB:(cpBody*)bodyB
                      anchorA:(CGPoint)anchorA
                      anchorB:(CGPoint)anchorB;

- (id)initWithPoints:(cpSpace*)space
         parentLayer:(CCLayer*)parentLayer
         connectMode:(int)connectMode
                 num:(int)num
              points:(cpVect*)points
           thickness:(cpFloat)thickness
               bodyA:(cpBody*)bodyA
               bodyB:(cpBody*)bodyB
             anchorA:(CGPoint)anchorA
             anchorB:(CGPoint)anchorB;


/**
 *  use each segment pivot point as start to assemble link between two bodies
 *
 */

+ (id)connectWithCenterPoint:(cpSpace*)space
                 parentLayer:(CCLayer*)parentLayer
                         num:(int)num
                      points:(cpVect*)points
                   thickness:(cpFloat)thickness
                    bodyTank:(cpBody*)bodyTank
                  anchorTank:(CGPoint)anchorTank
                 anchorStart:(CGPoint)anchorStart
                   anchorEnd:(CGPoint)anchorEnd;

- (id)initWithPoints:(cpSpace*)space
         parentLayer:(CCLayer*)parentLayer
                 num:(int)num
              points:(cpVect*)points
           thickness:(cpFloat)thickness
            bodyTank:(cpBody*)bodyTank
          anchorTank:(CGPoint)anchorTank
         anchorStart:(CGPoint)anchorStart
           anchorEnd:(CGPoint)anchorEnd;

@end
