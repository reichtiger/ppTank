//
//  roadblocks.m
//  ppTank
//
//  Created by williamzhao on 14-7-21.
//  Copyright 2014年 williamzhao. All rights reserved.
//

#import "roadblocks.h"

@interface roadblocks()
{
    
}

-(void) add_block:(CGPoint)pos verts:(cpVect*)verts;

@end

/*********************************************
 *
 * implementation of roadblocks
 *
 *********************************************/
@implementation roadblocks

// 碉堡，是否带战士
+ (id) blockhouseAtPos:(cpSpace*)space pos:(CGPoint)pos withWarrior:(BOOL)hasWarrior
{
    return [[roadblocks node] initWithBlockhouse:space pos:pos withWarrior:hasWarrior];
}

- (id) initWithBlockhouse:(cpSpace*)space pos:(CGPoint)pos withWarrior:(BOOL)hasWarrior
{
    self = [super init];
    if (!self) return(nil);
    
    _space = space;
    
    CGFloat scale = 0.9f;
    
    int block_width = 20;
    
    cpVect verts[] = {
		cpvmult(cpv(-block_width/2, -block_width/2), scale) ,
		cpvmult(cpv(-block_width/2, block_width/2), scale) ,
        cpvmult(cpv( block_width/2, block_width/2), scale) ,
		cpvmult(cpv( block_width/2,-block_width/2), scale) ,
	};
    
    [self add_block:cpvadd(pos, cpv(block_width*0, 0)) verts:verts];
    [self add_block:cpvadd(pos, cpv(block_width*1, 0)) verts:verts];
    [self add_block:cpvadd(pos, cpv(block_width*2, 0)) verts:verts];
    [self add_block:cpvadd(pos, cpv(block_width*3, 0)) verts:verts];
    
    [self add_block:cpvadd(pos, cpv(block_width*0, block_width*1)) verts:verts];
    [self add_block:cpvadd(pos, cpv(block_width*1, block_width*1)) verts:verts];
    [self add_block:cpvadd(pos, cpv(block_width*2, block_width*1)) verts:verts];
    [self add_block:cpvadd(pos, cpv(block_width*3, block_width*1)) verts:verts];
    
    [self add_block:cpvadd(pos, cpv(block_width*1, block_width*2)) verts:verts];
    [self add_block:cpvadd(pos, cpv(block_width*2, block_width*2)) verts:verts];
    [self add_block:cpvadd(pos, cpv(block_width*3, block_width*2)) verts:verts];
    
    cpVect hatVerts[] = {
        cpv(-40, -10),
        cpv(-40, 10),
        cpv(40, 10),
        cpv(40, -10),
        
    };
    [self add_block:cpvadd(pos, cpv(block_width*1.5, block_width*3)) verts:hatVerts];
    
    return self;
}


-(void) add_block:(CGPoint)pos  verts:(cpVect*)verts
{
	// physics body

	int num = 4;
	
    cpFloat mass = 0.1f;
	cpBody *body = cpBodyNew(mass, cpMomentForPoly(mass, num, verts, ccp(2, 2)));
	cpBodySetPos( body, pos );
	cpSpaceAddBody(_space, body);
    
	cpShape* shape = cpPolyShapeNew(body, num, verts, ccp(2, 2));
	cpShapeSetElasticity( shape, 0.2f );
	cpShapeSetFriction( shape, 1.5f );
	cpSpaceAddShape(_space, shape);
    cpShapeSetCollisionType(shape, 2);
    
    
    //    CCSpriteBatchNode *parent = [CCSpriteBatchNode batchNodeWithFile:@"block2.png" capacity:1];
    //    _spriteTexture = [parent texture];
    //
    //	CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:_spriteTexture];
    //	[parent addChild: sprite];
    //	[sprite setCPBody:body];
    //    sprite.scale = 1;
    //    [self addChild:parent z:1 tag:kTagParentNode];
    //    sprite.position = real_pos;
    
    
}

// 轿车，是否带警察
+ (id) carAtPos:(cpSpace*)space pos:(CGPoint)pos withPolice:(BOOL)hasPolice
{
    return [roadblocks node];
}
- (id) initWithCar:(cpSpace*)space pos:(CGPoint)pos withPolice:(BOOL)hasPolice
{
    self = [super init];
    if (!self) return(nil);
    
    _space = space;
    
    
    return self;
}



// 喀秋莎火箭炮车，带炮弹数目
+ (id) bazookaAtPos:(cpSpace*)space pos:(CGPoint)pos withBullet:(int)num
{
    return [roadblocks node];
}
- (id) initWithBazooka:(cpSpace*)space pos:(CGPoint)pos withBullet:(int)num
{
    self = [super init];
    if (!self) return(nil);
    
    _space = space;
    
    return self;
}
@end
