//
//  KPKMetaData.m
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
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

#import "KPKMetaData.h"
#import "KPKXmlFormat.h"
#import "KPKIcon.h"
#import "KPKTree.h"

#import "NSUUID+KeePassKit.h"

@interface KPKMetaData () {
  NSMutableDictionary *_customIconCache;
  NSMutableArray *_customIcons;
}

@end

@implementation KPKMetaData

+ (NSSet *)keyPathsForValuesAffectingEnforceMasterKeyChange {
  return [NSSet setWithObject:NSStringFromSelector(@selector(masterKeyChangeEnforcementInterval))];
}

+ (NSSet *)keyPathsForValuesAffectingRecommendMasterKeyChange {
  return [NSSet setWithObject:NSStringFromSelector(@selector(masterKeyChangeRecommendationInterval))];
}

- (id)init {
  self = [super init];
  if(self){
    _customData = [[NSMutableArray alloc] init];
    _customIcons = [[NSMutableArray alloc] init];
    _customIconCache = [[NSMutableDictionary alloc] init];
    _rounds = 50000;
    _compressionAlgorithm = KPKCompressionGzip;
    _protectNotes = NO;
    _protectPassword = YES;
    _protectTitle = NO;
    _protectUrl = NO;
    _protectUserName = NO;
    _generator = [@"MacPass" copy];
    _databaseName = [NSLocalizedString(@"DATABASE", "") copy];
    _databaseNameChanged = [NSDate date];
    _databaseDescription = [@"" copy];
    _databaseDescriptionChanged = [NSDate date];
    _defaultUserName = [@"" copy];
    _defaultUserNameChanged = [NSDate date];
    _entryTemplatesGroupChanged = [NSDate date];
    _entryTemplatesGroup = [NSUUID nullUUID];
    _trashChanged = [NSDate date];
    _trashUuid = [NSUUID nullUUID];
    _lastSelectedGroup = [NSUUID nullUUID];
    _lastTopVisibleGroup = [NSUUID nullUUID];
    _historyMaxItems = 10;
    _historyMaxSize = 6 * 1024 * 1024; // 6 MB
    _maintenanceHistoryDays = 365;
    /* No Key change recommandation or enforcement */
    _masterKeyChangeRecommendationInterval=-1;
    _masterKeyChangeEnforcementInterval=-1;
  }
  return self;
}

#pragma mark -
#pragma mark Properties
- (NSArray *)customIcons {
  return [_customIcons copy];
}

- (BOOL)isHistoryEnabled {
  return (self.historyMaxItems != -1);
}

- (BOOL)enforceMasterKeyChange {
  return  self.masterKeyChangeEnforcementInterval > -1;
}

- (BOOL)recommendMasterKeyChange {
  return self.masterKeyChangeRecommendationInterval > -1;
}

- (void)setColor:(NSUIColor *)color {
  if(![_color isEqual:color]) {
    /*
     The color for databases does not support a alpha componentet
     thus we just stripp it
     */
    _color = [[color colorWithAlphaComponent:1.0] copy];
  }
}

- (void)setDatabaseName:(NSString *)databaseName {
  if(![_databaseName isEqualToString:databaseName]) {
    _databaseName = [databaseName copy];
    if(_updateTiming) {
      self.databaseNameChanged = [NSDate date];
    }
  }
}

- (void)setDatabaseDescription:(NSString *)databaseDescription {
  if(![_databaseDescription isEqualToString:databaseDescription]) {
    _databaseDescription = [databaseDescription copy];
    if(_updateTiming) {
      self.databaseNameChanged = [NSDate date];
    }
  }
}

- (void)setDefaultUserName:(NSString *)defaultUserName {
  if(![_defaultUserName isEqualToString:defaultUserName]) {
    _defaultUserName = [defaultUserName copy];
    if(_updateTiming) {
      self.defaultUserNameChanged = [NSDate date];
    }
  }
}

- (void)setEntryTemplatesGroup:(NSUUID *)entryTemplatesGroup {
  if(![_entryTemplatesGroup isEqual:entryTemplatesGroup]) {
    _entryTemplatesGroup = entryTemplatesGroup;
    if(_updateTiming) {
      self.entryTemplatesGroupChanged = [NSDate date];
    }
  }
}

- (void)setTrashUuid:(NSUUID *)trashUuid {
  if(![_trashUuid isEqual:trashUuid]) {
    _trashUuid = trashUuid;
    if(_updateTiming) {
      self.trashChanged = [NSDate date];
    }
  }
}


