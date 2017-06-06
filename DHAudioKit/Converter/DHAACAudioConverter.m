//
//  DHAACAudioConverter.m
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHAACAudioConverter.h"

#import "DHAACAudioConverter.h"
@interface DHAACAudioConverter() {
    AudioConverterRef mConverter;
}
@property (nonatomic, strong) NSData *data;

@property (nonatomic) UInt32 srcBufferSize;
@property (nonatomic) UInt32 srcSizePerPacket;
@property (nonatomic) UInt32 dataOffset;

@end

@implementation DHAACAudioConverter

- (instancetype) initWithInputAudioFormat:(AudioStreamBasicDescription)inFormat
                        outputAudioFormat:(AudioStreamBasicDescription)outFormat
                                 delegate:(id<DHAudioConverterDelegate>)delegate
                            delegateQueue:(dispatch_queue_t)delegateQueue
{
    self = [super initWithInputAudioFormat:inFormat
                         outputAudioFormat:outFormat
                                  delegate:delegate
                             delegateQueue:delegateQueue];
    if (self) {
        encodeQ = dispatch_queue_create("Encode AAC Queue", NULL);
        
        if (![self setupConverterWithInFormat:self.inFormat outFormat:self.outFormat]) {
            return nil;
        }
    }
    return self;
}

- (void) convertData:(NSData *)data numberOfPackets:(int)numberOfPackets
{
    if ([data length] == 0) {
        return;
    }
    self.numberOfPacketsReceived++;
    dispatch_async(encodeQ, ^{
        self.data = data;
        self.dataOffset = 0;
        outBufferSize = numberOfPackets * self.outFormat.mChannelsPerFrame;
        outBuffer = malloc(outBufferSize * sizeof(u_int8_t));
        self.srcBufferSize = self.outFormat.mFramesPerPacket * self.inFormat.mBytesPerPacket;
        self.srcSizePerPacket = self.inFormat.mBytesPerPacket;
        
        AudioBufferList outBufferList = [self setupOutBufferList];
        
        UInt32 ioOutputDataPacketSize = outBufferList.mBuffers[0].mDataByteSize / self.outFormat.mFramesPerPacket / self.outFormat.mChannelsPerFrame;
        AudioStreamPacketDescription *packetDescription = malloc(ioOutputDataPacketSize  * sizeof(AudioStreamBasicDescription));
        OSStatus status = AudioConverterFillComplexBuffer(mConverter, AACInputDataProc, (__bridge void *)self, &ioOutputDataPacketSize, &outBufferList, packetDescription);
        if (status != noErr) {
            [self reportErrorWithErrorCode:status message:@"Fail to convert data"];
        } else {
            NSMutableData *fullData = [NSMutableData data];
            NSData *rawData = [NSData dataWithBytes:outBufferList.mBuffers[0].mData length:outBufferList.mBuffers[0].mDataByteSize];
            [fullData appendData:[self postProcessRawData:rawData packetDescriptions:packetDescription packetCount:ioOutputDataPacketSize]];
            dispatch_async(self.delegateQueue, ^{
                [self.delegate audioConverter:self didFinishConversionWithData:fullData];
            });
            self.numberOfPacketsConverted++;
            
            [self finishConversionIfAllPacketsAreConverted];
        }
    });
}

- (NSData *) postProcessRawData:(NSData *)rawData
             packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions
                    packetCount:(UInt32)packetCount
{
    NSMutableData *fullData = [NSMutableData data];
    char *bytes = (char *)[rawData bytes];
    for (int i = 0; i < packetCount; i++) {
        AudioStreamPacketDescription packetDescription = packetDescriptions[i];
        
        NSData *data = [NSData dataWithBytes:bytes + packetDescription.mStartOffset
                                      length:packetDescription.mDataByteSize];
        
        NSData *adstHeader = [self adtsDataForPacketLength:data.length];
        [fullData appendData:adstHeader];
        [fullData appendData:data];
    }
    return [fullData copy];
}

#pragma mark - Set up
- (BOOL) setupConverterWithInFormat:(AudioStreamBasicDescription)inFormat
                          outFormat:(AudioStreamBasicDescription)outFormat
{
    OSStatus status = AudioConverterNew(&inFormat, &outFormat, &mConverter);
    if (status != noErr) {
        [self reportErrorWithErrorCode:status message:@"Fail to create converter"];
        return NO;
    }
    return YES;
}

