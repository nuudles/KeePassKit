//
//  KPKGroup.m
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
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

#import "KPKGroup.h"

#import "KPKAutotype.h"
#import "KPKDeletedNode.h"
#import "KPKEntry.h"
#import "KPKIconTypes.h"
#import "KPKMetaData.h"
#import "KPKTree.h"
#import "KPKTimeInfo.h"

#import "NSUUID+KeePassKit.h"

@interface KPKGroup () {
@private
  NSMutableArray *_groups;
  NSMutableArray *_entries;
  NSString *_defaultAutoTypeSequence;
}

@end

@implementation KPKGroup

@synthesize title = _title;
@synthesize notes = _notes;

+ (NSUInteger)defaultIcon {
  return KPKIconFolder;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _groups = [[NSMutableArray alloc] initWithCapacity:8];
    _entries = [[NSMutableArray alloc] initWithCapacity:16];
    _isAutoTypeEnabled = KPKInherit;
    _isSearchEnabled = KPKInherit;
    _lastTopVisibleEntry = [NSUUID nullUUID];
    self.updateTiming = YES;
  }
  return self;
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if(self) {
    self.updateTiming = NO;
    self.title = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(title))];
    self.notes = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(notes))];
    _groups = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:NSStringFromSelector(@selector(groups))];
    _entries = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:NSStringFromSelector(@selector(entries))];
    self.isAutoTypeEnabled = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(isAutoTypeEnabled))];
    self.isSearchEnabled = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(isSearchEnabled))];
    self.isExpanded = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(isExpanded))];
    self.defaultAutoTypeSequence = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(defaultAutoTypeSequence))];
    
    for(KPKGroup *group in self.groups) {
      group.parent = self;
    }
    for(KPKEntry *entry in self.entries) {
      entry.parent = self;
    }
    
    self.updateTiming = YES;
  }
  return self;
}

- (void)dealloc {
  [self.undoManager removeAllActionsWithTarget:self];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_title forKey:NSStringFromSelector(@selector(title))];
  [aCoder encodeObject:_notes forKey:NSStringFromSelector(@selector(notes))];
  [aCoder encodeObject:_groups forKey:NSStringFromSelector(@selector(groups))];
  [aCoder encodeObject:_entries forKey:NSStringFromSelector(@selector(entries))];
  [aCoder encodeInteger:_isAutoTypeEnabled forKey:NSStringFromSelector(@selector(isAutoTypeEnabled))];
  [aCoder encodeInteger:_isSearchEnabled forKey:NSStringFromSelector(@selector(isSearchEnabled))];
  [aCoder encodeBool:_isExpanded forKey:NSStringFromSelector(@selector(isExpanded))];
  [aCoder encodeObject:_defaultAutoTypeSequence forKey:NSStringFromSelector(@selector(defaultAutoTypeSequence))];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
  KPKGroup *copy = [[KPKGroup alloc] init];
  copy.uuid = [self.uuid copyWithZone:zone];
  copy->_entries = [[NSMutableArray alloc] initWithArray:_entries copyItems:YES];
  copy->_groups = [[NSMutableArray alloc] initWithArray:_groups copyItems:YES];
  copy.isAutoTypeEnabled = self.isAutoTypeEnabled;
  copy.defaultAutoTypeSequence = self.defaultAutoTypeSequence;
  copy.isSearchEnabled = self.isSearchEnabled;
  copy.isExpanded = self.isExpanded;
  copy.updateTiming = self.updateTiming;
  copy.notes = self.notes;
  copy.iconId = self.iconId;
  copy.iconUUID = self.iconUUID;
  copy.parent = self.parent;
  
  [copy _updateParents];
  
  /* Copy time info at last to ensure valid times */
  copy.timeInfo = [self.timeInfo copyWithZone:zone];
  
  return copy;
}

- (instancetype)copyWithTitle:(NSString *)titleOrNil options:(KPKCopyOptions)options {
  KPKGroup *copy = [self copy];
  
  /* update entry uuids */
  /* update child uuids */
  if(nil == titleOrNil) {
    NSString *format = NSLocalizedStringFromTable(@"KPK_GROUP_COPY_%@", @"KPKLocalizable", "");
    titleOrNil = [[NSString alloc] initWithFormat:format, self.title];
  }
  [copy _updateUUIDs];
  [copy.timeInfo reset];
  copy.title = titleOrNil;
  return copy;
}