#pragma mark -
#pragma mark Equality
- (BOOL)isEqualToMetaData:(KPKMetaData *)other {
  if(self == other) {
    return YES; // Pointers match
  }
  /* no tree comparison, since the pointers cannot be encoded persitently */
  return self.rounds == other.rounds &&
  self.compressionAlgorithm == other.compressionAlgorithm &&
  [self.generator isEqualToString:other.generator] &&
  [self.databaseName isEqualToString:other.databaseName] &&
  [self.databaseNameChanged isEqualToDate:other.databaseNameChanged] &&
  [self.databaseDescription isEqualToString:other.databaseDescription] &&
  [self.databaseDescriptionChanged isEqualToDate:other.databaseDescriptionChanged] &&
  [self.defaultUserName isEqualToString:other.defaultUserName] &&
  [self.defaultUserNameChanged isEqualToDate:other.defaultUserNameChanged] &&
  self.maintenanceHistoryDays == other.maintenanceHistoryDays &&
  [self.color isEqual:other.color] &&
  [self.masterKeyChanged isEqualToDate:other.masterKeyChanged] &&
  self.recommendMasterKeyChange == other.recommendMasterKeyChange &&
  self.masterKeyChangeRecommendationInterval == other.masterKeyChangeRecommendationInterval &&
  self.enforceMasterKeyChange == other.enforceMasterKeyChange &&
  self.masterKeyChangeEnforcementInterval == other.masterKeyChangeEnforcementInterval &&
  self.protectTitle == other.protectTitle &&
  self.protectUserName == other.protectUserName &&
  self.protectPassword == other.protectPassword &&
  self.protectUrl == other.protectUrl &&
  self.protectNotes == other.protectNotes &&
  self.useTrash == other.useTrash &&
  [self.trashUuid isEqual:other.trashUuid] &&
  [self.trashChanged isEqualToDate:other.trashChanged] &&
  [self.entryTemplatesGroup isEqualTo:other.entryTemplatesGroup] &&
  [self.entryTemplatesGroupChanged isEqualToDate:other.entryTemplatesGroupChanged] &&
  self.isHistoryEnabled == other.isHistoryEnabled &&
  self.historyMaxItems == other.historyMaxItems &&
  self.historyMaxSize == other.historyMaxSize &&
  [self.lastSelectedGroup isEqualTo:other.lastSelectedGroup] &&
  [self.lastTopVisibleGroup isEqualTo:other.lastTopVisibleGroup] &&
  [self.customData isEqualToArray:other.customData] &&
  [self.customIcons isEqualToArray:other.customIcons] &&
  [self.unknownMetaEntryData isEqualToArray:other.unknownMetaEntryData] &&
  self.updateTiming == other.updateTiming;
}

- (BOOL)isEqual:(id)object {
  if([object isKindOfClass:[self class]]) {
    return [self isEqualToMetaData:object];
  }
  return NO;
}

- (void)addCustomIcon:(KPKIcon *)icon {
  [self addCustomIcon:icon atIndex:[_customIcons count]];
}

- (void)addCustomIcon:(KPKIcon *)icon atIndex:(NSUInteger)index {
  index = MIN([_customIcons count], index);
  [self insertObject:icon inCustomIconsAtIndex:index];
}

- (void)removeCustomIcon:(KPKIcon *)icon {
  NSUInteger index = [_customIcons indexOfObject:icon];
  if(index != NSNotFound) {
    [self removeObjectFromCustomIconsAtIndex:index];
  }
}

- (KPKIcon *)findIcon:(NSUUID *)uuid {
  return _customIconCache[uuid];
}

#pragma mark KVO

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
  NSSet *keyPathSet = [super keyPathsForValuesAffectingValueForKey:key];
  if([key isEqualToString:@"isHistoryEnabled"]) {
    keyPathSet = [keyPathSet setByAddingObject:@"historyMaxItems"];
  }
  return keyPathSet;
}

- (NSUInteger)countOfCustomIcons {
  return [_customIcons count];
}

- (void)insertObject:(KPKIcon *)icon inCustomIconsAtIndex:(NSUInteger)index {
  index = MIN([_customIcons count], index);
  [_customIcons insertObject:icon atIndex:index];
  _customIconCache[icon.uuid] = icon;
}

- (void)removeObjectFromCustomIconsAtIndex:(NSUInteger)index {
  index = MIN([_customIcons count], index);
  KPKIcon *icon = _customIcons[index];
  [_customIcons removeObjectAtIndex:index];
  if(icon) {
    [_customIconCache removeObjectForKey:icon.uuid];
  }
}

@end
