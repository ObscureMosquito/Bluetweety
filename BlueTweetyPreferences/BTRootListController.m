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
    [self _updateTableHeaderView];
}

- (void)_updateTableHeaderView {
    // Get the table width dynamically, fallback to 320 for legacy iPhones if bounds aren't set yet
    UITableView *tableView = (UITableView *)self.table;
    CGFloat w = tableView.bounds.size.width;
    if (w < 10.0f) w = 320.0f;

    // Dimensions for your BlueTweety icon
    CGFloat imageWidth  = 170.0f;
    CGFloat imageHeight = 170.0f;
    CGFloat topPad      = 22.0f;
    
    // Proper math to perfectly center the image horizontally
    CGFloat startX = (w - imageWidth) / 2.0f;

    // 1. Setup the Icon
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(startX, topPad, imageWidth, imageHeight)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.clipsToBounds = YES;

    NSString *absolutePath = @"/Library/Application Support/bag.skyglow.bluetweety/BlueTweety-Icon.png";
    UIImage *image = [UIImage imageWithContentsOfFile:absolutePath];

    if (image) {
        imageView.image = image;
    } else {
        NSLog(@"[BlueTweety] Failed to load image at path: %@", absolutePath);
    }

    // 2. Setup the Text Formatting (keeping the Skyglow placeholder text)
    CGFloat iconGap   = 10.0f;
    CGFloat titleGap  = 4.0f;
    CGFloat bodyGap   = 12.0f;
    CGFloat botPad    = 18.0f;
    CGFloat sideInset = 24.0f;

    UILabel *titleLabel          = [[UILabel alloc] init];
    titleLabel.text              = @"Skyglow Notifications";
    titleLabel.font              = [UIFont boldSystemFontOfSize:17.0f];
    titleLabel.textColor         = [UIColor colorWithRed:0.18f green:0.18f blue:0.18f alpha:1.0f];
    titleLabel.shadowColor       = [UIColor colorWithWhite:1.0f alpha:0.7f];
    titleLabel.shadowOffset      = CGSizeMake(0, 1);
    titleLabel.textAlignment     = NSTextAlignmentCenter;
    titleLabel.backgroundColor   = [UIColor clearColor];
    
    CGFloat titleY = topPad + imageHeight + iconGap;
    titleLabel.frame = CGRectMake(sideInset, titleY, w - sideInset * 2.0f, 22.0f);

    UILabel *bodyLabel          = [[UILabel alloc] init];
    bodyLabel.text              = @"Enter your server address below, then select\nyour server\xe2\x80\x99s public certificate to get started.";
    bodyLabel.font              = [UIFont systemFontOfSize:13.0f];
    bodyLabel.textColor         = [UIColor colorWithRed:0.38f green:0.38f blue:0.42f alpha:1.0f];
    bodyLabel.shadowColor       = [UIColor colorWithWhite:1.0f alpha:0.6f];
    bodyLabel.shadowOffset      = CGSizeMake(0, 1);
    bodyLabel.textAlignment     = NSTextAlignmentCenter;
    bodyLabel.backgroundColor   = [UIColor clearColor];
    bodyLabel.numberOfLines     = 0;
    
    // Calculate the height needed for the body text
    CGFloat bodyY = titleY + 22.0f + titleGap;
    CGSize bodyFit = [bodyLabel sizeThatFits:CGSizeMake(w - sideInset * 2.0f, 999.0f)];
    bodyLabel.frame = CGRectMake(sideInset, bodyY, w - sideInset * 2.0f, bodyFit.height);

    // 3. Container Assembly
    CGFloat totalH = bodyY + bodyFit.height + bodyGap + botPad;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, totalH)];
    header.backgroundColor = [UIColor clearColor];
    
    [header addSubview:imageView];
    [header addSubview:titleLabel];
    [header addSubview:bodyLabel];

    // Assign back to PSListController's table
    tableView.tableHeaderView = header;
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