- (AudioBufferList) setupOutBufferList
{
    memset(outBuffer, 0, outBufferSize);
    
    AudioBufferList outAudioBufferList = {0};
    outAudioBufferList.mNumberBuffers = 1;
    outAudioBufferList.mBuffers[0].mNumberChannels = self.outFormat.mChannelsPerFrame;
    outAudioBufferList.mBuffers[0].mDataByteSize = (int)outBufferSize;
    outAudioBufferList.mBuffers[0].mData = outBuffer;
    
    return outAudioBufferList;
}

#pragma mark - AAC ADTS header

/**
 *  Add ADTS header at the beginning of each and every AAC packet.
 *  This is needed as MediaCodec encoder generates a packet of raw
 *  AAC data.
 *
 *  Note the packetLen must count in the ADTS header itself.
 *  See: http://wiki.multimedia.cx/index.php?title=ADTS
 *  Also: http://wiki.multimedia.cx/index.php?title=MPEG-4_Audio#Channel_Configurations
 **/
- (NSData*) adtsDataForPacketLength:(NSUInteger)packetLength {
    int adtsLength = 7;
    char *packet = malloc(sizeof(char) * adtsLength);
    // Variables Recycled by addADTStoPacket
    int profile = 2;  //AAC LC
    //39=MediaCodecInfo.CodecProfile7Level.AACObjectELD;
    int freqIdx = [self frequencyIndex];
    int chanCfg = [self channelConfiguration];  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
    NSUInteger fullLength = adtsLength + packetLength;
    // fill in ADTS data
    packet[0] = (char)0xFF; // 11111111     = syncword
    packet[1] = (char)0xF9; // 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}

- (int) frequencyIndex
{
    if (self.outFormat.mSampleRate == 96000) {
        return 0;
    } else if (self.outFormat.mSampleRate == 88200) {
        return 1;
    } else if (self.outFormat.mSampleRate == 64000) {
        return 2;
    }  else if (self.outFormat.mSampleRate == 48000) {
        return 3;
    } else if (self.outFormat.mSampleRate == 44100) {
        return 4;
    } else if (self.outFormat.mSampleRate == 32000) {
        return 5;
    } else if (self.outFormat.mSampleRate == 24000) {
        return 6;
    } else if (self.outFormat.mSampleRate == 22050) {
        return 7;
    } else if (self.outFormat.mSampleRate == 16000) {
        return 8;
    } else if (self.outFormat.mSampleRate == 12000) {
        return 9;
    } else if (self.outFormat.mSampleRate == 11025) {
        return 10;
    } else if (self.outFormat.mSampleRate == 8000) {
        return 11;
    } else if (self.outFormat.mSampleRate == 7350) {
        return 12;
    }
    return -1;
}

- (int) channelConfiguration
{
    if (self.outFormat.mChannelsPerFrame > 0 && self.outFormat.mChannelsPerFrame < 7) {
        return self.outFormat.mChannelsPerFrame;
    } else if (self.outFormat.mChannelsPerFrame == 7) {
        return 8;
    } else {
        return 0;
    }
}



#pragma mark - Converter Call Back
OSStatus AACInputDataProc(AudioConverterRef inAudioConverter,
                          UInt32 *ioNumberDataPackets,
                          AudioBufferList *ioData,
                          AudioStreamPacketDescription **outDataPacketDescription,
                          void *inUserData)
{
    DHAACAudioConverter *converter = (__bridge DHAACAudioConverter *)inUserData;
    
    UInt32 maxPackets = converter.srcBufferSize / converter.srcSizePerPacket;
    if (*ioNumberDataPackets > maxPackets) {
        *ioNumberDataPackets = maxPackets;
    }
    
    char *bytes = (char *)[[converter data] bytes];
    bytes += converter.dataOffset;
    
    UInt32 readBytes = (*ioNumberDataPackets * converter.srcSizePerPacket);
    
    ioData->mBuffers[0].mData = bytes;
    ioData->mBuffers[0].mDataByteSize = readBytes;
    ioData->mBuffers[0].mNumberChannels = converter.outFormat.mChannelsPerFrame;
    
    converter.dataOffset += readBytes;
    
    return noErr;
}

@end