- (void)_updateUUIDs {
  self.uuid = [[NSUUID alloc] init];
  for(KPKEntry *entry in self.entries) {
    entry.uuid = [[NSUUID alloc] init];
  }
  for(KPKGroup *group in self.groups) {
    [group _updateUUIDs];
  }
}

- (void)_updateParents {
  for(KPKGroup *childGroup in self.groups) {
    childGroup.parent = self;
    [childGroup _updateParents];
  }
  for(KPKEntry *childEntry in self.entries) {
    childEntry.parent = self;
  }
}

#pragma mark NSPasteboardWriting/Reading

#if TARGET_OS_IPHONE == 0
- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
  return @[KPKGroupUTI];
}

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
  return @[KPKGroupUTI];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
  NSAssert([type isEqualToString:KPKGroupUTI], @"Type needs to be KPKGroupUTI");
  return NSPasteboardReadingAsKeyedArchive;
}

- (id)pasteboardPropertyListForType:(NSString *)type {
  if([type isEqualToString:KPKGroupUTI]) {
    return [NSKeyedArchiver archivedDataWithRootObject:self];
  }
  return nil;
}
#endif

#pragma mark -
#pragma mark Properties
- (NSArray *)groups {
  return [_groups copy];
}

- (NSArray *)entries {
  return  [_entries copy];
}

- (void)setTitle:(NSString *)title {
  if(![_title isEqualToString:title]) {
    _title = [title copy];
    [self wasModified];
  }
}

- (void)setNotes:(NSString *)notes {
  if(![_notes isEqualToString:notes]) {
    _notes = [notes copy];
    [self wasModified];
  }
}

- (NSString *)defaultAutoTypeSequence {
  if(![self hasDefaultAutotypeSequence]) {
    return _defaultAutoTypeSequence;
  }
  if(self.parent) {
    return self.parent.defaultAutoTypeSequence;
  }
  NSString *defaultSequence = [self.tree defaultAutotypeSequence];
  BOOL hasDefault = [defaultSequence length] > 0;
  return hasDefault ? defaultSequence : @"{USERNAME}{TAB}{PASSWORD}{ENTER}";
}

- (BOOL)hasDefaultAutotypeSequence {
  return !([_defaultAutoTypeSequence length] > 0);
}

#pragma mark -
#pragma mark Accessors
- (NSArray *)childEntries {
  NSMutableArray *childEntries = [NSMutableArray arrayWithArray:_entries];
  for(KPKGroup *group in _groups) {
    [childEntries addObjectsFromArray:[group childEntries]];
  }
  return  childEntries;
}

- (NSArray *)childGroups {
  NSMutableArray *childGroups = [NSMutableArray arrayWithArray:_groups];
  for(KPKGroup *group in _groups) {
    [childGroups addObjectsFromArray:[group childGroups]];
  }
  return childGroups;
}

- (KPKGroup *)asGroup {
  return self;
}

#pragma mark -
#pragma mark Group/Entry editing

- (void)remove {
  /* Undo is handled in removeGroup */
  [self.parent _removeGroup:self];
}

- (void)addGroup:(KPKGroup *)group {
  [self addGroup:group atIndex:[_groups count]];
}

- (void)addGroup:(KPKGroup *)group atIndex:(NSUInteger)index {
  group.parent = self;
  group.tree = self.tree;
  index = MAX(0, MIN([_groups count], index));
  [[self.undoManager prepareWithInvocationTarget:self] _removeGroup:group];
  /* Remove entries that might have been added to the deleted objects */
  [self.tree.deletedObjects removeObjectForKey:group.uuid];
  [self insertObject:group inGroupsAtIndex:index];
  [self wasModified];
}

