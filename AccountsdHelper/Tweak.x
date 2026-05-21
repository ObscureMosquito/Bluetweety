#import <Foundation/Foundation.h>

static NSString *BlueTweetyCustomServerURL() {
    NSString *prefsPath = @"/var/mobile/Library/Preferences/bag.skyglow.bluetweetypreferences.plist";
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
    
    NSString *customURL = [prefs objectForKey:@"URLEndpoint"];
    if (!customURL || [customURL isEqualToString:@""]) {
        return @"example.com";
    }
    
    return customURL;
}

static NSString *ReplaceTwitterDomain(NSString *original) {
    NSString *customDomain = BlueTweetyCustomServerURL();

    NSString *cleanURL = [original stringByReplacingOccurrencesOfString:@"api.twitter.com" withString:@"twitter.com"];
    cleanURL = [cleanURL stringByReplacingOccurrencesOfString:@"upload.twitter.com" withString:@"twitter.com"];

    return [cleanURL stringByReplacingOccurrencesOfString:@"twitter.com" withString:customDomain];
}

%group AccountsdHook

%hook NSURLRequest

- (instancetype)initWithURL:(NSURL *)URL {
    NSString *URLString = [URL absoluteString];
    if ([URLString rangeOfString:@"api.twitter.com"].location != NSNotFound) {
        NSString *newURLString = ReplaceTwitterDomain(URLString);
        return %orig([NSURL URLWithString:newURLString]);
    }
    return %orig(URL);
}

- (instancetype)initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval {
    NSString *URLString = [URL absoluteString];
    if ([URLString rangeOfString:@"api.twitter.com"].location != NSNotFound) {
        NSString *newURLString = ReplaceTwitterDomain(URLString);
        return %orig([NSURL URLWithString:newURLString], cachePolicy, timeoutInterval);
    }
    return %orig(URL, cachePolicy, timeoutInterval);
}

%end

%hook NSMutableURLRequest

- (void)setURL:(NSURL *)URL {
    NSString *URLString = [URL absoluteString];
    if ([URLString rangeOfString:@"api.twitter.com"].location != NSNotFound) {
        NSString *newURLString = ReplaceTwitterDomain(URLString);
        %orig([NSURL URLWithString:newURLString]);
    } else {
        %orig(URL);
    }
}

%end

%end

%ctor {
    if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"accountsd"]) {
        %init(AccountsdHook);
    }
}