//
//  testLayer.m
//  ppTank
//
//  Created by williamzhao on 14-7-18.
//  Copyright 2014年 williamzhao. All rights reserved.
//

#import "testLayer.h"


@implementation testLayer
{
    cpSpace* _space;
    CCPhysicsDebugNode *_debugLayer; // weak ref
	
    cpShape *_walls[4];
}


+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	testLayer *layer = [testLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	if( (self = [super init])) {
		
		// enable events
#ifdef __CC_PLATFORM_IOS
		self.touchEnabled = YES;
		self.accelerometerEnabled = YES;
#elif defined(__CC_PLATFORM_MAC)
		self.mouseEnabled = YES;
        [self setKeyboardEnabled:YES];
#endif

    }
    
    [self initPhysics];
    
    [self test_slideJoint];
    
    
    return  self;
}

-(void) initPhysics
{
	CGSize s = [[CCDirector sharedDirector] winSize];
	
	_space = cpSpaceNew();
	
    //cpSpaceEachConstraint(g_space, drawConstraint, NULL);
    
    _space->gravity = cpv(0.0f, -1280.0f);
	
    cpSpaceSetDamping(_space, 0.05f);  // lost 65% power  every frame, >1 will strange
	//
	// rogue shapes
	// We have to free them manually
	//
	// bottom
    
    cpFloat base_ground_y = 6.0f;
    
	_walls[0] = cpSegmentShapeNew( _space->staticBody, cpv(0, base_ground_y), cpv(s.width, 2), 2.0f);
	cpShapeSetElasticity( _walls[0], 0.6f );
    cpShapeSetFriction( _walls[0], 1.0f );
    cpSpaceAddStaticShape(_space, _walls[0] );
    cpShapeSetCollisionType(_walls[0], COLLISION_TYPE_OUTLINE);
	// top
	_walls[1] = cpSegmentShapeNew( _space->staticBody, cpv(0,s.height), cpv(s.width,s.height), 0.0f);
	cpShapeSetElasticity( _walls[1], 0.6f );
    cpShapeSetFriction( _walls[1], 0.0f );
    cpSpaceAddStaticShape(_space, _walls[1] );
	// left
	_walls[2] = cpSegmentShapeNew( _space->staticBody, cpv(0,0), cpv(0, s.height), 2.0f);
	cpShapeSetElasticity( _walls[2], 0.6f );
    cpShapeSetFriction( _walls[2], 0.0f );
    cpSpaceAddStaticShape(_space, _walls[2] );
	// right
    
	_walls[3] = cpSegmentShapeNew( _space->staticBody, cpv(s.width,0), cpv(s.width, s.height), 2.0f);
    cpShapeSetElasticity( _walls[3], 0.6f );
    cpShapeSetFriction( _walls[3], 0.0f );
    cpSpaceAddStaticShape(_space, _walls[3] );
    
	
	_debugLayer = [CCPhysicsDebugNode debugNodeForCPSpace:_space];
	_debugLayer.visible = YES;
	[self addChild:_debugLayer z:0];
}


- (void) test_slideJoint
{
    int num = 4;
	cpVect verts[] = {
		{ -60, -30 } ,
		{ -60, 30 } ,
        { 60, 30 } ,
		{ 60, -30 } ,
	};
	
    cpFloat mass = 10.1f;
	cpBody *body = cpBodyNew(mass, cpMomentForPoly(mass, num, verts, ccp(2, 2)));
	cpBodySetPos( body, cpv(200, 150) );
	cpSpaceAddBody(_space, body);
    
	cpShape* shape = cpPolyShapeNew(body, num, verts, ccp(2, 2));
	cpShapeSetElasticity( shape, 0.2f );
	cpShapeSetFriction( shape, 1.5f );
	cpSpaceAddShape(_space, shape);
    
    
    cpBody* preSeg;
    
    for (int i = 0; i < 12; i++) {
        cpBody* segment1 = cpBodyNew(mass, cpMomentForBox(mass, 30, 10));
        cpBodySetPos(segment1, cpv(100+i*30, 30));
        cpSpaceAddBody(_space, segment1);
        cpShape* shape1 = cpBoxShapeNew(segment1, 30, 10);
        cpShapeSetElasticity( shape1, 0.2f );
        cpShapeSetFriction( shape1, 1.5f );
        cpSpaceAddShape(_space, shape1);
        cpShapeSetGroup(shape1, 1);
        
        
        cpVect world_pos1 = cpBodyLocal2World( segment1, cpv(-15, 5));
        cpVect world_pos2 = cpBodyLocal2World( segment1, cpv(15, 5));
        
        cpFloat dist1 = cpvdist(cpBodyGetPos(body), world_pos1);
        cpFloat dist2 = cpvdist(cpBodyGetPos(body), world_pos2);
        CCLOG(@"dist1=%2f,  dist2= %2f", dist1, dist2);
        
        cpSpaceAddConstraint(_space, cpSlideJointNew(body, segment1, cpv(0, 0), cpv(-15, 5), dist1-5, dist1));
        cpSpaceAddConstraint(_space, cpSlideJointNew(body, segment1, cpv(0, 0), cpv(15, 5), dist2-5, dist2));
        
        if (i > 0) {
            cpSpaceAddConstraint(_space, cpPivotJointNew2(preSeg, segment1, cpv(15, 5), cpv(-15, 5)));
            
        }
        
        preSeg = segment1;
    }

}

- (void)dealloc
{
	// manually Free rogue shapes
	for( int i=0;i<4;i++) {
		cpShapeFree( _walls[i] );
	}
	
	cpSpaceFree( _space );
	
	[super dealloc];
	
}

-(void) update:(ccTime) delta
{
	// Should use a fixed size step based on the animation interval.
	int steps = 2;
	CGFloat dt = [[CCDirector sharedDirector] animationInterval]/(CGFloat)steps;
	
	for(int i=0; i<steps; i++){
		cpSpaceStep(_space, dt);
	}
    
}

- (BOOL)ccKeyDown:(NSEvent *)event
{
    switch (event.keyCode) {
        case 12:
            [self scheduleUpdate];
            break;
            
        default:
            break;
    }
    
    return YES;
}

-(BOOL) ccMouseDown:(NSEvent *)event
{
	CGPoint location = [(CCDirectorMac*)[CCDirector sharedDirector] convertEventToGL:event];
    
    [self addNewStone:location];
	
	return YES;
}

-(void) addNewStone:(CGPoint)pos
{
	// physics body
    
    cpFloat scale = 0.9;
    
	int num = 4;
	cpVect verts[] = {
		cpvmult(cpv(-10,-10), scale) ,
		cpvmult(cpv(-10, 10), scale) ,
        cpvmult(cpv( 10, 10), scale) ,
		cpvmult(cpv( 20,-10), scale) ,
	};
	
    cpFloat mass = 330.1f;
	cpBody *body = cpBodyNew(mass, cpMomentForPoly(mass, num, verts, ccp(2, 2)));
	cpBodySetPos( body, pos );
	cpSpaceAddBody(_space, body);
    
	cpShape* shape = cpPolyShapeNew(body, num, verts, ccp(2, 2));
	cpShapeSetElasticity( shape, 0.2f );
	cpShapeSetFriction( shape, 1.5f );
	cpSpaceAddShape(_space, shape);
    cpShapeSetCollisionType(shape, 2);
    
}
@end
