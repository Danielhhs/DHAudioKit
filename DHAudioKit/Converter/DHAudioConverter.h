//
//  DHAudioConverter.h
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

static const NSString *kDHAudioConverterErrorMessageKey = @"AudioConverterErrorMessage";

typedef NS_ENUM(NSInteger, DHAudioConverterStatus) {
    DHAudioConverterStatusConverting,
    DHAudioConverterStatusStopping,
    DHAudioConverterStatusStopped,
};

@class DHAudioConverter;
@protocol DHAudioConverterDelegate <NSObject>

/**
 * Notify the delegate that the audio data has been converted successfully.
 * @param converter the converter;
 * @param data the audio data in the target format;
 */
- (void) audioConverter:(DHAudioConverter *)converter didFinishConversionWithData:(NSData *)data;

@optional

/**
 * Notify the delegate when errors occurred during conversion. The error code is different due to the target format.
    * AAC: Audio Queue error code;
    * MP3: lame error code;
    * Opus: libOpus error code;
 *
 * @param converter the converter
 * @param error detailed error information
 */
- (void) audioConverter:(DHAudioConverter *)converter didFailToConvertWithError:(NSError *)error;

/**
 * Notify the delegate that the conversion process is finished;
 *
 * @discussion Calling `stopConversion` will only notify the converter to stop conversion. There still might be some data left in the buffer or waiting for conversion. When this method is called, the conversion process is completely finished;
 */
- (void) audioConverterDidStopConversion:(DHAudioConverter *)converter;

@end

@interface DHAudioConverter : NSObject {
    UInt32 outBufferSize;
    u_int8_t *outBuffer;
    dispatch_queue_t encodeQ;
}

#pragma mark - Instance Variables
/**
 * The format of the source PCM audio data;
 */
@property (nonatomic, readonly) AudioStreamBasicDescription inFormat;

/**
 * The format of the target audio data;
 */
@property (nonatomic) AudioStreamBasicDescription outFormat;

/**
 * The bitrate of the output audio;
 */
@property (nonatomic) UInt32 bitRate;

/**
 * The delegate to handle conversion events;
 */
@property (nonatomic, weak) id<DHAudioConverterDelegate> delegate;

/**
 * The queue on which the delegate is running;
 */
@property (nonatomic, weak) dispatch_queue_t delegateQueue;

/**
 * The status of the converter; See`DHAudioConverterStatus`;
 */
@property (nonatomic) DHAudioConverterStatus status;

#pragma mark - Public APIs
/**
 * Designated Initializer
 * @param inFormat Source audio format
 * @param outFormat Target audio format
 * @param delegate the delegate
 */
- (instancetype) initWithInputAudioFormat:(AudioStreamBasicDescription)inFormat
                        outputAudioFormat:(AudioStreamBasicDescription)outFormat
                                 delegate:(id<DHAudioConverterDelegate>)delegate;

/**
 * Designated Initializer
 * @param inFormat Source audio format
 * @param outFormat Target audio format
 * @param delegate the delegate
 * @param delegateQueue the queue on which the delegate is running;
 */
- (instancetype) initWithInputAudioFormat:(AudioStreamBasicDescription)inFormat
                        outputAudioFormat:(AudioStreamBasicDescription)outFormat
                                 delegate:(id<DHAudioConverterDelegate>)delegate
                            delegateQueue:(dispatch_queue_t)delegateQueue;

/**
 * Convert the audio data; The conversion process is running asychronously. So the result will not be returned immediately.
 * Delegate will be notified in `audioConverter:didFinishConversionWithData:`
 */
- (void) convertData:(NSData *)data
     numberOfPackets:(int)numberOfPackets;

/**
 * Notify the converter to stop conversion. But the conversion process will not stop immediately;
 * Delegate will be notified in `audioConverterDidStopConversion`;
 */
- (void) stopConversion;


#pragma mark - For Subclassing
/**
 * For Subclassing;
 * Subclass can call this method to report error to the delegate;
 * For more details about the error codes, please refer to :https://www.osstatus.com/search/results?platform=all&framework=all&search=1718449215
 */
- (void) reportErrorWithErrorCode:(int)error
                          message:(NSString *)message;

/**
 * For Subclassing;
 * Subclass can call this method to notify the delegate that all the conversion is done;
 */
- (void) finishConversionIfAllPacketsAreConverted;

/**
 * For Subclassing;
 * Subclass can override this class to clean up converter resource;
 */
- (void) cleanUpResource;

//These two properties are used to tell whether the conversion is finished;
@property (nonatomic) NSInteger numberOfPacketsReceived;
@property (nonatomic) NSInteger numberOfPacketsConverted;
@end
