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
    
    
    return  self;
}

@end
