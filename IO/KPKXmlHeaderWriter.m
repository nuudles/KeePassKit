//
//  KPKXmlHeaderWriter.m
//  KeePassKit
//
//  Created by Michael Starke on 31.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "KPKXmlHeaderWriter.h"
#import "KPKTree.h"
#import "KPKMetaData.h"
#import "KPKDataStreamWriter.h"
#import "KPKXmlFormat.h"
#import "KPKFormat.h"

#import "NSData+CommonCrypto.h"
#import "NSData+Random.h"
#import "NSUUID+KeePassKit.h"

@interface KPKXmlHeaderWriter () {
  KPKDataStreamWriter *_writer;
}

@property (readwrite, weak) KPKTree *tree;
@property (nonatomic, readwrite, strong) NSData *headerHash;

@end;

@implementation KPKXmlHeaderWriter

- (id)initWithTree:(KPKTree *)tree {
  self = [super init];
  if(self) {
    _tree = tree;
    _masterSeed = [NSData dataWithRandomBytes:32];
    _transformSeed = [NSData dataWithRandomBytes:32];
    _encryptionIv = [NSData dataWithRandomBytes:16];
    _protectedStreamKey = [NSData dataWithRandomBytes:32];
    _streamStartBytes = [NSData dataWithRandomBytes:32];
    _randomStreamID = KPKRandomStreamSalsa20;
  }
  return self;
}

- (void)writeHeaderData:(NSMutableData *)data {
  _writer = [[KPKDataStreamWriter alloc] initWithData:data];
  
  /* Version and Signature */
  [_writer write4Bytes:CFSwapInt32HostToLittle(KPK_XML_SIGNATURE_1)];
  [_writer write4Bytes:CFSwapInt32HostToLittle(KPK_XML_SIGNATURE_2)];
  [_writer write4Bytes:CFSwapInt32HostToLittle(KPK_XML_FILE_VERSION)];
  
  @autoreleasepool {
    uuid_t uuidBytes;
    [[NSUUID AESUUID] getUUIDBytes:uuidBytes];
    NSData *headerData = [NSData dataWithBytesNoCopy:&uuidBytes length:sizeof(uuid_t) freeWhenDone:NO];
    [self _writerHeaderField:KPKHeaderKeyCipherId data:headerData];
    
    uint32_t compressionAlgorithm = CFSwapInt32HostToLittle(_tree.metaData.compressionAlgorithm);
    headerData = [NSData dataWithBytesNoCopy:&compressionAlgorithm length:sizeof(uint32_t) freeWhenDone:NO];
    [self _writerHeaderField:KPKHeaderKeyCompression data:headerData];
    [self _writerHeaderField:KPKHeaderKeyMasterSeed data:_masterSeed];
    [self _writerHeaderField:KPKHeaderKeyTransformSeed data:_transformSeed];
    
    uint64_t rounds = CFSwapInt64HostToLittle(_tree.metaData.rounds);
    headerData = [NSData dataWithBytesNoCopy:&rounds length:sizeof(uint64_t) freeWhenDone:NO];
    [self _writerHeaderField:KPKHeaderKeyTransformRounds data:headerData];
    [self _writerHeaderField:KPKHeaderKeyEncryptionIV data:_encryptionIv];
    [self _writerHeaderField:KPKHeaderKeyProtectedKey data:_protectedStreamKey];
    [self _writerHeaderField:KPKHeaderKeyStartBytes data:_streamStartBytes];
    
    uint32_t randomStreamId = CFSwapInt32HostToLittle(_randomStreamID);
    headerData = [NSData dataWithBytesNoCopy:&randomStreamId length:sizeof(uint32_t) freeWhenDone:NO];
    [self _writerHeaderField:KPKHeaderKeyRandomStreamId data:headerData];

#if TARGET_OS_IPHONE == 0
    uint8_t endBuffer[] = { NSCarriageReturnCharacter, NSNewlineCharacter, NSCarriageReturnCharacter, NSNewlineCharacter };
#else
    uint8_t endBuffer[] = { '\r', '\n', '\r', '\n' };
#endif
    headerData = [NSData dataWithBytesNoCopy:endBuffer length:4 freeWhenDone:NO];
    [self _writerHeaderField:KPKHeaderKeyEndOfHeader data:headerData];
  }
  self.headerHash = [[_writer writtenData] SHA256Hash];
}

- (void)_writerHeaderField:(KPKHeaderKey)key data:(NSData *)data {
  [_writer writeByte:key];
  [_writer write2Bytes:CFSwapInt16HostToLittle([data length])];
  if ([data length] > 0) {
    [_writer writeData:data];
  }
}

@end
