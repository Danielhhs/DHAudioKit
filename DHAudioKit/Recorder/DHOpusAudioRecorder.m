//
//  DHOpusAudioRecorder.m
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHOpusAudioRecorder.h"
#import "DHAudioConverterFactory.h"

@interface DHOpusAudioRecorder()<DHAudioConverterDelegate>
@property (nonatomic, strong) DHAudioConverter *converter;
@property (nonatomic) int numberOfPackets;
@end

@implementation DHOpusAudioRecorder

- (void) processPCMData:(NSData *)pcmData
        numberOfPackets:(int)numberOfPackets
{
    self.numberOfPackets = numberOfPackets;
    [self.converter convertData:pcmData numberOfPackets:numberOfPackets];
}

- (DHAudioConverter *) converter
{
    if (!_converter) {
        AudioStreamBasicDescription destinationFormat = [DHAudioConverterFactory
                                                         defaultDestinationFormatForAudioType:DHAudioTypeOpus
                                                         sourceFormat:self.audioFormat];
        _converter = [DHAudioConverterFactory audioConverterFromType:DHAudioTypeLinearPCM
                                                          sourceFormat:self.audioFormat
                                                                toType:DHAudioTypeOpus
                                                     destinationFormat:destinationFormat
                                                              delegate:self
                                                         delegateQueue:self.delegateQueue];
    }
    return _converter;
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
