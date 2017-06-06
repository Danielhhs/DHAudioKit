//
//  DHAudioRecorderFactory.m
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHAudioRecorderFactory.h"
#import "DHAudioRecorder.h"
#import "DHAACAudioRecorder.h"
#import "DHMP3AudioRecorder.h"
#import "DHOpusAudioRecorder.h"

@implementation DHAudioRecorderFactory
+ (DHAudioRecorder *) recorderForType:(DHAudioType)audioType
                         packetDuration:(NSTimeInterval)packetDuration
                               delegate:(id<DHAudioRecorderDelegate>)delegate
{
    return [DHAudioRecorderFactory recorderForType:audioType
                                      packetDuration:packetDuration
                                            delegate:delegate
                                       delegateQueue:dispatch_get_main_queue()];
}

+ (DHAudioRecorder *) recorderForType:(DHAudioType)audioType
                         packetDuration:(NSTimeInterval)packetDuration
                               delegate:(id<DHAudioRecorderDelegate>)delegate
                          delegateQueue:(dispatch_queue_t)delegateQueue
{
    AudioStreamBasicDescription format = [DHAudioRecorder defaultFormat];
    return [DHAudioRecorderFactory recorderForType:audioType
                                      packetDuration:packetDuration
                                         audioFormat:format
                                            delegate:delegate
                                       delegateQueue:delegateQueue];
}

+ (DHAudioRecorder *) recorderForType:(DHAudioType)audioType
                         packetDuration:(NSTimeInterval)packetDuration
                            audioFormat:(AudioStreamBasicDescription)format
                               delegate:(id<DHAudioRecorderDelegate>)delegate
                          delegateQueue:(dispatch_queue_t)delegateQueue
{
    DHAudioRecorder *recorder;
    switch (audioType) {
        case DHAudioTypeLinearPCM:
            recorder = [[DHAudioRecorder alloc] initWithFormat:format
                                                  packetDuration:packetDuration
                                                        delegate:delegate
                                                   delegateQueue:delegateQueue];
            break;
        case DHAudioTypeAAC:
            recorder = [[DHAACAudioRecorder alloc] initWithFormat:format
                                                     packetDuration:packetDuration
                                                           delegate:delegate
                                                      delegateQueue:delegateQueue];
            break;
        case DHAudioTypeMP3:
            recorder = [[DHMP3AudioRecorder alloc] initWithFormat:format
                                                     packetDuration:packetDuration
                                                           delegate:delegate
                                                      delegateQueue:delegateQueue];
            break;
        case DHAudioTypeOpus:
            recorder = [[DHOpusAudioRecorder alloc] initWithFormat:format
                                                      packetDuration:packetDuration
                                                            delegate:delegate
                                                       delegateQueue:delegateQueue];
            break;
        default:
            break;
    }
    return recorder;
}

@end
