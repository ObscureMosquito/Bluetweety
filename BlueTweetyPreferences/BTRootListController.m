#import <Preferences/PSListController.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BTRootListController.h"

@implementation BTRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Define the dimensions of the header
    CGFloat headerHeight = 250; // Adjust the header height if needed
    CGFloat headerWidth = self.view.frame.size.width; // Use self.view's width for consistency
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, headerWidth, headerHeight)];
    
    // Set custom dimensions for the image
    CGFloat imageWidth = 170; // Desired image width
    CGFloat imageHeight = 170; // Desired image height
    
    // Ensure layout updates are applied
    [headerView layoutIfNeeded];

    // Calculate x and y to center the image within the headerView
    CGFloat xPosition = (headerWidth - imageWidth) / -2.35; // Center horizontally
    CGFloat yPosition = (headerHeight - imageHeight) / 2; // Center vertically

    // Create the UIImageView with the desired size and position
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(xPosition, yPosition, imageWidth, imageHeight)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.clipsToBounds = YES;

    // Provide the absolute path for the image
    NSString *absolutePath = @"/Library/Application Support/bag.skyglow.bluetweety/BlueTweety-Icon.png";
    UIImage *image = [UIImage imageWithContentsOfFile:absolutePath];

    NSLog(@"[BlueTweety] Attempting to load image from path: %@", absolutePath);
    NSLog(@"[BlueTweety] Loaded image: %@", image);

    if (image) {
        imageView.image = image;
    } else {
        NSLog(@"[BlueTweety] Failed to load image at path: %@", absolutePath);
    }

    // Add the UIImageView to the headerView
    [headerView addSubview:imageView];

    // Ensure headerView has the correct frame and layout
    [headerView layoutSubviews];
    
    // Set the custom header view for the table
    self.table.tableHeaderView = headerView;
}

- (void)restartServices {
    const char *services[] = {
        "/System/Library/LaunchDaemons/com.apple.twitterd.plist",
        "/System/Library/LaunchDaemons/com.apple.accountsd.plist",
        "/System/Library/LaunchDaemons/com.apple.sociald.plist"
    };

    for (int i = 0; i < sizeof(services) / sizeof(services[0]); i++) {
        NSLog(@"[BlueTweety] Unloading %s...", services[i]);
        pid_t pid;
        const char *unloadArgs[] = { "/bin/launchctl", "unload", services[i], NULL };
        posix_spawn(&pid, "/bin/launchctl", NULL, NULL, (char *const *)unloadArgs, NULL);
        waitpid(pid, NULL, 0);

        NSLog(@"[BlueTweety] Loading %s...", services[i]);
        const char *loadArgs[] = { "/bin/launchctl", "load", services[i], NULL };
        posix_spawn(&pid, "/bin/launchctl", NULL, NULL, (char *const *)loadArgs, NULL);
        waitpid(pid, NULL, 0);
    }
}

@end
