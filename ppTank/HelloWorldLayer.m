//
//  HelloWorldLayer.m
//  ddd
//
//  Created by williamzhao on 14-7-17.
//  Copyright williamzhao 2014年. All rights reserved.
//

#import "AppDelegate.h"

// Import the interfaces
#import "HelloWorldLayer.h"

enum {
	kTagParentNode = 1,
};


#pragma mark - HelloWorldLayer

@interface HelloWorldLayer ()
-(void) addNewSpriteAtPosition:(CGPoint)pos;
-(void) createMenu;
-(void) initPhysics;
@end


@implementation HelloWorldLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	if( (self=[super init])) {
		
		// enable events
#ifdef __CC_PLATFORM_IOS
		self.touchEnabled = YES;
		self.accelerometerEnabled = YES;
#elif defined(__CC_PLATFORM_MAC)
		self.mouseEnabled = YES;
#endif
		
		CGSize s = [[CCDirector sharedDirector] winSize];
		
		// title
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Multi touch the screen" fontName:@"Marker Felt" fontSize:36];
		label.position = ccp( s.width / 2, s.height - 30);
		[self addChild:label z:-1];
		
		// reset button
		[self createMenu];
		
		
		// init physics
		[self initPhysics];
		
		
#if 1
		// Use batch node. Faster
		CCSpriteBatchNode *parent = [CCSpriteBatchNode batchNodeWithFile:@"grossini_dance_atlas.png" capacity:100];
		_spriteTexture = [parent texture];
#else
		// doesn't use batch node. Slower
		_spriteTexture = [[CCTextureCache sharedTextureCache] addImage:@"grossini_dance_atlas.png"];
		CCNode *parent = [CCNode node];
#endif
		[self addChild:parent z:0 tag:kTagParentNode];
		
		[self addNewSpriteAtPosition:ccp(200,200)];
		
		[self scheduleUpdate];
	}
	
	return self;
}

-(void) initPhysics
{
	CGSize s = [[CCDirector sharedDirector] winSize];
	
	_space = cpSpaceNew();
	
	cpSpaceSetGravity( _space, cpv(0, -100) );
	
	//
	// rogue shapes
	// We have to free them manually
	//
	// bottom
	_walls[0] = cpSegmentShapeNew( _space->staticBody, cpv(0,0), cpv(s.width,0), 0.0f);
	
	// top
	_walls[1] = cpSegmentShapeNew( _space->staticBody, cpv(0,s.height), cpv(s.width,s.height), 0.0f);
	
	// left
	_walls[2] = cpSegmentShapeNew( _space->staticBody, cpv(0,0), cpv(0,s.height), 0.0f);
	
	// right
	_walls[3] = cpSegmentShapeNew( _space->staticBody, cpv(s.width,0), cpv(s.width,s.height), 0.0f);
	
	for( int i=0;i<4;i++) {
		cpShapeSetElasticity( _walls[i], 1.0f );
		cpShapeSetFriction( _walls[i], 1.0f );
		cpSpaceAddStaticShape(_space, _walls[i] );
	}
	
	_debugLayer = [CCPhysicsDebugNode debugNodeForCPSpace:_space];
	_debugLayer.visible = NO;
	[self addChild:_debugLayer z:100];
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

-(void) createMenu
{
	// Default font size will be 22 points.
		
}

-(void) addNewSpriteAtPosition:(CGPoint)pos
{
	// physics body
	int num = 4;
	cpVect verts[] = {
		cpv(-24,-54),
		cpv(-24, 54),
		cpv( 24, 54),
		cpv( 24,-54),
	};
	
	cpBody *body = cpBodyNew(1.0f, cpMomentForPoly(1.0f, num, verts, CGPointZero));
	cpBodySetPos( body, pos );
	cpSpaceAddBody(_space, body);
	
	cpShape* shape = cpPolyShapeNew(body, num, verts, CGPointZero);
	cpShapeSetElasticity( shape, 0.5f );
	cpShapeSetFriction( shape, 0.5f );
	cpSpaceAddShape(_space, shape);
	
	// sprite
	CCNode *parent = [self getChildByTag:kTagParentNode];
	int posx = CCRANDOM_0_1() * 200.0f;
	int posy = CCRANDOM_0_1() * 200.0f;
	posx = (posx % 4) * 85;
	posy = (posy % 3) * 121;
	
	CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:_spriteTexture rect:CGRectMake(posx, posy, 85, 121)];
	[parent addChild: sprite];
	[sprite setCPBody:body];
	[sprite setPosition: pos];
}

@end

