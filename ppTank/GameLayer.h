//
//  GameLayer.h
//  ppTank
//
//  Created by williamzhao on 14-7-10.
//  Copyright williamzhao 2014年. All rights reserved.
//

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// Importing Chipmunk headers
#import "chipmunk.h"


#define             BODY_SKIN
#define             WHEEL_SKIN
#define             GUN_SKIN

#import "trackNode.h"
#import "roadblocks.h"

@interface GameLayer : CCLayerColor
{
	int space_pages;
    int currentPage;
    
	CCTexture2D *_spriteTexture; // weak ref
	CCPhysicsDebugNode *_debugLayer; // weak ref
	
	cpSpace *_space; // strong ref
	
	cpShape *_walls[4];
    
    CCSprite* tankSp;
    
    CCLayer* _bgLayer;
    //touchLayer* _touchLayer;
    
    
    // tank and wheels
    cpFloat tankScale;
    cpBody* tankBody;
    int     tankDirection;
    
    cpShape* tankShape;
    cpFloat tankMaxSpeed;  // the wheel rotate speed
    cpBody* wheel1;
    cpBody* wheel2;
    cpBody* wheel3;
    cpBody* wheel4;
    cpBody* wheel5;
    cpBody* wheel6;
    cpBody* wheel7;
    
    cpBody *gearBody1;
    cpBody *gearBody2;
    
    cpBody* gun_gear;
    
    
    cpConstraint* motor1;
    cpConstraint* motor2;
    cpConstraint* motor3;
    cpConstraint* motor4;
    cpConstraint* motor5;
    cpConstraint* motor6;
    cpConstraint* motor7;
    
    cpConstraint* motorGear1;
    cpConstraint* motorGear2;
    
    cpBody *gunBody;
    cpConstraint* gunGearJoint;
    
    trackNode *track2, *track3;
    cpFloat motorSpeed;
    cpConstraint* motor;
    
    CGPoint offsetScreenX;
    BOOL useTrack1;
}

@property (nonatomic, assign) cpConstraint* motor;
@property (nonatomic, assign) cpFloat motorSpeed;

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
