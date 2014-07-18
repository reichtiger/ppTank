//
//  trackNode
//  cpTank
//
//  Created by williamzhao on 14-6-17.
//  Copyright 2014年 williamzhao. All rights reserved.
//

#import "trackNode.h"

#define         TRACK_SKIN

@implementation trackNode
{
    cpVect trackRect;
}

- (cpBody *) addSegment:(CCLayer*)layer pos:(cpVect)pos rotation:(cpFloat)rotation group:(int)grp
{
    cpFloat mass = 0.1f;
    
	cpBody* body = cpBodyNew(mass, cpMomentForBox(mass, trackRect.x, trackRect.y));
	cpBodySetPos( body, pos );
	cpSpaceAddBody(_space, body);
    cpBodySetAngle(body, rotation);
    
	cpShape* shape = cpBoxShapeNew(body, trackRect.x, trackRect.y);
	cpShapeSetElasticity( shape, 0.2f );
	cpShapeSetFriction( shape, 1.0f );
	cpSpaceAddShape(_space, shape);
    cpShapeSetGroup(shape, 1); // same with tankBody
    cpShapeSetCollisionType(shape, COLLISION_TYPE_TRACK);
   
    
#ifdef  TRACK_SKIN
    CCSpriteBatchNode *parent = [CCSpriteBatchNode batchNodeWithFile:@"tracksegment.png" capacity:1];
    _spriteTexture = [parent texture];
	
	CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:_spriteTexture];
	[parent addChild: sprite];
	[sprite setCPBody:body];
    sprite.scale = 0.5;
    [sprite setContentSize:CGSizeMake(trackRect.x, trackRect.y)];
    [layer addChild:parent z:1];
    sprite.position = pos;
    
#endif
    
    return body;
}

// =============================================================================

//          use track 2 method
// =============================================================================

+ (id)connectBodiesWithPoints:(cpSpace*)space
                  parentLayer:(CCLayer*)parentLayer
                  connectMode:(int)connectMode
                          num:(int)num
                       points:(cpVect*)points
                    thickness:(cpFloat)thickness
                        bodyA:(cpBody*)bodyA
                        bodyB:(cpBody*)bodyB
                      anchorA:(CGPoint)anchorA
                      anchorB:(CGPoint)anchorB
{
    return [[trackNode node] initWithPoints:space
                                parentLayer:parentLayer
                                connectMode:connectMode
                                        num:num
                                     points:points
                                  thickness:thickness
                                       bodyA:bodyA
                                      bodyB:bodyB
                                    anchorA:anchorA
                                    anchorB:anchorB];

}

- (id)initWithPoints:(cpSpace*)space
         parentLayer:(CCLayer*)parentLayer
         connectMode:(int)connectMode
                 num:(int)num
              points:(cpVect*)points
           thickness:(cpFloat)thickness
               bodyA:(cpBody*)bodyA
               bodyB:(cpBody*)bodyB
             anchorA:(CGPoint)anchorA
             anchorB:(CGPoint)anchorB
{
    self = [super init];
    if (!self) return(nil);
    
    _space = space;
    
    //   init vars
    cpVect posCur;
    cpBody* firstBody;
    cpBody* preBody;
    cpBody* curBody = nil;
    cpConstraint* pivotJointTrack;
    
    cpFloat dist;
    cpFloat preDist;
    
    int n = 0;
    for (n = 0; n < num; n++) {
        
        if (n == 0) {
            
            cpVect pos1 = cpBodyLocal2World(bodyA, anchorA);
            cpVect pos2 = points[0];
            
            dist = cpvdist(pos1, pos2);
            trackRect = cpv(dist, thickness);
            
            cpFloat rotation = cpvtoangle(ccpSub(pos2, pos1));
            cpVect angelVect = cpvforangle( rotation );
            
            posCur  = ccpAdd(ccpAdd(pos1, ccp(dist*angelVect.x/2, dist*angelVect.y/2)), ccp(0, 0));
            curBody = [self addSegment:parentLayer pos:posCur rotation:rotation group:n ];
            
            pivotJointTrack = cpPivotJointNew2(bodyA, curBody, anchorA, cpv(-dist/2, -trackRect.y/2));
            cpSpaceAddConstraint(_space, pivotJointTrack);
            
            firstBody = curBody;
        }else{
            
            cpVect pos1 = points[n-1];
            cpVect pos2 = points[n];
            
            dist = cpvdist(pos1, pos2)+2;
            trackRect = cpv(dist, thickness);
            
            cpFloat rotation = cpvtoangle(ccpSub(pos2, pos1));
            cpVect angelVect = cpvforangle( rotation );
            
            posCur  = ccpAdd(ccpAdd(pos1, ccp(dist*angelVect.x/2, dist*angelVect.y/2)), ccp(dist* angelVect.x/2, dist*angelVect.y/2));
            
            if (connectMode == 0) {
                curBody = [self addSegment:parentLayer pos:posCur rotation:rotation group:1 ];
                
                pivotJointTrack = cpPivotJointNew2(preBody, curBody, cpv(preDist/2, -trackRect.y/2), cpv(-dist/2+2, -trackRect.y/2));
                cpSpaceAddConstraint(_space, pivotJointTrack);
            }
        }
        
        // prepare next
        preBody = curBody;
        preDist = dist;
    }
    
    if (n == num) {
        
        cpVect pos1 = points[n-1];
        cpVect pos2 = cpBodyLocal2World(bodyB, anchorB);
        
        dist = cpvdist(pos1, pos2)+2;
        trackRect = cpv(dist, thickness);
        
        cpFloat rotation = cpvtoangle(ccpSub(pos2, pos1));
        cpVect angelVect = cpvforangle( rotation );
        
        posCur  = ccpAdd(ccpAdd(pos1, ccp(dist*angelVect.x/2, dist*angelVect.y/2)), ccp(0, 0));
        curBody = [self addSegment:parentLayer pos:posCur rotation:rotation group:n ];
        
        
        // connect with pre-body,
        cpConstraint* lastPointJoint = cpPivotJointNew2(preBody, curBody, cpv(preDist/2, -trackRect.y/2), cpv(-dist/2+2, -trackRect.y/2));
        cpSpaceAddConstraint(_space, lastPointJoint);
        // then connect bodyB
        pivotJointTrack = cpPivotJointNew2(curBody, bodyB, cpv(dist/2, -trackRect.y/2), anchorB);
        cpSpaceAddConstraint(_space, pivotJointTrack);
        
    }
    
   
    // done
    return self;
}

