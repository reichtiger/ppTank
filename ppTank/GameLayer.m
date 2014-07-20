//
//  HelloWorldLayer.m
//  ppTank
//
//  Created by williamzhao on 14-7-10.
//  Copyright williamzhao 2014年. All rights reserved.
//

#import "AppDelegate.h"

// Import the interfaces
#import "GameLayer.h"

enum GO_DIRECTION {
    GO_AHEAD = 0,
    GO_BACK = 1
};

static cpSpace *g_space;
static cpVect  tankSpeed = {0.0f, 0.0f};
#define             TANK_MAX_SPEED              200.0f

enum {
	kTagParentNode = 1,
};


#pragma mark - GameLayer

@interface GameLayer ()
{
    cpFloat gun_angel;
}

- (void) addStaticWheel:(CGPoint)pos radius:(cpFloat)radius friction:(cpFloat)friction motorSpeed:(cpFloat)speed;
-(cpBody *) addWheel:(cpSpace *)space mass:(cpFloat)mass radius:(cpFloat)radius angel:(cpFloat)angel pos:(cpVect )pos  boxOffset:(cpVect)boxOffset scale:(cpFloat)scale;
-(cpBody *) addTankBody:(cpSpace *)space pos:(cpVect)pos boxOffset:(cpVect)boxOffset;
-(void) addNewStone:(CGPoint)pos;
-(void) initPhysics;
-(void) addGround;
-(void) assemble_tank;
-(void) addTrack2;
-(void) addAntenna;
-(void) rotateGun:(cpFloat)rotation;
-(void) addGround;

@end

static void
postStepRemove(cpSpace *space, cpShape *shape, void *unused)
{
    cpSpaceRemoveBody(space, shape->body);
    cpBodyFree(shape->body);
    
    cpSpaceRemoveShape(space, shape);
    cpShapeFree(shape);
}

static cpBool
preSolveFire(cpArbiter *arb, cpSpace *space, void *ignore)
{
    cpShape *a, *b;
    cpArbiterGetShapes(arb, &a, &b);
    
    // after fire , remove bullet and targets
    cpSpaceAddPostStepCallback(g_space, (cpPostStepFunc)postStepRemove, a, NULL);
    cpSpaceAddPostStepCallback(g_space, (cpPostStepFunc)postStepRemove, b, NULL);
    return cpTrue;
}

static cpBool
preSolveTankMove(cpArbiter *arb, cpSpace *space, void *ignore)
{
    cpShape *a, *b;
    cpArbiterGetShapes(arb, &a, &b);
    
    CGPoint* newSpeed = (CGPoint*)ignore;
    
    cpArbiterSetSurfaceVelocity(arb, *newSpeed);
    cpArbiterSetFriction(arb, 7.6f);
    
    return cpTrue;
}



@implementation GameLayer

@synthesize motor;
@synthesize motorSpeed;

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	GameLayer *layer = [GameLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	if( (self=[super initWithColor:ccc4(50, 50.6, 50, 255)])) {
		
		// enable events
#ifdef __CC_PLATFORM_IOS
		self.touchEnabled = YES;
		self.accelerometerEnabled = YES;
#elif defined(__CC_PLATFORM_MAC)
		self.mouseEnabled = YES;
        [self setKeyboardEnabled:YES];
#endif
		space_pages = 13;
        currentPage = 0;
        
        CGSize s = [[CCDirector sharedDirector] winSize];
        
        CCLayerColor* background_color = [[CCLayerColor alloc] initWithColor:ccc4(50, 50.6, 50, 255) width:s.width*space_pages height:s.height];
        
        [self addChild:background_color z:-1];
        
        CCLabelTTF *label = [CCLabelTTF labelWithString:@"By: reichtiger@gmail.com" fontName:@"Verdana" fontSize:27];
		label.position = ccp( s.width / 2, s.height - 50);
		[self addChild:label];
        
        
		// init physics
		[self initPhysics];
		[self addGround];
		
        tankScale = 0.7f;
        
		[self assemble_tank];
        
        
        // --------------  add track on it
        [self addTrack3];
        
        //[ self addTrack2];
        
        //[self addAntenna];
        [self addGun];
        
        
        [self addStaticWheel:cpv(470, 60) radius:16 friction:1.7f motorSpeed:2.0f];
        [self addStaticWheel:cpv(530, 65) radius:11 friction:1.7f motorSpeed:-2.0f];
        [self addStaticWheel:cpv(590, 70) radius:13 friction:1.7f motorSpeed:2.0f];
        [self addStaticWheel:cpv(660, 60) radius:11 friction:1.7f motorSpeed:-2.0f];
        [self addStaticWheel:cpv(720, 30) radius:12 friction:1.7f motorSpeed:2.0f];
        [self addStaticWheel:cpv(790, 60) radius:14 friction:1.7f motorSpeed:-2.0f];
        
        
        cpSpaceAddCollisionHandler(_space, COLLISION_TYPE_BULLET, COLLISION_TYPE_STONE, NULL, preSolveFire, NULL, NULL, NULL);
        // track collitate with box
        cpSpaceAddCollisionHandler(_space, COLLISION_TYPE_TRACK, COLLISION_TYPE_BULLET, NULL, preSolveTankMove, NULL, NULL, &tankSpeed);
        cpSpaceAddCollisionHandler(_space, COLLISION_TYPE_TRACK, COLLISION_TYPE_STONE, NULL, preSolveTankMove, NULL, NULL, &tankSpeed);
        // track with ground
        cpSpaceAddCollisionHandler(_space, COLLISION_TYPE_TRACK, COLLISION_TYPE_OUTLINE, NULL, preSolveTankMove, NULL, NULL, &tankSpeed);
        
        cpSpaceAddCollisionHandler(_space, COLLISION_TYPE_TRACK, COLLISION_TYPE_WHEEL, NULL, preSolveTankMove, NULL, NULL, &tankSpeed);
        
        
        // add boxes
        
//        [self addNewStone:CGPointMake(400, 70)];
//        [self addNewStone:CGPointMake(420, 70)];
//        [self addNewStone:CGPointMake(440, 70)];
//        [self addNewStone:CGPointMake(460, 70)];
//        [self addNewStone:CGPointMake(430, 80)];
//        [self addNewStone:CGPointMake(450, 80)];
//        [self addNewStone:CGPointMake(430, 90)];
        
        
        
        
		//[self scheduleUpdate];
	}
	
	return self;
}

