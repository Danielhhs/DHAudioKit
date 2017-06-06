//
//  DHOpusAudioFilePlayer.m
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHOpusAudioFilePlayer.h"
#import "DHOpusDecoder.h"

@interface DHOpusAudioFilePlayer() <DHOpusDecoderDelegate>
@property (nonatomic, strong) DHOpusDecoder *decoder;
@end

@implementation DHOpusAudioFilePlayer

- (void) setupPlayerWithFile:(NSString *)filePath
{
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    [self.decoder decodeOpusData:data];
    self.status = DHAudioPlayerStatusConvertingData;
}

- (void) setupPlayerWithData:(NSData *)data
{
    [self.decoder decodeOpusData:data];
    self.status = DHAudioPlayerStatusConvertingData;
}

- (DHOpusDecoder *) decoder
{
    if (!_decoder) {
        _decoder = [[DHOpusDecoder alloc] initWithSampleRate:self.audioFormat.mSampleRate
                                              numberOfChannels:self.audioFormat.mChannelsPerFrame
                                                packetDuration:self.packetDuration
                                                      delegate:self];
    }
    return _decoder;
}

#pragma mark - DHOpusDecoderDelegate
- (void) opusDecoder:(DHOpusDecoder *)decoder
didFinishDecodingWithResultPCMData:(NSData *)pcmData
{
    [self updateWithPlayableData:[self playablePCMDataWithData:pcmData]];
}

- (NSData *) playablePCMDataWithData:(NSData *)data
{
    char path[256];
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
                          stringByAppendingString:@"/temp_pcm_intermidate.wav"];
    [filePath getCString:path maxLength:256 encoding:NSUTF8StringEncoding];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    
    AudioFileID audioFile;
    AudioStreamBasicDescription mDataFormat = self.audioFormat;
    
    CFURLRef audioFileURL = CFURLCreateFromFileSystemRepresentation(NULL, (const UInt8 *)path, strlen(path), false);
    AudioFileCreateWithURL(audioFileURL, kAudioFileWAVEType, &mDataFormat, kAudioFileFlags_EraseFile, &audioFile);
    UInt32 fileLength = (UInt32)[data length];
    AudioFileWriteBytes(audioFile, false, 0, &fileLength, [data bytes]);
    AudioFileClose(audioFile);
    
    return [NSData dataWithContentsOfFile:filePath];
}
@end

