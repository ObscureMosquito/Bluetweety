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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self _updateTableHeaderView];
}

- (void)_updateTableHeaderView {
    UITableView *tableView = (UITableView *)self.table;
    CGFloat w = tableView.bounds.size.width;
    if (w < 10.0f) w = 320.0f;

    CGFloat imageWidth  = 90.0f;
    CGFloat imageHeight = 90.0f;
    CGFloat topPad      = 22.0f;

    CGFloat startX = (w - imageWidth) / 2.0f;

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(startX, topPad, imageWidth, imageHeight)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.clipsToBounds = YES;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

    NSString *absolutePath = @"/Library/Application Support/bag.skyglow.bluetweety/BlueTweety-Icon.png";
    UIImage *image = [UIImage imageWithContentsOfFile:absolutePath];

    if (image) {
        imageView.image = image;
    } else {
        NSLog(@"[BlueTweety] Failed to load image at path: %@", absolutePath);
    }

    CGFloat iconGap   = 10.0f;
    CGFloat titleGap  = 4.0f;
    CGFloat bodyGap   = 12.0f;
    CGFloat botPad    = 18.0f;
    CGFloat sideInset = 24.0f;

    UILabel *titleLabel          = [[UILabel alloc] init];
    titleLabel.text              = @"BlueTweety";
    titleLabel.font              = [UIFont boldSystemFontOfSize:17.0f];
    titleLabel.textColor         = [UIColor colorWithRed:0.18f green:0.18f blue:0.18f alpha:1.0f];
    titleLabel.shadowColor       = [UIColor colorWithWhite:1.0f alpha:0.7f];
    titleLabel.shadowOffset      = CGSizeMake(0, 1);
    titleLabel.textAlignment     = NSTextAlignmentCenter;
    titleLabel.backgroundColor   = [UIColor clearColor];
    titleLabel.autoresizingMask  = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    CGFloat titleY = topPad + imageHeight + iconGap;
    [titleLabel sizeToFit];
    titleLabel.frame = CGRectMake((w - titleLabel.frame.size.width) / 2.0f, titleY, titleLabel.frame.size.width, titleLabel.frame.size.height);

    UILabel *bodyLabel          = [[UILabel alloc] init];
    bodyLabel.text              = @"Enter the server's address below, then log in\nvia the native settings section to get started.";
    bodyLabel.font              = [UIFont systemFontOfSize:13.0f];
    bodyLabel.textColor         = [UIColor colorWithRed:0.38f green:0.38f blue:0.42f alpha:1.0f];
    bodyLabel.shadowColor       = [UIColor colorWithWhite:1.0f alpha:0.6f];
    bodyLabel.shadowOffset      = CGSizeMake(0, 1);
    bodyLabel.textAlignment     = NSTextAlignmentCenter;
    bodyLabel.backgroundColor   = [UIColor clearColor];
    bodyLabel.numberOfLines     = 0;
    bodyLabel.autoresizingMask  = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    CGFloat bodyY = titleY + titleLabel.frame.size.height + titleGap;
    CGSize bodyFit = [bodyLabel sizeThatFits:CGSizeMake(w - sideInset * 2.0f, 999.0f)];
    bodyLabel.frame = CGRectMake((w - bodyFit.width) / 2.0f, bodyY, bodyFit.width, bodyFit.height);

    CGFloat totalH = bodyY + bodyFit.height + bodyGap + botPad;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, totalH)];
    header.backgroundColor = [UIColor clearColor];
    header.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [header addSubview:imageView];
    [header addSubview:titleLabel];
    [header addSubview:bodyLabel];

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

- (void)respringAndRestart {
    [self restartServices];

    pid_t pid;
    const char *args[] = { "killall", "-9", "SpringBoard", NULL };
    posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char *const *)args, NULL);
    waitpid(pid, NULL, 0);
}

@end