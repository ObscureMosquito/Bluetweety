#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ===============================================
// Part 1: Shared Hook Logic (Helper Functions)
// ===============================================

// Helper to replace "api.twitter.com" in a URL string
static NSString * ReplaceTwitterDomain(NSString *original) {
    return [original stringByReplacingOccurrencesOfString:@"api.twitter.com"
                                               withString:@"twitterbridge.loganserver.net"];
}

// Hooks for SLTwitterRequest
// ALL OF THESE HOOK INTO THE TWITTER PREFERENCE BUNDLE, AND ARE NEEDED TO MANAGE ACCOUNTS
id hook_SL_initWithURL(id self, SEL _cmd, NSURL *url, NSDictionary *params, int method) {
    NSString *originalURL = [url absoluteString];
    if ([originalURL rangeOfString:@"api.twitter.com"].location != NSNotFound) {
        NSString *newURLString = ReplaceTwitterDomain(originalURL);
        NSURL *newURL = [NSURL URLWithString:newURLString];
        NSLog(@"[BlueTweety] (SLTwitterRequest) Redirect initWithURL: %@ -> %@", originalURL, newURLString);
        return orig_SL_initWithURL(self, _cmd, newURL, params, method);
    }
    return orig_SL_initWithURL(self, _cmd, url, params, method);
}

void hook_SL_performJSONRequestWithHandler(id self, SEL _cmd, void (^handler)(NSData*,NSHTTPURLResponse*,NSError*)) {
    NSLog(@"[BlueTweety] (SLTwitterRequest) performJSONRequestWithHandler. URL: %@", [[self URL] absoluteString]);
    orig_SL_performJSONRequestWithHandler(self, _cmd, handler);
}

NSURL* hook_SL_URL(id self, SEL _cmd) {
    NSURL *originalURL = orig_SL_URL(self, _cmd);
    NSString *originalURLString = [originalURL absoluteString];
    if ([originalURLString rangeOfString:@"api.twitter.com"].location != NSNotFound) {
        NSString *newURLString = ReplaceTwitterDomain(originalURLString);
        NSURL *newURL = [NSURL URLWithString:newURLString];
        NSLog(@"[BlueTweety] (SLTwitterRequest) Redirect URL getter: %@ -> %@", originalURLString, newURLString);
        return newURL;
    }
    return originalURL;
}

NSURLRequest* hook_SL_signedURLRequest(id self, SEL _cmd) {
    NSURLRequest *origRequest = orig_SL_signedURLRequest(self, _cmd);
    NSURL *originalURL = [origRequest URL];
    NSString *originalURLString = [originalURL absoluteString];
    if ([originalURLString rangeOfString:@"api.twitter.com"].location != NSNotFound) {
        NSString *newURLString = ReplaceTwitterDomain(originalURLString);
        NSMutableURLRequest *modified = [origRequest mutableCopy];
        [modified setURL:[NSURL URLWithString:newURLString]];
        NSLog(@"[BlueTweety] (SLTwitterRequest) Redirect signedURLRequest: %@ -> %@", originalURLString, newURLString);
        return modified;
    }
    return origRequest;
}

// ===============================================
// Part 3: Hook TWRequest (Legacy Twitter.framework)
// ===============================================

// THIS IS FOR POSTING ACROSS THE SYSTEM, INCLUDING NOTIFICATION CENTER WIDGET AND SHARE SHEET
%hook TWRequest

- (id)initWithURL:(NSURL *)url parameters:(NSDictionary *)parameters requestMethod:(int)method {
    NSString *originalURL = [url absoluteString];
    if ([originalURL rangeOfString:@"twitter.com"].location != NSNotFound) {
        // Remove "twitter.com" from the URL
        NSRange domainRange = [originalURL rangeOfString:@"twitter.com"];
        NSString *urlPathAndQuery = [originalURL substringFromIndex:(domainRange.location + domainRange.length)];
        NSString *newURLString = [@"https://twitterbridge.loganserver.net" stringByAppendingString:urlPathAndQuery];

        NSLog(@"[BlueTweety] (TWRequest) Redirect initWithURL: %@ -> %@", originalURL, newURLString);
        NSURL *newURL = [NSURL URLWithString:newURLString];
        return %orig(newURL, parameters, method);
    }
    return %orig(url, parameters, method);
}

- (NSURL *)URL {
    NSURL *originalURL = %orig;
    NSString *originalURLString = [originalURL absoluteString];
    if ([originalURLString rangeOfString:@"twitter.com"].location != NSNotFound) {
        NSRange domainRange = [originalURLString rangeOfString:@"twitter.com"];
        NSString *urlPathAndQuery = [originalURLString substringFromIndex:(domainRange.location + domainRange.length)];
        NSString *newURLString = [@"https://twitterbridge.loganserver.net" stringByAppendingString:urlPathAndQuery];

        NSLog(@"[BlueTweety] (TWRequest) Redirect URL: %@ -> %@", originalURLString, newURLString);
        return [NSURL URLWithString:newURLString];
    }
    return originalURL;
}

%end

// ===============================================
// Part 4: Dynamically Hook SLTwitterRequest
// ===============================================

//THIS IS CALLED WHEN THE TWITTER PREFERENCE BUNDLE IS LOADED TO INITIALIZE NETWORK HOOKS
static void hook_SLTwitterRequestClasses() {
    Class SLTwitterRequest = objc_getClass("SLTwitterRequest");
    if (SLTwitterRequest) {
        NSLog(@"[BlueTweety] Found SLTwitterRequest, hooking...");

        MSHookMessageEx(SLTwitterRequest,
            @selector(initWithURL:parameters:requestMethod:),
            (IMP)hook_SL_initWithURL,
            (IMP *)&orig_SL_initWithURL);

        MSHookMessageEx(SLTwitterRequest,
            @selector(performJSONRequestWithHandler:),
            (IMP)hook_SL_performJSONRequestWithHandler,
            (IMP *)&orig_SL_performJSONRequestWithHandler);

        MSHookMessageEx(SLTwitterRequest,
            @selector(URL),
            (IMP)hook_SL_URL,
            (IMP *)&orig_SL_URL);

        MSHookMessageEx(SLTwitterRequest,
            @selector(signedURLRequest),
            (IMP)hook_SL_signedURLRequest,
            (IMP *)&orig_SL_signedURLRequest);
    } else {
        NSLog(@"[BlueTweety] SLTwitterRequest not found in this process");
    }
}

// ===============================================
// Part 5: Main Constructor (Process Injection)
// ===============================================

%ctor {
    NSLog(@"[BlueTweety] Injected into %@", [[NSBundle mainBundle] bundleIdentifier]);

    // Dynamically hook SLTwitterRequest in "TwitterSettings.bundle" (Preferences or sociald)
    [[NSNotificationCenter defaultCenter] addObserverForName:NSBundleDidLoadNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
        NSBundle *bundle = note.object;
        if ([bundle.bundlePath rangeOfString:@"TwitterSettings.bundle"].location != NSNotFound) {
            NSLog(@"[BlueTweety] TwitterSettings bundle loaded: %@", bundle.bundlePath);
            hook_SLTwitterRequestClasses();
        }
    }];

    // Optionally hook SLTwitterRequest immediately if it's already loaded
    hook_SLTwitterRequestClasses();
}