-(void) initPhysics
{
	CGSize s = [[CCDirector sharedDirector] winSize];
	
	_space = cpSpaceNew();
	g_space = _space;
    
    //cpSpaceEachConstraint(g_space, drawConstraint, NULL);
    
    _space->gravity = cpv(0.0f, -1280.0f);
	
    cpSpaceSetDamping(_space, 0.05f);  // lost 65% power  every frame, >1 will strange
	//
	// rogue shapes
	// We have to free them manually
	//
	// bottom
    
    cpFloat base_ground_y = 6.0f;
    
	_walls[0] = cpSegmentShapeNew( _space->staticBody, cpv(0, base_ground_y), cpv(s.width*space_pages, 20), 10.0f);
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
	_walls[2] = cpSegmentShapeNew( _space->staticBody, cpv(0,0), cpv(0, s.height), 6.0f);
	cpShapeSetElasticity( _walls[2], 0.6f );
    cpShapeSetFriction( _walls[2], 0.0f );
    cpSpaceAddStaticShape(_space, _walls[2] );
	// right
    
	_walls[3] = cpSegmentShapeNew( _space->staticBody, cpv(s.width*space_pages,0), cpv(s.width*space_pages, s.height), 6.0f);
    cpShapeSetElasticity( _walls[3], 0.6f );
    cpShapeSetFriction( _walls[3], 0.0f );
    cpSpaceAddStaticShape(_space, _walls[3] );
    
	
	_debugLayer = [CCPhysicsDebugNode debugNodeForCPSpace:_space];
	_debugLayer.visible = YES;
	[self addChild:_debugLayer z:0];
}

- (void) addGround
{
    
}

-(cpBody *) addWheel:(cpSpace *)space mass:(cpFloat)mass radius:(cpFloat)radius angel:(cpFloat)angel pos:(cpVect )pos  boxOffset:(cpVect )boxOffset scale:(cpFloat)scale;
{
	cpBody *body = cpSpaceAddBody(space, cpBodyNew(mass, cpMomentForCircle(mass, 0.0f, radius, cpvzero)));
	cpBodySetPos(body, cpvadd(pos, boxOffset));
    cpBodySetAngle(body, angel); // set rand angle of each wheel
    
	cpShape *shape = cpSpaceAddShape(space, cpCircleShapeNew(body, radius, cpvzero));
	cpShapeSetElasticity(shape, 0.0f);
	cpShapeSetFriction(shape, 0.1f);
    cpShapeSetLayers(shape, 1);
    
	cpShapeSetGroup(shape, 2); // use a group to keep the car parts from colliding
	
    
#ifdef  WHEEL_SKIN
    CCSpriteBatchNode *parent = [CCSpriteBatchNode batchNodeWithFile:@"rollerwheel.png" capacity:1];
    _spriteTexture = [parent texture];
	
	CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:_spriteTexture];
	[parent addChild: sprite];
	[sprite setCPBody:body];
    sprite.scale = scale;
    [self addChild:parent z:1 tag:kTagParentNode];
    sprite.position = pos;

#endif
    
	return body;
}

