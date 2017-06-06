//
//  DHAudioFilePlayerFactory.m
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHAudioFilePlayerFactory.h"
#import "DHAudioFilePlayer.h"
#import "DHPCMAudioFilePlayer.h"
#import "DHOpusAudioFilePlayer.h"
@implementation DHAudioFilePlayerFactory
+ (DHAudioFilePlayer *) filePlayerForAudioType:(DHAudioType)audioType
                                            data:(NSData *)data
                                     audioFormat:(AudioStreamBasicDescription) audioFormat
{
    return [DHAudioFilePlayerFactory filePlayerForAudioType:audioType
                                                         data:data
                                                  audioFormat:audioFormat
                                               packetDuration:0];
}

+ (DHAudioFilePlayer *) filePlayerForAudioType:(DHAudioType)audioType
                                            data:(NSData *)data
                                     audioFormat:(AudioStreamBasicDescription) audioFormat
                                  packetDuration:(NSTimeInterval)packetDuration
{
    return [DHAudioFilePlayerFactory filePlayerForAudioType:audioType
                                                         data:data
                                                  audioFormat:audioFormat
                                               packetDuration:packetDuration
                                                     delegate:nil];
}

+ (DHAudioFilePlayer *) filePlayerForAudioType:(DHAudioType)audioType
                                            data:(NSData *)data
                                     audioFormat:(AudioStreamBasicDescription) audioFormat
                                  packetDuration:(NSTimeInterval)packetDuration
                                        delegate:(id<DHAudioFilePlayerDelegate>)delegate
{
    switch (audioType) {
        case DHAudioTypeAAC:
        case DHAudioTypeMP3:
            return [[DHAudioFilePlayer alloc] initWithData:data
                                              packetDuration:packetDuration
                                                 audioFormat:audioFormat
                                                    delegate:delegate];
        case DHAudioTypeOpus:
            return [[DHOpusAudioFilePlayer alloc] initWithData:data
                                                  packetDuration:packetDuration
                                                     audioFormat:audioFormat
                                                        delegate:delegate];
        case DHAudioTypeLinearPCM:
            return [[DHPCMAudioFilePlayer alloc] initWithData:data
                                                 packetDuration:packetDuration
                                                    audioFormat:audioFormat
                                                       delegate:delegate];
        default:
            break;
    }
}

+ (DHAudioFilePlayer *) filePlayerForAudioType:(DHAudioType)audioType
                                        filePath:(NSString *)filePath
                                     audioFormat:(AudioStreamBasicDescription) audioFormat
{
    return [DHAudioFilePlayerFactory filePlayerForAudioType:audioType
                                                     filePath:filePath
                                                  audioFormat:audioFormat
                                               packetDuration:0];
}

+ (DHAudioFilePlayer *) filePlayerForAudioType:(DHAudioType)audioType
                                        filePath:(NSString *)filePath
                                     audioFormat:(AudioStreamBasicDescription)audioFormat
                                  packetDuration:(NSTimeInterval)packetDuration
{
    return [DHAudioFilePlayerFactory filePlayerForAudioType:audioType
                                                     filePath:filePath
                                                  audioFormat:audioFormat
                                               packetDuration:packetDuration
                                                     delegate:nil];
}

+ (DHAudioFilePlayer *) filePlayerForAudioType:(DHAudioType)audioType
                                        filePath:(NSString *)filePath
                                     audioFormat:(AudioStreamBasicDescription)audioFormat
                                  packetDuration:(NSTimeInterval)packetDuration
                                        delegate:(id<DHAudioFilePlayerDelegate>)delegate
{
    switch (audioType) {
        case DHAudioTypeAAC:
        case DHAudioTypeMP3:
            return [[DHAudioFilePlayer alloc] initWithFilePath:filePath
                                                  packetDuration:packetDuration
                                                     audioFormat:audioFormat
                                                        delegate:delegate];
        case DHAudioTypeOpus:
            return [[DHOpusAudioFilePlayer alloc] initWithFilePath:filePath
                                                      packetDuration:packetDuration
                                                         audioFormat:audioFormat
                                                            delegate:delegate];
        case DHAudioTypeLinearPCM:
            return [[DHPCMAudioFilePlayer alloc] initWithFilePath:filePath
                                                     packetDuration:packetDuration
                                                        audioFormat:audioFormat
                                                           delegate:delegate];
        default:
            break;
    }
}
@end
