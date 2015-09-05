//
//  KPKDataStreamWriter.m
//  KeePassKit
//
//  Created by Michael Starke on 29.07.13.
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

#import "KPKDataStreamWriter.h"
@interface KPKDataStreamWriter () {
  NSUInteger _location;
  NSMutableData *_data;
}
@end

@implementation KPKDataStreamWriter

+ (instancetype)streamWriter {
  NSMutableData *mutableData = [[NSMutableData alloc] init];
  return [self streamWriterWithData:mutableData];
}

+ (instancetype)streamWriterWithData:(NSMutableData *)data {
  return [[KPKDataStreamWriter alloc] initWithData:data];
}

- (instancetype)initWithData:(NSMutableData *)data {
  self = [super init];
  if(self) {
    _data = data;
  }
  return self;
}

- (NSData *)data {
  return _data;
}

- (NSData *)writtenData {
  return [_data subdataWithRange:NSMakeRange(0, _location)];
}

- (void)writeData:(NSData *)data {
  [_data appendData:data];
  _location += [data length];
}

- (void)writeString:(NSString *)string encoding:(NSStringEncoding)encoding {
  [self writeData:[string dataUsingEncoding:encoding]];
}

- (void)writeBytes:(const void *)buffer length:(NSUInteger)lenght {
  [self _writeBytes:buffer length:lenght];
}
- (void)writeByte:(UInt8Type)byte {
  [self _writeBytes:&byte length:1];
}
- (void)write2Bytes:(UInt16Type)bytes {
  [self _writeBytes:&bytes length:2];
}
- (void)write4Bytes:(UInt32Type)bytes {
  [self _writeBytes:&bytes length:4];
}

- (void)write8Bytes:(UInt64Type)bytes {
  [self _writeBytes:&bytes length:8];
}

- (void)writeInteger:(NSUInteger)integer {
  [self _writeBytes:&integer length:sizeof(NSUInteger)];
}

- (NSUInteger)location {
  return _location;
}

- (void)reset {
  _location = 0;
}

- (NSUInteger)_writeBytes:(const void *)buffer length:(NSUInteger)length {
  [_data appendBytes:buffer length:length];
  _location += length;
  return length;
}

@end