-(cpBody *) addTankBody:(cpSpace *)space pos:(cpVect)pos boxOffset:(cpVect)boxOffset
{
	cpFloat mass = 5.0f;
	
    int body_track_pointsNum = 6;
    cpVect verts[] = {
        { -228.6, -11.1},
        { 143.0, -15.3},
        { 158.5, -23.6},
        { 126.4, -46.2},
        { -204.8, -51.3},
        { -228.6, -38.9},

    };
    
    for (int a = 0; a < body_track_pointsNum; a++) {
        verts[a] = cpvmult(verts[a], tankScale);
        //CCLOG(@"%2f", verts[a].x, verts[a].y);
    }
    
    cpVect offset = cpv(0, 0);
    cpBody *body = cpSpaceAddBody(space, cpBodyNew(mass, cpMomentForPoly(mass, body_track_pointsNum, verts, offset)));
	cpBodySetPos(body, cpvadd(pos, boxOffset));
	
	cpShape *shape = cpSpaceAddShape(space, cpPolyShapeNew(body, body_track_pointsNum, verts, offset));
	cpShapeSetElasticity(shape, 0.4f);
	cpShapeSetFriction(shape, 0.0f);
	cpShapeSetGroup(shape, 2); // use a group to keep the car parts from colliding
	cpShapeSetLayers(shape, 1);
    
    
    int head_verts1_num = 7;
    cpVect headVerts1[] = {
        { 10.2, 54.0},
        { 59.9, 26.7},
        { 71.7, 1.4},
        { 51.8, -9.4},
        { -75.8, -9.0},
        { -75.3, 41.4},
        { -37.8, 58.4},
        
    };
    for (int a = 0; a < head_verts1_num; a++) {
        headVerts1[a] = cpvmult(headVerts1[a], tankScale);
    }
    cpShape* head = cpSpaceAddShape(space, cpPolyShapeNew(body, head_verts1_num, headVerts1, offset));
    cpShapeSetElasticity(head, 0.0f);
	cpShapeSetFriction(head, 0.1f);
	cpShapeSetGroup(head, 2); // use a group to keep the car parts from colliding
	cpShapeSetLayers(head, 1);
    
    int head_verts2_num = 5;
    cpVect headVerts2[] = {
        { -79.6, 35.3},
        { -76.2, -2.8},
        { -201.4, 5.3},
        { -199.2, 35.4},
        { -171.7, 45.5},
        
    };
    for (int a = 0; a < head_verts2_num; a++) {
        headVerts2[a] = cpvmult(headVerts2[a], tankScale);
    }
    cpShape* head2 = cpSpaceAddShape(space, cpPolyShapeNew(body, head_verts2_num, headVerts2, offset));
    cpShapeSetElasticity(head2, 0.0f);
	cpShapeSetFriction(head2, 0.1f);
	cpShapeSetGroup(head2, 2); // use a group to keep the car parts from colliding
	cpShapeSetLayers(head2, 1);

   
#ifdef  BODY_SKIN
    CCSpriteBatchNode *parent = [CCSpriteBatchNode batchNodeWithFile:@"tankbody.png" capacity:1];
    _spriteTexture = [parent texture];
	
	CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:_spriteTexture];
	[parent addChild: sprite];
	[sprite setCPBody:body];
    sprite.scale = tankScale;
    [self addChild:parent z:0 tag:kTagParentNode];
    sprite.position = pos;
    
#endif
    
    // done
	return body;
}

/**
 *
 * assemble tank in physics space
 *
 */

