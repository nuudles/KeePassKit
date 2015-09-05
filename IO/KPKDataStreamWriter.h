//
//  KPKDataStreamWriter.h
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

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE == 0
  #define UInt8Type uint8
  #define UInt16Type uint16
  #define UInt32Type uint32
  #define UInt64Type uint64
#else
  #define UInt8Type uint8_t
  #define UInt16Type uint16_t
  #define UInt32Type uint32_t
  #define UInt64Type uint64_t
#endif

@interface KPKDataStreamWriter : NSObject

+ (instancetype)streamWriterWithData:(NSMutableData *)data;
+ (instancetype)streamWriter;

- (instancetype)initWithData:(NSMutableData *)data;

- (void)writeData:(NSData *)data;
- (void)writeString:(NSString *)string encoding:(NSStringEncoding)encoding;
- (void)writeBytes:(const void *)buffer length:(NSUInteger)lenght;
- (void)writeByte:(UInt8Type)byte;
- (void)write2Bytes:(UInt16Type)bytes;
- (void)write4Bytes:(UInt32Type)bytes;
- (void)write8Bytes:(UInt64Type)bytes;
- (void)writeInteger:(NSUInteger)integer;

- (NSData *)data;
- (NSData *)writtenData;
- (NSUInteger)location;
- (void)reset;

@end
