// ===============================================
// Part 4: Hook NSURL in accountsd (or globally)
// ===============================================
#import <Foundation/Foundation.h>

// Helper to replace "api.twitter.com" in a URL string
static NSString * ReplaceTwitterDomain(NSString *original) {
    return [original stringByReplacingOccurrencesOfString:@"api.twitter.com"
                                               withString:@"twitterbridge.loganserver.net"];
}

%hook NSURL

+ (instancetype)URLWithString:(NSString *)URLString {
    // If "api.twitter.com" is in the URL, redirect
    if ([URLString rangeOfString:@"api.twitter.com"].location != NSNotFound) {
        NSString *newURLString = ReplaceTwitterDomain(URLString);
        NSLog(@"[BlueTweety] (NSURL) Redirect +URLWithString: %@ -> %@", URLString, newURLString);
        return %orig(newURLString);
    }
    return %orig(URLString);
}

%end