- (void) assemble_tank
{
    
    cpVect tankPos = cpv(260, 135);
    cpVect boxOffset = cpv(0, 0);
    // tank body create
    tankBody = [self addTankBody:_space pos:tankPos boxOffset:boxOffset];
    
    cpFloat wheel_mass = 2.0f;
    
    int anchorHeight = -46*tankScale;
    int startWheel_y = -75*tankScale;
    int baseXwheel = -155*tankScale;
    int wheel_dist = 35.0f*tankScale;
    
    cpFloat radius = 16.0f*tankScale;
    
    cpVect pos1_local = cpv(baseXwheel + wheel_dist*0, startWheel_y);
    cpVect pos2_local = cpv(baseXwheel + wheel_dist*1, startWheel_y);
    cpVect pos3_local = cpv(baseXwheel + wheel_dist*2, startWheel_y);
    cpVect pos4_local = cpv(baseXwheel + wheel_dist*3, startWheel_y);
    cpVect pos5_local = cpv(baseXwheel + wheel_dist*4, startWheel_y);
    cpVect pos6_local = cpv(baseXwheel + wheel_dist*5, startWheel_y);
    cpVect pos7_local = cpv(baseXwheel + wheel_dist*6, startWheel_y);
    
    
    cpVect pos1_w = cpBodyLocal2World(tankBody, cpvmult(pos1_local, tankScale));
    cpVect pos2_w = cpBodyLocal2World(tankBody, cpvmult(pos2_local, tankScale));
    cpVect pos3_w = cpBodyLocal2World(tankBody, cpvmult(pos3_local, tankScale));
    cpVect pos4_w = cpBodyLocal2World(tankBody, cpvmult(pos4_local, tankScale));
    cpVect pos5_w = cpBodyLocal2World(tankBody, cpvmult(pos5_local, tankScale));
    cpVect pos6_w = cpBodyLocal2World(tankBody, cpvmult(pos6_local, tankScale));
    cpVect pos7_w = cpBodyLocal2World(tankBody, cpvmult(pos7_local, tankScale));
    
    
    
    // wheels create
    wheel1 = [self addWheel:_space mass:wheel_mass radius:radius angel:rand()%20 pos:pos1_w boxOffset:boxOffset scale:tankScale];
    wheel2 = [self addWheel:_space mass:wheel_mass radius:radius angel:rand()%20 pos:pos2_w boxOffset:boxOffset scale:tankScale];
    wheel3 = [self addWheel:_space mass:wheel_mass radius:radius angel:rand()%20 pos:pos3_w boxOffset:boxOffset scale:tankScale];
    wheel4 = [self addWheel:_space mass:wheel_mass radius:radius angel:rand()%20 pos:pos4_w boxOffset:boxOffset scale:tankScale];
    wheel5 = [self addWheel:_space mass:wheel_mass radius:radius angel:rand()%20 pos:pos5_w boxOffset:boxOffset scale:tankScale];
    wheel6 = [self addWheel:_space mass:wheel_mass radius:radius angel:rand()%20 pos:pos6_w boxOffset:boxOffset scale:tankScale];
    wheel7 = [self addWheel:_space mass:wheel_mass radius:radius angel:rand()%20 pos:pos7_w boxOffset:boxOffset scale:tankScale];
    
    cpSpaceAddConstraint(_space, cpGrooveJointNew(tankBody, wheel1, cpv( baseXwheel+wheel_dist*0, anchorHeight), pos1_local, cpvzero));
    cpSpaceAddConstraint(_space, cpGrooveJointNew(tankBody, wheel2, cpv( baseXwheel+wheel_dist*1, anchorHeight), pos2_local, cpvzero));
    cpSpaceAddConstraint(_space, cpGrooveJointNew(tankBody, wheel3, cpv( baseXwheel+wheel_dist*2, anchorHeight), pos3_local, cpvzero));
    cpSpaceAddConstraint(_space, cpGrooveJointNew(tankBody, wheel4, cpv( baseXwheel+wheel_dist*3, anchorHeight), pos4_local, cpvzero));
    cpSpaceAddConstraint(_space, cpGrooveJointNew(tankBody, wheel5, cpv( baseXwheel+wheel_dist*4, anchorHeight), pos5_local, cpvzero));
    cpSpaceAddConstraint(_space, cpGrooveJointNew(tankBody, wheel6, cpv( baseXwheel+wheel_dist*5, anchorHeight), pos6_local, cpvzero));
    cpSpaceAddConstraint(_space, cpGrooveJointNew(tankBody, wheel7, cpv( baseXwheel+wheel_dist*6, anchorHeight), pos7_local, cpvzero));
    
    
    cpFloat stiffness = 70.0f;
    cpFloat restLen = 30.0f;
    //cpSpaceAddConstraint(_space, cpDampedSpringNew(tankBody, wheel1, cpv( baseXwheel, anchorHeight), cpvzero, restLen, stiffness, 10.0f));
    cpSpaceAddConstraint(_space, cpDampedSpringNew(tankBody, wheel2, cpv( baseXwheel+wheel_dist*1, anchorHeight), cpvzero, restLen, stiffness, 10.0f));
    cpSpaceAddConstraint(_space, cpDampedSpringNew(tankBody, wheel3, cpv( baseXwheel+wheel_dist*2, anchorHeight), cpvzero, restLen, stiffness, 10.0f));
    cpSpaceAddConstraint(_space, cpDampedSpringNew(tankBody, wheel4, cpv( baseXwheel+wheel_dist*3, anchorHeight), cpvzero, restLen, stiffness, 10.0f));
    cpSpaceAddConstraint(_space, cpDampedSpringNew(tankBody, wheel5, cpv( baseXwheel+wheel_dist*4, anchorHeight), cpvzero, restLen, stiffness, 10.0f));
    cpSpaceAddConstraint(_space, cpDampedSpringNew(tankBody, wheel6, cpv( baseXwheel+wheel_dist*5, anchorHeight), cpvzero, restLen, stiffness, 10.0f));
    //cpSpaceAddConstraint(_space, cpDampedSpringNew(tankBody, wheel7, cpv( baseXwheel+wheel_dist*6, anchorHeight), cpvzero, restLen, stiffness, 10.0f));
    
    
    // ====== add gears left right
    cpFloat gearMass = 0.1f;
    // add two gear wheels
    gearBody1 = [self addWheel:_space mass:gearMass radius:10.0f*tankScale angel:0 pos:cpBodyLocal2World(tankBody,cpv(-220*tankScale, -25)) boxOffset:boxOffset scale:tankScale*0.8f];
    gearBody2 = [self addWheel:_space mass:gearMass radius:10.0f*tankScale angel:0 pos:cpBodyLocal2World(tankBody,cpv(140*tankScale, -25)) boxOffset:boxOffset scale:tankScale*0.8f];
    
    cpSpaceAddConstraint(_space, cpPivotJointNew2(tankBody, gearBody1, cpv(-220*tankScale, -30), cpv(0, 0)));
    cpSpaceAddConstraint(_space, cpPivotJointNew2(tankBody, gearBody2, cpv(140*tankScale, -30), cpv(0, 0)));
    cpSpaceAddConstraint(_space, cpRotaryLimitJointNew(tankBody, gearBody1, 0.2f, -0.2f));
    cpSpaceAddConstraint(_space, cpRotaryLimitJointNew(tankBody, gearBody2, 0.2f, -0.2f));
    
    // add motor for tank
    
    motorGear1 = cpSimpleMotorNew(tankBody, gearBody1, 0.0f);
    motorGear2 = cpSimpleMotorNew(tankBody, gearBody2, 0.0f);
    cpSpaceAddConstraint(_space, motorGear1);
    cpSpaceAddConstraint(_space, motorGear2);
    
    // motor add
    motor1 = cpSimpleMotorNew(tankBody, wheel1, 0.0f);
    motor2 = cpSimpleMotorNew(tankBody, wheel2, 0.0f);
    motor3 = cpSimpleMotorNew(tankBody, wheel3, 0.0f);
    motor4 = cpSimpleMotorNew(tankBody, wheel4, 0.0f);
    motor5 = cpSimpleMotorNew(tankBody, wheel5, 0.0f);
    motor6 = cpSimpleMotorNew(tankBody, wheel6, 0.0f);
    motor7 = cpSimpleMotorNew(tankBody, wheel7, 0.0f);
    cpSpaceAddConstraint(_space, motor1);
    cpSpaceAddConstraint(_space, motor2);
    cpSpaceAddConstraint(_space, motor3);
    cpSpaceAddConstraint(_space, motor4);
    cpSpaceAddConstraint(_space, motor5);
    cpSpaceAddConstraint(_space, motor6);
    cpSpaceAddConstraint(_space, motor7);
    
    
    gun_gear = [self addWheel:_space mass:gearMass radius:10.0f*tankScale angel:0 pos:cpBodyLocal2World(tankBody,cpv(55*tankScale, 5*tankScale)) boxOffset:boxOffset scale:tankScale];
    
    cpSpaceAddConstraint(_space, cpPivotJointNew2(tankBody, gun_gear, cpv(55*tankScale, 5*tankScale), cpv(0, 0)));
    cpSpaceAddConstraint(_space, cpRotaryLimitJointNew(tankBody, gun_gear, 0.0f, 0.4f));
    

}

