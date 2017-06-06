//
//  DHAudioRecorderFactory.h
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DHAudioAttributes.h"
#import "DHAudioRecorder.h"

@interface DHAudioRecorderFactory : NSObject
+ (DHAudioRecorder *) recorderForType:(DHAudioType)audioType
                         packetDuration:(NSTimeInterval)packetDuration
                               delegate:(id<DHAudioRecorderDelegate>)delegate;

+ (DHAudioRecorder *) recorderForType:(DHAudioType)audioType
                         packetDuration:(NSTimeInterval)packetDuration
                               delegate:(id<DHAudioRecorderDelegate>)delegate
                          delegateQueue:(dispatch_queue_t)delegateQueue;

+ (DHAudioRecorder *) recorderForType:(DHAudioType)audioType
                         packetDuration:(NSTimeInterval)packetDuration
                            audioFormat:(AudioStreamBasicDescription)format
                               delegate:(id<DHAudioRecorderDelegate>)delegate
                          delegateQueue:(dispatch_queue_t)delegateQueue;
@end
