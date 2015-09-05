//
//  KPKIcon.h
//  KeePassKit
//
//  Created by Michael Starke on 20.07.13.
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
  #define NSUIImage NSImage
#else
  #define NSUIImage UIImage
#endif

@interface KPKIcon : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, strong) NSUUID *uuid;
@property (nonatomic, strong) NSUIImage *image;
@property (nonatomic, readonly) NSData *pngData;
@property (nonatomic, readonly) NSString *encodedString;

- (id)initWithImageAtURL:(NSURL *)imageLocation;
- (id)initWithUUID:(NSUUID *)uuid encodedString:(NSString *)encodedString;
- (id)initWithData:(NSData *)data;

- (BOOL)isEqualToIcon:(KPKIcon *)icon;

@end