// add antenna ======================

- (void) addAntenna
{
    // antenna
    cpVect vertsAntenna[] = {
        cpv(-100, 21),
        cpv(-104, 21),
        cpv(-104, 35),
        cpv(-100, 35),
    };
    
    for (int a = 0; a < 4; a++) {
        vertsAntenna[a] = cpvmult(vertsAntenna[a], tankScale);
    }
    cpShape *antennaShape = cpSpaceAddShape(_space, cpPolyShapeNew(tankBody, 4, vertsAntenna, cpv(0, 0)));
	cpShapeSetElasticity(antennaShape, 2.0f);
	cpShapeSetFriction(antennaShape, 0.7f);
	cpShapeSetGroup(antennaShape, 1); // use a group to keep the car parts from colliding
	cpShapeSetCollisionType(antennaShape, 1);
	cpShapeSetLayers(antennaShape, 0);
    
    // add 1 --------------------------------------------------
    int anten1_width = 1;
    int anten1_height = 26*tankScale;
    cpBody *antennaBody1 = cpSpaceAddBody(_space, cpBodyNew(0.1f, cpMomentForBox(0.1f, 1.6f, 10.0f)));
    cpVect antenWorldPos = cpBodyLocal2World(tankBody, cpv(-102*tankScale, 35*tankScale+anten1_height/2));
	cpBodySetPos(antennaBody1, antenWorldPos);
    
    cpShape *antennaShape1 = cpSpaceAddShape(_space, cpBoxShapeNew(antennaBody1, anten1_width, anten1_height));
	cpShapeSetElasticity(antennaShape1, 2.0f);
	cpShapeSetFriction(antennaShape1, 0.7f);
	cpShapeSetGroup(antennaShape1, 1); // use a group to keep the car parts from colliding
	cpShapeSetCollisionType(antennaShape1, 1);
	cpShapeSetLayers(antennaShape1, 0);
    
    cpVect jPos = cpvmult(cpv(-102, 35), tankScale);
    cpSpaceAddConstraint(_space, cpPivotJointNew(tankBody, antennaBody1, cpBodyLocal2World(tankBody, jPos)));
    //cpSpaceAddConstraint(_space, cpDampedRotarySpringNew(tankBody, antennaBody1, 90.0f, 150.0f, 0.1f));
    cpSpaceAddConstraint(_space, cpDampedSpringNew(tankBody, antennaBody1, cpv(-100*tankScale, 21*tankScale), cpv(0, 16*tankScale), 50*tankScale, 130.0f*tankScale, 110.f*tankScale));
    
}

