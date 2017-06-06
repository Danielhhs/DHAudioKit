//
//  DHAudioFilePlayerFactory.h
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DHAudioFilePlayer.h"
#import "DHAudioAttributes.h"

@interface DHAudioFilePlayerFactory : NSObject

+ (DHAudioFilePlayer *) filePlayerForAudioType:(DHAudioType)audioType
                                          data:(NSData *)data
                                   audioFormat:(AudioStreamBasicDescription) audioFormat;

+ (DHAudioFilePlayer *) filePlayerForAudioType:(DHAudioType)audioType
                                          data:(NSData *)data
                                   audioFormat:(AudioStreamBasicDescription) audioFormat
                                packetDuration:(NSTimeInterval)packetDuration;

+ (DHAudioFilePlayer *) filePlayerForAudioType:(DHAudioType)audioType
                                          data:(NSData *)data
                                   audioFormat:(AudioStreamBasicDescription) audioFormat
                                packetDuration:(NSTimeInterval)packetDuration
                                      delegate:(id<DHAudioFilePlayerDelegate>)delegate;


+ (DHAudioFilePlayer *) filePlayerForAudioType:(DHAudioType)audioType
                                      filePath:(NSString *)filePath
                                   audioFormat:(AudioStreamBasicDescription) audioFormat;

+ (DHAudioFilePlayer *) filePlayerForAudioType:(DHAudioType)audioType
                                      filePath:(NSString *)filePath
                                   audioFormat:(AudioStreamBasicDescription) audioFormat
                                packetDuration:(NSTimeInterval)packetDuration;

+ (DHAudioFilePlayer *) filePlayerForAudioType:(DHAudioType)audioType
                                      filePath:(NSString *)filePath
                                   audioFormat:(AudioStreamBasicDescription) audioFormat
                                packetDuration:(NSTimeInterval)packetDuration
                                      delegate:(id<DHAudioFilePlayerDelegate>)delegate;
@end