- (void)_removeGroup:(KPKGroup *)group {
  NSUInteger index = [_groups indexOfObject:group];
  if(index != NSNotFound) {
    [[self.undoManager prepareWithInvocationTarget:self] addGroup:group atIndex:index];
    group.parent = nil;
    /* Add group to deleted objects */
    NSAssert(nil == self.tree.deletedObjects[group.uuid], @"Group already registered as deleted!");
    self.tree.deletedObjects[group.uuid] = [[KPKDeletedNode alloc] initWithNode:group];
    [self removeObjectFromGroupsAtIndex:index];
    [self wasModified];
  }
}

- (void)moveToGroup:(KPKGroup *)group {
  [self moveToGroup:group atIndex:group->_groups.count];
}

- (void)moveToGroup:(KPKGroup *)group atIndex:(NSUInteger)index {
  NSUInteger oldIndex = [self.parent.groups indexOfObject:self];
  if(oldIndex == NSNotFound) {
    return; // Parent does not contain us!
  }
  [[self.undoManager prepareWithInvocationTarget:self] moveToGroup:self.parent atIndex:oldIndex];
  [self.parent removeObjectFromGroupsAtIndex:oldIndex];
  self.parent = nil;
  index = MAX(0, MIN([group.groups count], index));
  self.parent = group;
  [group insertObject:self inGroupsAtIndex:index];
  [self wasModified];
  [self wasMoved];
}

- (void)addEntry:(KPKEntry *)entry {
  [self addEntry:entry atIndex:[self.entries count]];
}

- (void)addEntry:(KPKEntry *)entry atIndex:(NSUInteger)index {
  entry.parent = self;
  entry.tree = self.tree;
  index = MAX(0, MIN([_entries count], index));
  [[self.undoManager prepareWithInvocationTarget:self] removeEntry:entry];
  /* Remove the deleted Object */
  [self.tree.deletedObjects removeObjectForKey:entry.uuid];
  [self insertObject:entry inEntriesAtIndex:index];
}

- (void)removeEntry:(KPKEntry *)entry {
  NSUInteger index = [_entries indexOfObject:entry];
  if(NSNotFound != index) {
    [[self.undoManager prepareWithInvocationTarget:self] addEntry:entry atIndex:index];
    [self removeObjectFromEntriesAtIndex:index];
    /* Add the entry to the deleted Objects */
    NSAssert(nil == self.tree.deletedObjects[entry.uuid], @"Entry already marked as deleted!");
    self.tree.deletedObjects[ entry.uuid ] = [[KPKDeletedNode alloc] initWithNode:entry];
    entry.parent = nil;
  }
}

- (void)moveEntry:(KPKEntry *)entry toGroup:(KPKGroup *)toGroup {
  NSUInteger oldIndex = [_entries indexOfObject:entry];
  if(oldIndex != NSNotFound) {
    [[self.undoManager prepareWithInvocationTarget:entry] moveToGroup:self];
    [self removeObjectFromEntriesAtIndex:oldIndex];
    entry.parent = toGroup;
    [toGroup insertObject:entry inEntriesAtIndex:toGroup->_entries.count];
  }
}

- (NSString*)description {
  return [NSString stringWithFormat:@"%@ [image=%ld, name=%@, %@]",
          [self class],
          self.iconId,
          self.title,
          self.timeInfo];
}

#pragma mark Seaching
- (KPKEntry *)entryForUUID:(NSUUID *)uuid {
  NSArray *filterdEntries = [[self childEntries] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    return [uuid isEqual:(NSUUID *)[evaluatedObject uuid]];
  }]];
  NSAssert([filterdEntries count] <= 1, @"NSUUID hast to be unique");
  return [filterdEntries lastObject];
}

- (KPKGroup *)groupForUUID:(NSUUID *)uuid {
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    return [uuid isEqual:(NSUUID *)[evaluatedObject uuid]];
  }];
  NSArray *filteredGroups = [[self childGroups] filteredArrayUsingPredicate:predicate];
  NSAssert([filteredGroups count] <= 1, @"NSUUID hast to be unique");
  return  [filteredGroups lastObject];
}