- (void) addGun
{
    gunBody = cpSpaceAddBody(_space, cpBodyNew(0.1f, cpMomentForBox(0.1f, 240.0f, 6.0f)));
    cpVect gun_pos = cpBodyLocal2World(tankBody, cpv(180*tankScale, 15*tankScale));
	cpBodySetPos(gunBody, gun_pos);
	//cpBodySetAngle(gunBody, 0.4f);
    cpShape *gunShape = cpSpaceAddShape(_space, cpBoxShapeNew(gunBody, 240*tankScale, 6*tankScale));
	cpShapeSetElasticity(gunShape, 2.0f);
	cpShapeSetFriction(gunShape, 0.7f);
	cpShapeSetGroup(gunShape, 2); // use a group to keep the car parts from colliding
    
    cpSpaceAddConstraint(_space, cpPivotJointNew2(gun_gear, gunBody, cpv(0, 0), cpv(-120*tankScale, 0)));
    //cpSpaceAddConstraint(_space, cpDampedSpringNew(tankBody, gunBody, cpv(75*tankScale, 15*tankScale), cpv(0, 0), 35.0f*tankScale, 100.0f*tankScale, 20.0f*tankScale));
    gunGearJoint = cpRotaryLimitJointNew(gun_gear, gunBody, 0.0f, 0.0f);
    cpSpaceAddConstraint(_space, gunGearJoint);
    
    
#ifdef  GUN_SKIN
    CCSpriteBatchNode *parent = [CCSpriteBatchNode batchNodeWithFile:@"gunbarrel.png" capacity:1];
    _spriteTexture = [parent texture];
	
	CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:_spriteTexture];
	[parent addChild: sprite];
	[sprite setCPBody:gunBody];
    sprite.scale = tankScale;
    [self addChild:parent z:1 tag:kTagParentNode];
    sprite.position = gun_pos;
    
#endif
    
}

-(void) rotateGun:(cpFloat)rotation
{
    gun_angel = rotation;
    
    cpBodySetAngle(gun_gear, 0.5f);
}

- (void)fire
{
    // get cur pos of gun hole
    
    if (gunBody) {
        cpVect pos = cpBodyGetPos(gunBody);
        int speed = 1200;
        cpFloat bullet_mass = 20.0f;
        
        cpFloat bullet_angel = cpBodyGetAngle(gunBody);
        cpVect gun_angelV = cpvforangle(bullet_angel);
        cpVect speedVect = cpv(speed*gun_angelV.x, speed*gun_angelV.y);
        // set speed of bullet
        
        int num = 5;
        cpVect verts[] = {
            cpv(-4, -2),
            cpv(-4, 2),
            cpv( 4, 2),
            cpv( 6, 0),
            cpv( 4, -2),
        };
        
        for (int a= 0; a< 5; a++) {
            verts[a] = cpvmult(verts[a], tankScale);
        }
        CCLOG(@"bullet :%2f", pos.x);
        cpBody *body = cpBodyNew(bullet_mass, cpMomentForPoly(bullet_mass, num, verts, CGPointZero));
        cpBodySetPos( body, pos );
        cpSpaceAddBody(_space, body);
        cpBodySetAngle(body, bullet_angel);
        cpShape* shape = cpPolyShapeNew(body, num, verts, CGPointZero);
        cpShapeSetElasticity( shape, 0.8f );
        cpShapeSetFriction( shape, 0.5f );
        cpSpaceAddShape(_space, shape);
        cpShapeSetCollisionType(shape, COLLISION_TYPE_BULLET);
        cpBodySetVel(body, speedVect);
    }
    
}

- (void)addTrack2
{
    //cpFloat scale = 1;
    
    cpFloat firstPoint_x = -196;
    cpFloat firstPoint_y = -75;
    
    cpFloat segLen = 39;
    cpVect trackVerts[] = {
        
        { firstPoint_x + segLen*0, firstPoint_y },
        { firstPoint_x + segLen*1, firstPoint_y },
        { firstPoint_x + segLen*2, firstPoint_y },
        { firstPoint_x + segLen*3, firstPoint_y },
        { firstPoint_x + segLen*4, firstPoint_y },
        { firstPoint_x + segLen*5, firstPoint_y },
        { firstPoint_x + segLen*6, firstPoint_y },
        { firstPoint_x + segLen*7, firstPoint_y },
        
    };
    
    int numPoints = 8;
    
    for (int a = 0; a < numPoints; a++) {
        //trackVerts[a] = cpBodyWorld2Local(tankBody, trackVerts[a]);
        
        trackVerts[a] = cpBodyLocal2World(tankBody, cpvmult(trackVerts[a], tankScale));
        CCLOG(@"{ %2f, %2f },", trackVerts[a].x, trackVerts[a].y);
    }
    
    cpVect anchor_a = cpv(-156, -36);
    cpVect anchor_b = cpv(103, -38);
    
    track2 = [trackNode connectBodiesWithPoints:_space parentLayer:(CCLayer*)self connectMode:0 num:numPoints points:trackVerts thickness:6.0f*tankScale bodyA:tankBody bodyB:tankBody anchorA:anchor_a  anchorB:anchor_b];
}

