#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

// ===============================================
// Shared Helper: Replace Twitter Domains
// ===============================================

// Fetch the custom URL from NSUserDefaults
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

    // Remove "api." or "upload." subdomains from URLs
    NSString *cleanURL = [original stringByReplacingOccurrencesOfString:@"api.twitter.com" withString:@"twitter.com"];
    cleanURL = [cleanURL stringByReplacingOccurrencesOfString:@"upload.twitter.com" withString:@"twitter.com"];

    // Replace "twitter.com" with the custom domain
    return [cleanURL stringByReplacingOccurrencesOfString:@"twitter.com" withString:customDomain];
}

// ===============================================
// iOS 5 Hooks: TWDAuthenticator, for Settings Bundle
// ===============================================

static NSURL *(*orig_accessTokenURL)(id self, SEL _cmd) = NULL;
static NSURL * hook_accessTokenURL(id self, SEL _cmd) {
    NSURL *origURL = orig_accessTokenURL(self, _cmd);
    NSString *origStr = [origURL absoluteString];
    NSString *newStr = ReplaceTwitterDomain(origStr);
    if (![newStr isEqualToString:origStr]) {
        return [NSURL URLWithString:newStr];
    }
    return origURL;
}

static NSURL *(*orig_verifyCredentialsURL)(id self, SEL _cmd) = NULL;
static NSURL * hook_verifyCredentialsURL(id self, SEL _cmd) {
    NSURL *origURL = orig_verifyCredentialsURL(self, _cmd);
    NSString *origStr = [origURL absoluteString];
    NSString *newStr = ReplaceTwitterDomain(origStr);
    if (![newStr isEqualToString:origStr]) {
        return [NSURL URLWithString:newStr];
    }
    return origURL;
}

static void hook_iOS5_TWDAuthenticator() {
    Class twdAuthenticator = objc_getClass("TWDAuthenticator");
    if (twdAuthenticator) {
        MSHookMessageEx(twdAuthenticator,
                        @selector(accessTokenURL),
                        (IMP)hook_accessTokenURL,
                        (IMP *)&orig_accessTokenURL);

        MSHookMessageEx(twdAuthenticator,
                        @selector(verifyCredentialsURL),
                        (IMP)hook_verifyCredentialsURL,
                        (IMP *)&orig_verifyCredentialsURL);
    }
}

// ===============================================
// iOS 6+ Hooks: SLTwitterRequest For Posting from system
// ===============================================

static id (*orig_SL_initWithURL)(id self, SEL _cmd, NSURL *url, NSDictionary *params, int method) = NULL;
static NSURL* (*orig_SL_URL)(id self, SEL _cmd) = NULL;

id hook_SL_initWithURL(id self, SEL _cmd, NSURL *url, NSDictionary *params, int method) {
    NSString *originalURL = [url absoluteString];
    if ([originalURL rangeOfString:@"twitter.com"].location != NSNotFound) {
        NSString *newURLString = ReplaceTwitterDomain(originalURL);
        NSURL *newURL = [NSURL URLWithString:newURLString];
        return orig_SL_initWithURL(self, _cmd, newURL, params, method);
    }
    return orig_SL_initWithURL(self, _cmd, url, params, method);
}

NSURL* hook_SL_URL(id self, SEL _cmd) {
    NSURL *originalURL = orig_SL_URL(self, _cmd);
    NSString *originalURLString = [originalURL absoluteString];
    if ([originalURLString rangeOfString:@"twitter.com"].location != NSNotFound) {
        NSString *newURLString = ReplaceTwitterDomain(originalURLString);
        return [NSURL URLWithString:newURLString];
    }   
    return originalURL;
}

static void hook_SLTwitterRequestClasses() {
    Class SLTwitterRequest = objc_getClass("SLTwitterRequest");
    if (SLTwitterRequest) {
        MSHookMessageEx(SLTwitterRequest,
            @selector(initWithURL:parameters:requestMethod:),
            (IMP)hook_SL_initWithURL,
            (IMP *)&orig_SL_initWithURL);

        MSHookMessageEx(SLTwitterRequest,
            @selector(URL),
            (IMP)hook_SL_URL,
            (IMP *)&orig_SL_URL);
    }
}

// ===============================================
// Universal Hook: TWRequest (iOS 5 and 6)
// ===============================================

%hook TWRequest

- (id)initWithURL:(NSURL *)url parameters:(NSDictionary *)parameters requestMethod:(int)method {
    NSString *originalURL = [url absoluteString];
    if ([originalURL rangeOfString:@"twitter.com"].location != NSNotFound) {
        NSString *newURLString = ReplaceTwitterDomain(originalURL);
        NSURL *newURL = [NSURL URLWithString:newURLString];
        return %orig(newURL, parameters, method);
    }
    return %orig(url, parameters, method);
}

- (NSURL *)URL {
    NSURL *originalURL = %orig;
    NSString *originalURLString = [originalURL absoluteString];
    if ([originalURLString rangeOfString:@"twitter.com"].location != NSNotFound) {
        NSString *newURLString = ReplaceTwitterDomain(originalURLString);
        return [NSURL URLWithString:newURLString];
    }
    return originalURL;
}

%end

// ===============================================
// Main Constructor: Check iOS Version
// ===============================================

%ctor {
    double systemVer = [[[UIDevice currentDevice] systemVersion] doubleValue];

    if (systemVer < 6.0) {
        // iOS 5 specific hooks for Settings authentication
        if (objc_getClass("TWDAuthenticator")) {
            hook_iOS5_TWDAuthenticator();
        } else {
            [[NSNotificationCenter defaultCenter] addObserverForName:NSBundleDidLoadNotification
                                                              object:nil
                                                               queue:nil
                                                          usingBlock:^(NSNotification *note) {
                NSBundle *bundle = note.object;
                if ([bundle.bundlePath rangeOfString:@"TwitterSettings.bundle"].location != NSNotFound) {
                    hook_iOS5_TWDAuthenticator();
                }
            }];
        }
    } else {
        // iOS 6+ specific hooks for Social framework requests
        hook_SLTwitterRequestClasses();
    }
}
