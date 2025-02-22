#import <Foundation/Foundation.h>

// Helper to replace "api.twitter.com" in a URL string
static NSString *BlueTweetyCustomServerURL() {
    NSString *prefsPath = @"/var/mobile/Library/Preferences/bag.skyglow.bluetweetypreferences.plist";
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
    
    if (prefs) {
        //NSLog(@"[BlueTweety] Successfully loaded preferences plist.");
    } else {
        //NSLog(@"[BlueTweety] Failed to load preferences plist.");
    }

    NSString *customURL = [prefs objectForKey:@"URLEndpoint"];
    if (!customURL || [customURL isEqualToString:@""]) {
        //NSLog(@"[BlueTweety] Custom URL not set, using default value.");
        return @"example.com"; // Default value if not set
    }
    
    //NSLog(@"[BlueTweety] Custom URL loaded: %@", customURL);
    return customURL;
}

static NSString *ReplaceTwitterDomain(NSString *original) {
    NSString *customDomain = BlueTweetyCustomServerURL();

    // Remove "api." or "upload." subdomains from URLs
    NSString *cleanURL = [original stringByReplacingOccurrencesOfString:@"api.twitter.com" withString:@"twitter.com"];
    cleanURL = [cleanURL stringByReplacingOccurrencesOfString:@"upload.twitter.com" withString:@"twitter.com"];

    // Replace "twitter.com" with the custom domain
    return [cleanURL stringByReplacingOccurrencesOfString:@"twitter.com" withString:customDomain];
}

%group AccountsdHook

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

%end

%ctor {
    if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"accountsd"]) {
        %init(AccountsdHook);
    }
}