- (void)addTrack3
{
    //cpFloat scale = 1;
    
    cpFloat firstPoint_x = -170;
    cpFloat firstPoint_y = -90;
    
    cpFloat segLen = 40;
    cpVect trackVerts[] = {
        
        { firstPoint_x + segLen*0, firstPoint_y },
        { firstPoint_x + segLen*1, firstPoint_y },
        { firstPoint_x + segLen*2, firstPoint_y },
        { firstPoint_x + segLen*3, firstPoint_y },
        { firstPoint_x + segLen*4, firstPoint_y },
        { firstPoint_x + segLen*5, firstPoint_y },
        { firstPoint_x + segLen*6, firstPoint_y },
        { firstPoint_x + segLen*7, firstPoint_y },
        
    };
    
    int numPoints = 7;
    
    for (int a = 0; a < numPoints; a++) {
        //trackVerts[a] = cpBodyWorld2Local(tankBody, trackVerts[a]);
        
        trackVerts[a] = cpBodyLocal2World(tankBody, cpvmult(trackVerts[a], tankScale));
        CCLOG(@"{ %2f, %2f },", trackVerts[a].x, trackVerts[a].y);
    }
    
    track2 = [trackNode connectWithCenterPoint:_space parentLayer:self num:numPoints points:trackVerts thickness:6.0f bodyTank:tankBody anchorTank:ccp(-40, -30) anchorStart:cpv(-156, -36) anchorEnd:cpv(103, -38)];
}


-(void) addSpeed:(cpFloat)speed
{
    motorSpeed += speed;
    //CCLOG(@"motorSpeed = %2f", motorSpeed);
    
    cpFloat a = cpBodyGetAngle(tankBody);
    //CCLOG(@"angle=%2f", a);
    
    if (speed > 0) {
        tankDirection = GO_AHEAD;
        tankSpeed.x += 10.0f;
        tankSpeed.y = 80.0f*a;
        
        if (tankSpeed.x >= TANK_MAX_SPEED*tankScale) {
            tankSpeed.x = TANK_MAX_SPEED*tankScale;
        }
        
        if (tankSpeed.y >= 80.0f) {
            tankSpeed.y = 80.0f;
        }
        //CCLOG(@"speed ++++ { %2f, %2f }", tankSpeed.x, tankSpeed.y);
    }
    else{
        tankDirection = GO_BACK;
        tankSpeed.x -= 10.0f;
        tankSpeed.y = -80.0f*a;
        
        if (tankSpeed.x <= -TANK_MAX_SPEED*tankScale) {
            tankSpeed.x = -TANK_MAX_SPEED*tankScale;
        }
        if (tankSpeed.y >= 80.0f) {
            tankSpeed.y = 80.0f;
        }
        //CCLOG(@"speed ---- { %2f, %2f }", tankSpeed.x, tankSpeed.y);
    }
    
    if (motorSpeed >= TANK_WHEEL_MAX_SPEED || motorSpeed <= -TANK_WHEEL_MAX_SPEED) {
        return;
    }
    cpSimpleMotorSetRate(motor1, motorSpeed);
    cpSimpleMotorSetRate(motor2, motorSpeed);
    cpSimpleMotorSetRate(motor3, motorSpeed);
    cpSimpleMotorSetRate(motor4, motorSpeed);
    cpSimpleMotorSetRate(motor5, motorSpeed);
    cpSimpleMotorSetRate(motor6, motorSpeed);
    cpSimpleMotorSetRate(motor7, motorSpeed);
    

}

-(void)stopSpeed:(int)direction
{
    tankDirection = direction;
    
    tankSpeed.x = 0.0f;
    tankSpeed.y = 0.0f;
    
    motorSpeed = 0.0f;
    cpSimpleMotorSetRate(motor1, motorSpeed);
    cpSimpleMotorSetRate(motor2, motorSpeed);
    cpSimpleMotorSetRate(motor3, motorSpeed);
    cpSimpleMotorSetRate(motor4, motorSpeed);
    cpSimpleMotorSetRate(motor5, motorSpeed);
    cpSimpleMotorSetRate(motor6, motorSpeed);
    cpSimpleMotorSetRate(motor7, motorSpeed);
    
    if (useTrack1 == YES) {
        cpSimpleMotorSetRate(motorGear1, motorSpeed);
        cpSimpleMotorSetRate(motorGear2, motorSpeed);
        
    }
    
    //[self schedule:@selector(reduceMotorSpeed) interval:0.2 repeat:1000 delay:0.1];
}


