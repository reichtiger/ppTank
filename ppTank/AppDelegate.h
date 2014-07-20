//
//  AppDelegate.h
//  ppTank
//
//  Created by williamzhao on 14-7-10.
//  Copyright williamzhao 2014年. All rights reserved.
//


#import "cocos2d.h"
#import "SimpleAudioEngine.h"

@interface ppTankAppDelegate : NSObject <NSApplicationDelegate>
{
	NSWindow	*window_;
	CCGLView	*glView_;
}

@property (assign) IBOutlet NSWindow	*window;
@property (assign) IBOutlet CCGLView	*glView;

- (IBAction)toggleFullScreen:(id)sender;

@end