- (NSArray *)searchableChildEntries {
  NSMutableArray *searchableEntries;
  if([self isSearchable]) {
    searchableEntries = [NSMutableArray arrayWithArray:_entries];
  }
  else {
    searchableEntries = [[NSMutableArray alloc] init];
  }
  for(KPKGroup *group in _groups) {
    [searchableEntries addObjectsFromArray:[group searchableChildEntries]];
  }
  return searchableEntries;
}

- (BOOL)isSearchable {
  if(self.isTrash || self.isTrashed) {
    return NO;
  }
  switch(self.isSearchEnabled) {
    case KPKInherit:
      return self.parent ? [self.parent isSearchable] : YES;
      
    case KPKInheritNO:
      return NO;
      
    case KPKInheritYES:
      return YES;
  }
}

#pragma mark Autotype
- (NSArray *)autotypeableChildEntries {
  NSMutableArray *autotypeEntries;
  if([self isAutotypeable]) {
    /* KPKEntries have their own autotype settings, hence we need to filter them as well */
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
      NSAssert([evaluatedObject isKindOfClass:[KPKEntry class]], @"entry array should contain only KPKEntry objects");
      KPKEntry *entry = evaluatedObject;
      return entry.autotype.isEnabled;
    }];
    autotypeEntries = [NSMutableArray arrayWithArray:[_entries filteredArrayUsingPredicate:predicate]];
  }
  else {
    autotypeEntries = [[NSMutableArray alloc] init];
  }
  for(KPKGroup *group in _groups) {
    [autotypeEntries addObjectsFromArray:[group autotypeableChildEntries]];
  }
  return autotypeEntries;
}

- (BOOL)isAutotypeable {
  if(self.isTrash || self.isTrashed){
    return NO;
  }
  switch(self.isAutoTypeEnabled) {
    case KPKInherit:
      /* Default is YES, so fall back to YES if no parent is set, aplies to root node as well */
      return self.parent ? self.parent.isAutoTypeEnabled : YES;
      
    case KPKInheritNO:
      return NO;
      
    case KPKInheritYES:
      return YES;
  }
}

#pragma mark Hierarchy

- (NSString *)breadcrumb {
  return [self breadcrumbWithSeparator:@"."];
}

- (NSString *)breadcrumbWithSeparator:(NSString *)separator {
  if(self.parent && (self.rootGroup != self.parent)) {
    return [[self.parent breadcrumb] stringByAppendingFormat:@" > %@", self.title];
  }
  return self.title;
}

- (NSIndexPath *)indexPath {
  if(self.parent) {
    NSUInteger myIndex = [self.parent.groups indexOfObject:self];
    NSIndexPath *parentIndexPath = [self.parent indexPath];
    NSAssert( nil != parentIndexPath, @"existing parents should always yield a indexPath");
    return [parentIndexPath indexPathByAddingIndex:myIndex];
  }
  NSUInteger indexes[] = {0,0};
  return [[NSIndexPath alloc] initWithIndexes:indexes length:(sizeof(indexes)/sizeof(NSUInteger))];
}

#pragma mark Delete

- (void)clear {
  NSUInteger groupCount = [_groups count];
  for(NSInteger index = (groupCount - 1); index > -1; index--) {
    [self removeObjectFromGroupsAtIndex:index];
  }
  NSUInteger entryCount = [_entries count];
  for(NSInteger index = (entryCount - 1); index > -1; index--) {
    [self removeObjectFromEntriesAtIndex:index];
  }
}

#pragma mark -
#pragma mark KVC

- (NSUInteger)countOfEntries {
  return [_entries count];
}

- (void)insertObject:(KPKEntry *)entry inEntriesAtIndex:(NSUInteger)index {
  [_entries insertObject:entry atIndex:index];
}

- (void)removeObjectFromEntriesAtIndex:(NSUInteger)index {
  [_entries removeObjectAtIndex:index];
}

- (NSUInteger)countOfGroups {
  return [_groups count];
}

- (void)insertObject:(KPKGroup *)group inGroupsAtIndex:(NSUInteger)index {
  [_groups insertObject:group atIndex:index];
}

- (void)removeObjectFromGroupsAtIndex:(NSUInteger)index {
  [_groups removeObjectAtIndex:index];
}

@end

