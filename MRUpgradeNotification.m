//
//  MRUpgradeNotification.m
//  MRUpgradeNotification
//
//  Created by Mark Rickert on 9/10/11.
//  Copyright Mark Rickert 2011 All rights reserved.
//
/*
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "MRUpgradeNotification.h"
#import "SBJson.h"

#define kMRUpgradeLastChecked @"kMRUpgradeLastChecked"
#define kMRUpgradeShownForVersion @"kMRUpgradeShownForVersion"
#define kMRUpgradeAppStoreLookupURL @"http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsLookup?id=%u"
#define kMRUpgradeCheckInterval 86400 //Once a day
#define kMRUpgradeAlertTitle @"Application Update Available!"

@interface MRUpgradeNotification (PrivateMethods)
	+(double)dateDiff:(NSDate *)origDate;
	+(NSComparisonResult)compareVersion:(NSString *)leftVersion with:(NSString *)rightVersion;
@end


@implementation MRUpgradeNotification

+ (void) checkUpgradeForAppID:(int) applicationID
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	//Get the last update check
	NSDate *lastChecked = [defaults objectForKey:kMRUpgradeLastChecked];
	NSLog(@"MRUpgradeNotification Last Checked: %@", lastChecked);
	if(!lastChecked || [MRUpgradeNotification dateDiff:lastChecked] > kMRUpgradeCheckInterval) 
	{
		NSString *appStoreLookupURLString = [NSString stringWithFormat:kMRUpgradeAppStoreLookupURL, applicationID];
		NSURL *AppStoreLookupURL = [NSURL URLWithString:appStoreLookupURLString];

		//Pull that application's descriptior from Apple.
		SBJsonParser *parser = [[SBJsonParser alloc] init];
		NSDictionary *appStoreDict = [parser objectWithData:[NSData dataWithContentsOfURL:AppStoreLookupURL]];
		[parser release];

		if(appStoreDict != nil)
		{
			NSLog(@"appStoreDict != nil\n%@", [appStoreDict valueForKeyPath:@"results"]);
			NSString *currentApplicationVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
			
			NSDictionary *appStoreQueryResults = [[appStoreDict valueForKey:@"results"] objectAtIndex:0];
			NSString *storeApplicationVersion = [appStoreQueryResults valueForKey:@"version"];
			
			if(storeApplicationVersion != nil && ![defaults objectForKey:[NSString stringWithFormat:@"%@%@", kMRUpgradeShownForVersion, storeApplicationVersion]])
			{
				NSLog(@"haven't checked for this version");
				NSComparisonResult versionDifferences = [MRUpgradeNotification compareVersion:currentApplicationVersion with:storeApplicationVersion];
				if(versionDifferences == NSOrderedAscending)
				{
					//Show the alert.
					NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
					UIAlertView *upgradeAlert = [[[UIAlertView alloc] initWithTitle:kMRUpgradeAlertTitle
																															message:[NSString stringWithFormat:@"There is an update to %@. Version %@ is now available (you have %@).\n\nVisit the App Store to download and install the new version!", appName, storeApplicationVersion, currentApplicationVersion]
																														 delegate:nil 
																										cancelButtonTitle:@"OK" 
																										otherButtonTitles:nil] autorelease];
					[upgradeAlert show];
					
					[defaults setBool:YES forKey:[NSString stringWithFormat:@"%@%@", kMRUpgradeShownForVersion, storeApplicationVersion]];
				}
			}
		}
		
		NSLog(@"Setting last checked date.");
		[defaults setObject:[NSDate date] forKey:kMRUpgradeLastChecked];
		[defaults synchronize];
	}
}

+(double)dateDiff:(NSDate *)origDate
{
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