- (void) addStaticWheel:(CGPoint)pos radius:(cpFloat)radius friction:(cpFloat)friction motorSpeed:(cpFloat)speed
{
    cpFloat mass = 1.0f;
    
    cpVect posPivot = pos;
    // pivot point
    cpBody* pivotBody = cpBodyNewStatic();
    cpBodySetPos( pivotBody,  posPivot);
    cpBodySetAngle(pivotBody, -45.0f);
	cpShape* shapePivot = cpCircleShapeNew(pivotBody, 10.0f, cpv(0, 0));
	cpShapeSetElasticity( shapePivot, 0.2f );
	cpShapeSetFriction( shapePivot, 0.1f );
	cpSpaceAddStaticShape(_space, shapePivot);
    cpShapeSetGroup(shapePivot, 5); // same with gear below
    
    
    // gear
    cpBody *gearBody = cpSpaceAddBody(_space, cpBodyNew(mass, cpMomentForCircle(mass, 0.0f, radius, cpvzero)));
	cpBodySetPos(gearBody, posPivot);
	
	cpShape *shape = cpSpaceAddShape(_space, cpCircleShapeNew(gearBody, radius, cpvzero));
	cpShapeSetElasticity(shape, 0.0f);
	cpShapeSetFriction(shape, friction);
	cpShapeSetGroup(shape, 5); // use a group to keep the gear parts from colliding
	cpShapeSetCollisionType(shape, COLLISION_TYPE_WHEEL);
    
    cpConstraint* cons = cpPivotJointNew2(pivotBody, gearBody, cpv(0, 0), cpv(0, 0));
    cpSpaceAddConstraint(_space, cons);
    
    motor = cpSimpleMotorNew(pivotBody, gearBody, speed);
    cpSpaceAddConstraint(_space, motor);
    
    CCSpriteBatchNode *parent = [CCSpriteBatchNode batchNodeWithFile:@"wheel.png" capacity:1];
    _spriteTexture = [parent texture];
	
	CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:_spriteTexture];
	[parent addChild: sprite];
	[sprite setCPBody:gearBody];
    sprite.scale = radius/_spriteTexture.contentSize.width*2;
    [self addChild:parent z:1 tag:kTagParentNode];
    sprite.position = pos;
    //cpSpaceAddCollisionHandler(_space, 1, 2, NULL, preSolve2, NULL, NULL, NULL);
    
}

// ===============================================================================================
// ================================================below is default ===============================
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
    
    cpVect p = cpBodyGetPos(tankBody);
    //CCLOG(@"tankPos=%2f, %2f", p.x, p.y);
    
    currentPage = (int)(p.x/self.contentSize.width);
    
    if ( (p.x >= self.contentSize.width/2) && (p.x < self.contentSize.width * (space_pages-1)+self.contentSize.width/2) ) {
        CGPoint s = self.position;
        
        offsetScreenX = CGPointMake(-(p.x - self.contentSize.width/2), s.y);
        [self setPosition:offsetScreenX];
    }
}

-(void) createMenu
{
	// Default font size will be 22 points.
	[CCMenuItemFont setFontSize:22];
	
	// Reset Button
	CCMenuItemLabel *reset = [CCMenuItemFont itemWithString:@"Reset" block:^(id sender){
		[[CCDirector sharedDirector] replaceScene: [GameLayer scene]];
	}];
	
	// Debug Button
	CCMenuItemLabel *debug = [CCMenuItemFont itemWithString:@"Toggle Debug" block:^(id sender){
		[_debugLayer setVisible: !_debugLayer.visible];
	}];
	
	CCMenu *menu = [CCMenu menuWithItems:debug, reset, nil];
	
	[menu alignItemsVertically];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	[menu setPosition:ccp( size.width/2, size.height/2)];
	
	
	[self addChild: menu z:-1];
}

-(void) addNewStone:(CGPoint)pos
{
	// physics body
    
    CGPoint real_pos = CGPointMake(-(offsetScreenX.x) + pos.x , pos.y);
    
    cpFloat scale = 0.9;
    
	int num = 4;
	cpVect verts[] = {
		cpvmult(cpv(-10,-10), scale) ,
		cpvmult(cpv(-10, 10), scale) ,
        cpvmult(cpv( 10, 10), scale) ,
		cpvmult(cpv( 20,-10), scale) ,
	};
	
    cpFloat mass = 0.1f;
	cpBody *body = cpBodyNew(mass, cpMomentForPoly(mass, num, verts, ccp(2, 2)));
	cpBodySetPos( body, real_pos );
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

-(BOOL) ccMouseDown:(NSEvent *)event
{
	CGPoint location = [(CCDirectorMac*)[CCDirector sharedDirector] convertEventToGL:event];

    cpVect inbodyPos = cpBodyWorld2Local(tankBody, location);
    CCLOG(@"{ %2f, %2f },", inbodyPos.x, inbodyPos.y);
    
    [self addNewStone:location];
	[self addNewStone:ccp(location.x+2, location.y+5)];
	
	return YES;
}

-(BOOL)ccKeyDown:(NSEvent *)event
{
    CCLOG(@"press %d", event.keyCode);
    switch (event.keyCode) {
        case 49: // char d
            [self fire];
            break;
        case 0: // <-  key a
            tankDirection = GO_BACK;
            [self addSpeed:-5.0f];
            break;
        case 2: // ->  key d
            tankDirection = GO_AHEAD;
            [self addSpeed:5.0f];
            break;
        case 125: // down
            [self rotateGun:-0.1f];
            break;

        case 126: // above
            [self rotateGun:0.1f];
            break;

        default:
            break;
    }
    return YES;
}

-(BOOL)ccKeyUp:(NSEvent *)event
{
    CCLOG(@"up %d", event.keyCode);
    switch (event.keyCode) {
        case 0:
            [self stopSpeed:tankDirection];
            break;
        case 2:
            [self stopSpeed:tankDirection];
            break;
        case 12: /// key q
            [self scheduleUpdate];
            break;
            
        default:
            break;
    }
    return YES;
}

@end

