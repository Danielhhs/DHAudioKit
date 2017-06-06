//
//  DHAudioConverterFactory.h
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DHAudioConverter.h"
#import "DHAudioAttributes.h"
@interface DHAudioConverterFactory : NSObject
/**
 * Create converter，currently we only support conversion from PCM to other compressed formats；
 * @param sourceType Source Type; currently only Linear PCM
 * @param sourceFormat Source Linear PCM data format
 * @param destinationType Target Type: currently supports AAC，MP3，Opus
 * @param delegate Converter delegate
 * @return instance of AudioConverter
 */
+ (DHAudioConverter *) audioConverterFromType:(DHAudioType)sourceType
                                   sourceFormat:(AudioStreamBasicDescription)sourceFormat
                                         toType:(DHAudioType)destinationType
                                       delegate:(id<DHAudioConverterDelegate>)delegate;

/**
 * Create converter，currently we only support conversion from PCM to other compressed formats；
 * @param sourceType Source Type; currently only Linear PCM
 * @param sourceFormat Source Linear PCM data format
 * @param destinationType Target Type: currently supports AAC，MP3，Opus
 * @param destinationFormat Destination format
 * @param delegate Converter delegate
 * @return instance of AudioConverter
 */
+ (DHAudioConverter *) audioConverterFromType:(DHAudioType)sourceType
                                   sourceFormat:(AudioStreamBasicDescription)sourceFormat
                                         toType:(DHAudioType)destinationType
                              destinationFormat:(AudioStreamBasicDescription)destinationFormat
                                       delegate:(id<DHAudioConverterDelegate>)delegate;

/**
 * Create converter，currently we only support conversion from PCM to other compressed formats；
 * @param sourceType Source Type; currently only Linear PCM
 * @param sourceFormat Source Linear PCM data format
 * @param destinationType Target Type: currently supports AAC，MP3，Opus
 * @param destinationFormat Destination format
 * @param delegate Converter delegate
 * @param delegateQueue the queue on which the delegate is running
 * @return instance of AudioConverter
 */
+ (DHAudioConverter *) audioConverterFromType:(DHAudioType)sourceType
                                   sourceFormat:(AudioStreamBasicDescription)sourceFormat
                                         toType:(DHAudioType)destinationType
                              destinationFormat:(AudioStreamBasicDescription)destinationFormat
                                       delegate:(id<DHAudioConverterDelegate>)delegate
                                  delegateQueue:(dispatch_queue_t)delegateQueue;


/**
 * Default target format for source format;
 * Keep the sample rate and channel count the same;
 */
+ (AudioStreamBasicDescription) defaultDestinationFormatForAudioType:(DHAudioType)audioType
                                                        sourceFormat:(AudioStreamBasicDescription)sourceFormat;
@end
