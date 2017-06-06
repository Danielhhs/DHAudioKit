//
//  DHAACAudioRecorder.m
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHAACAudioRecorder.h"
#import "DHAudioConverterFactory.h"

@interface DHAACAudioRecorder()<DHAudioConverterDelegate>
@property (nonatomic, strong) DHAudioConverter *converter;
@property (nonatomic) int numberOfPackets;
@end

@implementation DHAACAudioRecorder

- (instancetype) initWithFormat:(AudioStreamBasicDescription)audioFormat
                 packetDuration:(NSTimeInterval) packetDuration
                       delegate:(id<DHAudioRecorderDelegate>)delegate
                  delegateQueue:(dispatch_queue_t)delegateQueue
{
    self = [super initWithFormat:audioFormat
                  packetDuration:packetDuration
                        delegate:delegate
                   delegateQueue:delegateQueue];
    if (self) {
        AudioStreamBasicDescription destinationFormat = [DHAudioConverterFactory
                                                         defaultDestinationFormatForAudioType:DHAudioTypeAAC
                                                         sourceFormat:self.audioFormat];
        _converter = [DHAudioConverterFactory audioConverterFromType:DHAudioTypeLinearPCM
                                                          sourceFormat:self.audioFormat
                                                                toType:DHAudioTypeAAC
                                                     destinationFormat:destinationFormat
                                                              delegate:self
                                                         delegateQueue:self.delegateQueue];
    }
    return self;
}

- (void) processPCMData:(NSData *)pcmData
        numberOfPackets:(int)numberOfPackets
{
    self.numberOfPackets = numberOfPackets;
    [self.converter convertData:pcmData numberOfPackets:numberOfPackets];
}

- (void) cleanUpResource
{
    [self.converter stopConversion];
}

#pragma mark - DHAudioConverterDelegate
- (void) audioConverter:(DHAudioConverter *)converter
didFinishConversionWithData:(NSData *)data
{
    dispatch_async(self.delegateQueue, ^{
        [self.delegate audioRecorder:self
                       didRecordData:data
                     numberOfPackets:self.numberOfPackets];
    });
}

- (void) audioConverterDidStopConversion:(DHAudioConverter *)converter
{
    if ([self.delegate respondsToSelector:@selector(audioRecorderDidFinishRecording:)]) {
        [self.delegate audioRecorderDidFinishRecording:self];
    }
}
@end
