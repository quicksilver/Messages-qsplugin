//
//  QSiChatMediator.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 7/5/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "QSiChatMediator.h"

#import <InstantMessage/IMService.h>

#import "Messages.h"

//#import "InstantMessage/AddressBookPeople.h"
//#import "InstantMessage/DaemonicService.h"
//#import "InstantMessage/IMService.h"
//#import "InstantMessage/IMService-IMService_GetService.h"
//#import "InstantMessage/AddressCard.h"
//#import <AddressBook/AddressBook.h>
//#import "InstantMessage/AddressCard-AddressBook.h"

@implementation QSiChatMediator
- (id) init
{
  self = [super init];
  if (self != nil) {
    presenceController = [[iChatPresenceController alloc] init];
  }
  return self;
}

- (NSString *)uniqueIDForAIMAccount:(NSString *)account {
	ABAddressBook *book = [ABAddressBook sharedAddressBook];
  ABSearchElement *search = [ABPerson searchElementForProperty:kABAIMInstantProperty label:nil key:nil value:account comparison:kABEqualCaseInsensitive];
  NSArray *results = [[ABAddressBook sharedAddressBook] recordsMatchingSearchElement:search];
	if (![results count]) return nil;
	return [[results lastObject] uniqueId];
}

- (BOOL)contactIsAvailable:(QSObject *)contact
{
    ABPerson *person = [contact ABPerson];
    for (IMService *service in [IMService allServices]) {
        for (NSString *name in [service screenNamesForPerson:person]) {
            NSDictionary *userInfo = [service infoForScreenName:name];
            NSUInteger status = [[userInfo objectForKey:IMPersonStatusKey] integerValue];
            if (status & (IMPersonStatusAvailable | IMPersonStatusIdle | IMPersonStatusAway)) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)accountIsAvailable:(NSString *)accountID
{
    return [[self availableAccounts] containsObject:accountID];
}

- (NSArray *)availableAccounts {
  return [presenceController onlineBuddies];
	NSArray *array = [self onlineBuddies];
	array = [QSLib scoredArrayForString:nil inSet:array]; 	
	return array;
}

- (int) capabilitiesOfAccount:(NSString *)accountID {
	if ([accountID hasPrefix:@"AIM:"]) return QSChatAnyMask;
	return 0;
}

- (NSString *)statusForAccount:(NSString *)accountID
{
    return nil;
}

- (BOOL)initiateChat:(QSChatType)serviceType withAccounts:(NSArray *)accountIDs info:(id)info {
	//if (![[accountIDs lastObject] hasPrefix:@"AIM:"]) return NO;
  for (NSString *account in accountIDs) {
    int offset = [account rangeOfString:@":"].location;
    NSString *screenName = [account substringFromIndex:offset + 1];
//    NSString *personID = [self uniqueIDForAIMAccount:accountID];
    switch (serviceType) {
      case QSChatInitType:
      {
        MessagesApplication *MessagesApp = [SBApplication applicationWithBundleIdentifier:@"com.apple.iChat"];
        MessagesBuddy *buddy = [MessagesApp.buddies objectWithName:screenName];
        
        [MessagesApp send:@"" to:buddy];
      }
        //      if (personID) return [self chatWithPerson:personID];
        //      
        //      NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"iChat:compose?service=AIM&id=%@&style=im", [aimAccount URLEncoding]]]; 	
        //      [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:url] withAppBundleIdentifier:@"com.apple.iChat"
        //                                      options:nil additionalEventParamDescriptor:nil launchIdentifiers:nil];
        return YES; 			
        break;
      case QSChatTextType:
        [self sendText:info toAccount:screenName];
        break;
      case QSChatFileType:
        [self sendFile:info toAccount:screenName];
        break;
      case QSChatAudioType:
        [self initiateAudioWithAccount:screenName];
        break;
      case QSChatVideoType:
        [self initiateVideoWithAccount:screenName];
        break;
      case QSChatRoomType:
        break;
      default:
        break;
        
    }
  }
  return NO;
                   }

//much simpler thar applescript is URL : iChat:compose?service = AIM&id = ybizeul@mac.com&style = im
//iChat:compose?service = AIM&id = ecasadei&style = audiochat

- (BOOL)chatWithPerson:(NSString *)personID {
	if (![[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"iChat:compose?card=%@&style=im", personID]]])
		NSLog(@"could not open");
	return YES; 	
}

- (BOOL)sendItem:(QSObject *)item toAccounts:(NSArray *)accounts
{
    BOOL sent = NO;
    for (QSObject *buddy in accounts) {
        NSString *accountID = [buddy objectForType:QSIMAccountType];
        if ([[item primaryType] isEqualToString:QSFilePathType]) {
            sent = [self sendFiles:[item arrayForType:QSFilePathType] toAccount:accountID];
        } else {
            sent = [self sendText:[item stringValue] toAccount:accountID];
        }
    }
    return sent;
}

- (BOOL)sendText:(NSString *)text toAccount:(NSString *)accountID {
    MessagesApplication *MessagesApp = [SBApplication applicationWithBundleIdentifier:@"com.apple.iChat"];
    MessagesBuddy *buddy = [MessagesApp.buddies objectWithName:accountID];
    
    [MessagesApp send:text to:buddy];
    return YES;
}



- (BOOL)sendFiles:(NSArray *)paths toAccount:(NSString *)accountID {
    MessagesApplication *MessagesApp = [SBApplication applicationWithBundleIdentifier:@"com.apple.iChat"];
    MessagesBuddy *buddy = [MessagesApp.buddies objectWithName:accountID];

    for (NSString *path in paths) {
        [MessagesApp send:path to:buddy];
    }
  
  
  
  //
  //	[self sendText:@" " toAccount:accountID];
  //	
  //	foreach(path, paths) {
  //		//NSLog(@"path %@", path);
  //		NSPasteboard *pb = [NSPasteboard generalPasteboard];
  //		[pb declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];
  //		[pb setPropertyList:[NSArray arrayWithObject:path] forType:NSFilenamesPboardType];
  //		
  //		[[NSWorkspace sharedWorkspace] launchApplication:@"iChat"];
  //		
  //		QSForcePaste();
  //		
  //		CGInhibitLocalEvents(YES);
  //		CGEnableEventStateCombining(NO);
  //		CGSetLocalEventsFilterDuringSupressionState(kCGEventFilterMaskPermitAllEvents, kCGEventSupressionStateSupressionInterval);
  //		CGPostKeyboardEvent(0, 36, true);
  //		CGPostKeyboardEvent(0, 36, false);
  //		CGEnableEventStateCombining(YES);
  //		CGInhibitLocalEvents(NO);
  //		if ([paths count] >1)
  //			usleep(500000);
  //		
  //		
  //	}
  return YES;
}

- (BOOL)initiateVideoWithAccount:(NSString *)accountID {
  MessagesApplication *MessagesApp = [SBApplication applicationWithBundleIdentifier:@"com.apple.iChat"];
  MessagesBuddy *buddy = [MessagesApp.buddies objectWithName:accountID];
  [MessagesApp send:@"" to:buddy];
  return YES;
  
  
  //	NSAppleScript *imScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]]pathForResource:@"iChat" ofType:@"scpt"]] error:nil];
  //	NSDictionary *errorDict = nil;
  //	[imScript executeSubroutine:@"video_chat_with_account" arguments:[NSArray arrayWithObjects:accountID, nil] error:&errorDict];
  //	if (errorDict) NSLog(@"Execute Error: %@", errorDict);
  //	return !errorDict;
	
}

- (BOOL)initiateAudioWithAccount:(NSString *)accountID {
  MessagesApplication *MessagesApp = [SBApplication applicationWithBundleIdentifier:@"com.apple.iChat"];
  MessagesBuddy *buddy = [MessagesApp.buddies objectWithName:accountID];
  [MessagesApp send:@"" to:buddy];
  return YES;
  
  
  //	NSAppleScript *imScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]]pathForResource:@"iChat" ofType:@"scpt"]] error:nil];
  //	NSDictionary *errorDict = nil;
  //	[imScript executeSubroutine:@"audio_chat_with_account" arguments:[NSArray arrayWithObjects:accountID, nil] error:&errorDict];
  //	if (errorDict) NSLog(@"Execute Error: %@", errorDict);
  //	return !errorDict;
	
}

- (BOOL)setIChatStatus:(QSObject *)dObject {
  MessagesApplication *MessagesApp = [SBApplication applicationWithBundleIdentifier:@"com.apple.iChat"];
  MessagesApp.statusMessage = [dObject stringValue];
  return YES;
  //	NSString *status = [dObject stringValue];
  //	NSAppleScript *imScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]]pathForResource:@"iChat" ofType:@"scpt"]] error:nil];
  //	NSDictionary *errorDict = nil;
  //	[imScript executeSubroutine:@"set_status" arguments:[NSArray arrayWithObjects:status, nil] error:&errorDict];
  //	if (errorDict) NSLog(@"Execute Error: %@", errorDict);
  //	return !errorDict; 	
}


- (BOOL)loadChildrenForObject:(QSObject *)object {
	if ([[object primaryType] isEqualToString:NSFilenamesPboardType]) {
		[object setChildren:[presenceController onlineBuddies]];
		return YES; 	
	}
	return NO;
}

- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped {
  
  MessagesApplication *iChat = [SBApplication applicationWithBundleIdentifier:@"com.apple.iChat"];
  //iChat.
	return NO;
	if (![object objectForType:QSProcessType]) return NO;
	
	int count = 3;
	NSImage *icon = [object icon];
	[icon setFlipped:flipped];
	NSImageRep *bestBadgeRep = [icon bestRepresentationForSize:rect.size];  
	[icon setSize:[bestBadgeRep size]];
	[icon drawInRect:rect fromRect:NSMakeRect(0, 0, [bestBadgeRep size] .width, [bestBadgeRep size] .height) operation:NSCompositeSourceOver fraction:1.0];
	
	QSCountBadgeImage *countImage = [QSCountBadgeImage badgeForCount:count];
	
	[countImage drawBadgeForIconRect:rect]; 				
	
	return YES; 	
}

@end
