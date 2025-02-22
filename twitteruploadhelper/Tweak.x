#import <Foundation/Foundation.h>

%hook TwitterAPI

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

- (NSString *)uploadApiRoot {
    NSString *customURL = BlueTweetyCustomServerURL();
    return [NSString stringWithFormat:@"https://%@/1", customURL];
}

%end