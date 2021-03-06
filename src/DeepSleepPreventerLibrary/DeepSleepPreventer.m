//
//  DeepSleepPreventer.m
//  iPhoneInsomnia
//
//  Created by Marco Peluso on 20.08.09.
//  Copyright 2009 Marco Peluso. All rights reserved.
//

#import "DeepSleepPreventer.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface DeepSleepPreventer (Private)
- (void)setUpAudioSession;
- (void)playPreventSleepSound;
@end


@implementation DeepSleepPreventer

@synthesize audioPlayer;
@synthesize preventSleepTimer;


#pragma mark -
#pragma mark Inits and DidLoads

- (id)init
{
  if ((self = [super init]))
	{
		[self setUpAudioSession];
		
		NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"noSound" ofType:@"wav"];
		NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:soundFilePath];
		
		self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
		[fileURL release];
		[self.audioPlayer prepareToPlay];
		
		// You may want to set this to 0.0 even if your sound file is silent.
		// I don't know if this affects battery life, but it can't hurt.
		[self.audioPlayer setVolume:0.0];
	}
  return self;
}


#pragma mark -
#pragma mark Dealloc and UnLoads

- (void)dealloc
{
	[preventSleepTimer release];
	[audioPlayer release];
	[super dealloc];
}


#pragma mark -
#pragma mark Public Methods

- (void)startPreventSleep
{
  [self stopPreventSleep];
	self.preventSleepTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0]
													  interval:5.0
														target:self
													  selector:@selector(playPreventSleepSound)
													  userInfo:nil
													   repeats:YES];

	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	[runLoop addTimer:self.preventSleepTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopPreventSleep
{
	[self.preventSleepTimer invalidate];
	self.preventSleepTimer = nil;
}


#pragma mark -
#pragma mark Private

- (void)setUpAudioSession
{
	// Initialize audio session
		AudioSessionInitialize (
			NULL,							// Use NULL to use the default (main) run loop.
			NULL,							// Use NULL to use the default run loop mode.
			NULL,							// A reference to your interruption listener callback function. See “Responding to Audio Session Interruptions” for a description of how to write and use an interruption callback function.
			NULL							// Data you intend to be passed to your interruption listener callback function when the audio session object invokes it.
		);
		
		// Set up audio session category to kAudioSessionCategory_MediaPlayback.
    // We need that specific category: http://developer.apple.com/iphone/library/qa/qa2008/qa1626.html
		UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;	
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
		
		// Set up audio session playback mixing behavior.
		// kAudioSessionCategory_MediaPlayback usually prevents playback mixing, so we allow it here. This way, we don't get in the way of other sound playback in an application.
		// This property has a value of false (0) by default. When the audio session category changes, such as during an interruption, the value of this property reverts to false. To regain mixing behavior you must then set this property again.

		// Always check to see if setting this property succeeds or fails, and react appropriately; behavior may change in future releases of iPhone OS.
		OSStatus propertySetError = 0;
		UInt32 allowMixing = true;
 
    propertySetError = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(allowMixing), &allowMixing);
		
		if (propertySetError)
			DLog(@"Error setting kAudioSessionProperty_OverrideCategoryMixWithOthers: %d", propertySetError);

		// Activate audio session
		OSStatus activationResult = 0;
		activationResult = AudioSessionSetActive(true);
		
		if (activationResult)
			DLog(@"AudioSession is active");
}

- (void)playPreventSleepSound
{
	[self.audioPlayer play];
}

@end