+ (id)connectWithCenterPoint:(cpSpace*)space
                 parentLayer:(CCLayer*)parentLayer
                         num:(int)num
                      points:(cpVect*)points
                   thickness:(cpFloat)thickness
                    bodyTank:(cpBody*)bodyTank
                  anchorTank:(CGPoint)anchorTank
{
    return [[trackNode alloc] initWithPoints:space parentLayer:parentLayer num:num points:points thickness:thickness bodyTank:bodyTank anchorTank:anchorTank];
}

- (id)initWithPoints:(cpSpace*)space
         parentLayer:(CCLayer*)parentLayer
                 num:(int)num
              points:(cpVect*)points
           thickness:(cpFloat)thickness
            bodyTank:(cpBody*)bodyTank
          anchorTank:(CGPoint)anchorTank
{
    self = [super init];
    if (!self) return(nil);
    
    _space = space;
    
    //   init vars
    cpVect posCur;
    cpBody* firstBody;
    cpBody* preBody;
    cpBody* curBody = nil;
    
    cpFloat dist;
    cpFloat preDist;
    
    int n = 0;
    for (n = 0; n < 3; n++) {
        
        
            
            cpVect pos1 = points[n];
            cpVect pos2 = points[n+1];
            
            dist = cpvdist(pos1, pos2);
            cpFloat point1_2_center = cpvdist(pos1, anchorTank);
            cpFloat point2_2_center = cpvdist(pos2, anchorTank);
            
            trackRect = cpv(dist, thickness);
            
            cpFloat rotation = cpvtoangle(ccpSub(pos2, pos1));
            cpVect angelVect = cpvforangle( rotation );
            
            posCur  = ccpAdd(ccpAdd(pos1, ccp(dist*angelVect.x/2, dist*angelVect.y/2)), ccp(0, 0));
            curBody = [self addSegment:parentLayer pos:posCur rotation:rotation group:n ];
            
            //pivotJointTrack = cpPivotJointNew2(bodyTank, curBody, anchorA, cpv(-dist/2, -trackRect.y/2));
            cpSpaceAddConstraint(_space, cpSlideJointNew(bodyTank, curBody, anchorTank, cpv(-dist/2, -trackRect.y/2), point1_2_center/2, point1_2_center/2));
            cpSpaceAddConstraint(_space, cpSlideJointNew(bodyTank, curBody, anchorTank, cpv(dist/2, -trackRect.y/2), point2_2_center/2, point2_2_center/2));
            
            firstBody = curBody;
        }
        
        // prepare next
        preBody = curBody;
        preDist = dist;
    
    
    // done
    return self;
}

@end
