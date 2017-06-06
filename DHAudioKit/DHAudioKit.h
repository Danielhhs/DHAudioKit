//
//  DHAudioKit.h
//  DHAudioKit
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for DHAudioKit.
FOUNDATION_EXPORT double DHAudioKitVersionNumber;

//! Project version string for DHAudioKit.
FOUNDATION_EXPORT const unsigned char DHAudioKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <DHAudioKit/PublicHeader.h>
#import "DHAudioAttributes.h"

//Recorders
#import "DHAudioRecorder.h"
#import "DHAACAudioRecorder.h"
#import "DHMP3AudioRecorder.h"
#import "DHOpusAudioRecorder.h"
#import "DHAudioRecorderFactory.h"

//Converters
#import "DHAudioConverter.h"
#import "DHAACAudioConverter.h"
#import "DHMP3AudioConverter.h"
#import "DHOpusAudioConverter.h"
#import "DHAudioConverterFactory.h"

