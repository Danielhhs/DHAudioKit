//
//  DHAudioConverter.m
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHAudioConverter.h"
@interface DHAudioConverter ()
@property (nonatomic, readwrite) AudioStreamBasicDescription inFormat;
@end

@implementation DHAudioConverter
#pragma mark - Initializer
- (instancetype) initWithInputAudioFormat:(AudioStreamBasicDescription)inFormat
                        outputAudioFormat:(AudioStreamBasicDescription)outFormat
                                 delegate:(id<DHAudioConverterDelegate>)delegate
{
    return [self initWithInputAudioFormat:inFormat outputAudioFormat:outFormat delegate:delegate delegateQueue:dispatch_get_main_queue()];
}

- (instancetype) initWithInputAudioFormat:(AudioStreamBasicDescription)inFormat
                        outputAudioFormat:(AudioStreamBasicDescription)outFormat
                                 delegate:(id<DHAudioConverterDelegate>)delegate
                            delegateQueue:(dispatch_queue_t)delegateQueue
{
    self = [super init];
    if (self) {
        _inFormat = inFormat;
        _outFormat = outFormat;
        _delegate = delegate;
        _delegateQueue = delegateQueue;
        _status = DHAudioConverterStatusConverting;
    }
    return self;
}

#pragma mark - Default values
- (dispatch_queue_t) delegateQueue
{
    if (_delegateQueue == nil) {
        _delegateQueue = dispatch_get_main_queue();
    }
    return _delegateQueue;
}

#pragma mark - Conversion
- (void) convertData:(NSData *)data numberOfPackets:(int)numberOfPackets
{
    
}

- (void) stopConversion
{
    self.status = DHAudioConverterStatusStopping;
    [self finishConversionIfAllPacketsAreConverted];
}

- (void) cleanUpResource
{
    
}

#pragma mark - For Subclassing
- (void) reportErrorWithErrorCode:(int)errorCode message:(NSString *)message
{
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:errorCode userInfo:@{kDHAudioConverterErrorMessageKey: message}];
    if ([self.delegate respondsToSelector:@selector(audioConverter:didFailToConvertWithError:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate audioConverter:self didFailToConvertWithError:error];
        });
    }
}

- (void) finishConversionIfAllPacketsAreConverted
{
    if (self.status == DHAudioConverterStatusStopping && self.numberOfPacketsReceived == self.numberOfPacketsConverted) {
        self.status =DHAudioConverterStatusStopped;
        if ([self.delegate respondsToSelector:@selector(audioConverterDidStopConversion:)]) {
            dispatch_async(self.delegateQueue, ^{
                [self.delegate audioConverterDidStopConversion:self];
            });
            [self cleanUpResource];
        }
    }
}


@end
