//
//  DHAudioConverterFactory.m
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHAudioConverterFactory.h"
#import "DHAACAudioConverter.h"
#import "DHMP3AudioConverter.h"
#import "DHOpusAudioConverter.h"

@implementation DHAudioConverterFactory


+ (DHAudioConverter *) audioConverterFromType:(DHAudioType)sourceType
                                   sourceFormat:(AudioStreamBasicDescription)sourceFormat
                                         toType:(DHAudioType)destinationType
                                       delegate:(id<DHAudioConverterDelegate>)delegate
{
    AudioStreamBasicDescription destinationFormat = [DHAudioConverterFactory defaultDestinationFormatForAudioType:destinationType
                                                                                                       sourceFormat:sourceFormat];
    
    return [DHAudioConverterFactory audioConverterFromType:sourceType
                                                sourceFormat:sourceFormat
                                                      toType:destinationType
                                           destinationFormat:destinationFormat
                                                    delegate:delegate];
}

+ (DHAudioConverter *) audioConverterFromType:(DHAudioType)sourceType
                                   sourceFormat:(AudioStreamBasicDescription)sourceFormat
                                         toType:(DHAudioType)destinationType
                              destinationFormat:(AudioStreamBasicDescription)destinationFormat
                                       delegate:(id<DHAudioConverterDelegate>)delegate
{
    return [DHAudioConverterFactory audioConverterFromType:sourceType
                                                sourceFormat:sourceFormat
                                                      toType:destinationType
                                           destinationFormat:destinationFormat
                                                    delegate:delegate
                                               delegateQueue:dispatch_get_main_queue()];
}

+ (DHAudioConverter *) audioConverterFromType:(DHAudioType)sourceType
                                   sourceFormat:(AudioStreamBasicDescription)sourceFormat
                                         toType:(DHAudioType)destinationType
                              destinationFormat:(AudioStreamBasicDescription)destinationFormat
                                       delegate:(id<DHAudioConverterDelegate>)delegate
                                  delegateQueue:(dispatch_queue_t)delegateQueue
{
    DHAudioConverter *converter;
    if (destinationType == DHAudioTypeAAC) {
        converter = [[DHAACAudioConverter alloc] initWithInputAudioFormat:sourceFormat
                                                          outputAudioFormat:destinationFormat
                                                                   delegate:delegate
                                                              delegateQueue:delegateQueue];
    } else if (destinationType == DHAudioTypeMP3) {
        converter = [[DHMP3AudioConverter alloc] initWithInputAudioFormat:sourceFormat
                                                          outputAudioFormat:destinationFormat
                                                                   delegate:delegate
                                                              delegateQueue:delegateQueue];
    }
    else if (destinationType == DHAudioTypeOpus) {
        converter = [[DHOpusAudioConverter alloc] initWithInputAudioFormat:sourceFormat
                                                           outputAudioFormat:destinationFormat
                                                                    delegate:delegate
                                                               delegateQueue:delegateQueue];
    }
    return converter;
}


+ (AudioStreamBasicDescription) defaultDestinationFormatForAudioType:(DHAudioType)audioType
                                                        sourceFormat:(AudioStreamBasicDescription)sourceFormat
{
    AudioStreamBasicDescription destinationFormat = {0};
    destinationFormat.mSampleRate = sourceFormat.mSampleRate;
    destinationFormat.mChannelsPerFrame = sourceFormat.mChannelsPerFrame;
    if (audioType == DHAudioTypeAAC) {
        destinationFormat.mFormatID = kAudioFormatMPEG4AAC;
        destinationFormat.mBytesPerPacket = 0;
        destinationFormat.mFramesPerPacket = 1024;      //AAC格式默认framesPerPacket就是1024
        destinationFormat.mBytesPerFrame = 0;
        destinationFormat.mBitsPerChannel = 0;
        destinationFormat.mReserved = 0;
    }
    return destinationFormat;
}

@end

