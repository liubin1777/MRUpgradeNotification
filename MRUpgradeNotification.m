//
//  MRUpgradeNotification.m
//  MRUpgradeNotification
//
//  Created by Mark Rickert on 9/10/11.
//  Copyright Mark Rickert 2011 All rights reserved.
//

#import "MRUpgradeNotification.h"
#import "SBJson.h"

@interface MRUpgradeNotification (PrivateMethods)
	+(double)dateDiff:(NSDate *)origDate;
	+(NSComparisonResult)compareVersion:(NSString *)leftVersion with:(NSString *)rightVersion;
@end


@implementation MRUpgradeNotification

+ (void) checkUpgradeForAppID:(int) applicationID {

	//Get the last update check
	NSDate *lastChecked = [[NSUserDefaults standardUserDefaults] objectForKey:@"MRUpgradeNagLastChecked"];
	NSLog(@"Last Checked: %@", lastChecked);
	if(!lastChecked || [self dateDiff:lastChecked] > 86400) { //Only check once a day
		
		NSString *appStoreLookupURLString = [NSString stringWithFormat:@"http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsLookup?id=%u", applicationID];
		NSURL *AppStoreLookupURL = [NSURL URLWithString:appStoreLookupURLString];

		//Pull that application's descriptior from Apple.
		SBJsonParser *parser = [[SBJsonParser alloc] init];
		NSDictionary *appStoreDict = [parser objectWithData:[NSData dataWithContentsOfURL:AppStoreLookupURL]];
		[parser release];

		if(!appStoreDict)return; //Didn't get anything from the app store.

		NSString *currentApplicationVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
		NSString *storeApplicationVersion = [appStoreDict objectForKey:@"version"];

		if(!storeApplicationVersion)return; //Couldn't find the application version from the json dictioary
		
		NSComparisonResult versionDifferences = [MRUpgradeNotification compareVersion:currentApplicationVersion with:storeApplicationVersion];
		if(versionDifferences == NSOrderedAscending && ![[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"MRUpgradeNagShownForVersion%@", storeApplicationVersion]]) {
			//Show the alert.
			NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
			UIAlertView *nagAlert = [[[UIAlertView alloc] initWithTitle:@"Application Update Available!" 
																													message:[NSString stringWithFormat:@"There is an update to %@. Version %@ is now available (you have %@).\n\nVisit the App Store to download and install the new version!", appName, storeApplicationVersion, currentApplicationVersion]
																												delegate:nil 
																							 cancelButtonTitle:@"OK" 
																								otherButtonTitles:nil] autorelease];
			[nagAlert show];
			
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:[NSString stringWithFormat:@"MRUpgradeNagShownForVersion%@", storeApplicationVersion]];
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"MRUpgradeNagLastChecked"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

+(double)dateDiff:(NSDate *)origDate {
  double ti = [origDate timeIntervalSinceNow];
  ti = ti * -1;
  
	return ti;
}

/*
 * compareVersions(@"10.4",             @"10.3")             returns NSOrderedDescending (1)
 * compareVersions(@"10.5",             @"10.5.0")           returns NSOrderedSame (0)
 * compareVersions(@"10.4 Build 8L127", @"10.4 Build 8P135") returns NSOrderedAscending (-1)
 * 
 * Original Code by 0xced: http://snipplr.com/view.php?codeview&id=2771
 */
+(NSComparisonResult)compareVersion:(NSString *)leftVersion with:(NSString *)rightVersion
{
	int i;
	
	// Break version into fields (separated by '.')
	NSMutableArray *leftFields  = [[NSMutableArray alloc] initWithArray:[leftVersion  componentsSeparatedByString:@"."]];
	NSMutableArray *rightFields = [[NSMutableArray alloc] initWithArray:[rightVersion componentsSeparatedByString:@"."]];
	
	// Implict ".0" in case version doesn't have the same number of '.'
	if ([leftFields count] < [rightFields count]) {
		while ([leftFields count] != [rightFields count]) {
			[leftFields addObject:@"0"];
		}
	} else if ([leftFields count] > [rightFields count]) {
		while ([leftFields count] != [rightFields count]) {
			[rightFields addObject:@"0"];
		}
	}
	
	// Do a numeric comparison on each field
	for(i = 0; i < [leftFields count]; i++) {
		NSComparisonResult result = [[leftFields objectAtIndex:i] compare:[rightFields objectAtIndex:i] options:NSNumericSearch];
		if (result != NSOrderedSame) {
			[leftFields release];
			[rightFields release];
			return result;
		}
	}
	
	[leftFields release];
	[rightFields release];	
	return NSOrderedSame;
}

@end