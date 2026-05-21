#import <Foundation/Foundation.h>

%hook TwitterAPI

static NSString *BlueTweetyCustomServerURL() {
    NSString *prefsPath = @"/var/mobile/Library/Preferences/bag.skyglow.bluetweetypreferences.plist";
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
    
    NSString *customURL = [prefs objectForKey:@"URLEndpoint"];
    if (!customURL || [customURL isEqualToString:@""]) {
        return @"example.com"; // Default value if not set
    }
    
    return customURL;
}

- (NSString *)uploadApiRoot {
    NSString *customURL = BlueTweetyCustomServerURL();
    return [NSString stringWithFormat:@"https://%@/1", customURL];
}

%end