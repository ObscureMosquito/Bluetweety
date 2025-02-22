#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>
#import <spawn.h>

// We declare a category on UIApplication with our action method.
@interface UIApplication (BlueTweety)
- (void)blueTweetyDidChangeText:(UITextField *)sender;
@end

@implementation UIApplication (BlueTweety)

- (void)blueTweetyDidChangeText:(UITextField *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:sender.text forKey:@"BlueTweetyProxyURL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

@interface SLTwitterSettingsController : UITableViewController
@end

// Hook for viewWillDisappear
static void (*orig_viewWillDisappear)(id self, SEL _cmd, BOOL animated) = NULL;
static void hook_viewWillDisappear(id self, SEL _cmd, BOOL animated) {
    NSLog(@"[BlueTweety] viewWillDisappear called. Restarting daemons...");

    // Call the original method
    if (orig_viewWillDisappear) {
        orig_viewWillDisappear(self, _cmd, animated);
    }

    // Restart the daemons using launchctl
    const char *services[] = {
        "com.apple.twitterd",
        "com.apple.accountsd",
        "com.apple.sociald"
    };

    for (int i = 0; i < sizeof(services) / sizeof(services[0]); i++) {
        NSLog(@"[BlueTweety] Restarting %s...", services[i]);
        pid_t pid;
        const char *args[] = { "/bin/launchctl", "kickstart", "-k", services[i], NULL };
        posix_spawn(&pid, "/bin/launchctl", NULL, NULL, (char *const *)args, NULL);
        waitpid(pid, NULL, 0);
    }
    NSLog(@"[BlueTweety] Daemons restarted.");
}

// Define a unique section for the injected cell
#define CUSTOM_SECTION 2 // Add the custom cell in its own section

// Original method pointers
static NSInteger (*orig_tableView_numberOfSections)(id self, SEL _cmd, UITableView *tableView) = NULL;
static NSInteger (*orig_tableView_numberOfRowsInSection)(id self, SEL _cmd, UITableView *tableView, NSInteger section) = NULL;
static UITableViewCell *(*orig_tableView_cellForRowAtIndexPath)(id self, SEL _cmd, UITableView *tableView, NSIndexPath *indexPath) = NULL;
static UIView *(*orig_tableView_viewForHeaderInSection)(id self, SEL _cmd, UITableView *tableView, NSInteger section) = NULL;
static CGFloat (*orig_tableView_heightForHeaderInSection)(id self, SEL _cmd, UITableView *tableView, NSInteger section) = NULL;

// Hook for number of sections
static NSInteger hook_tableView_numberOfSections(id self, SEL _cmd, UITableView *tableView) {
    NSInteger baseCount = orig_tableView_numberOfSections(self, _cmd, tableView);
    return baseCount + 1; // Add one new section for the custom cell
}

// Hook for number of rows in section
static NSInteger hook_tableView_numberOfRowsInSection(id self, SEL _cmd, UITableView *tableView, NSInteger section) {
    if (section == CUSTOM_SECTION) {
        return 1; // The custom section contains only one row
    }
    return orig_tableView_numberOfRowsInSection(self, _cmd, tableView, section);
}

// Hook for cell at index path
static UITableViewCell *hook_tableView_cellForRowAtIndexPath(id self, SEL _cmd, UITableView *tableView, NSIndexPath *indexPath) {
    // Check if this is the custom row in the custom section
    if (indexPath.section == CUSTOM_SECTION) {
        static NSString *cellIdentifier = @"CustomTextFieldCell";

        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        UITextField *textField;

        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];

            // Create the text field
            textField = [[UITextField alloc] initWithFrame:CGRectMake(15, 10, tableView.frame.size.width - 30, 30)];
            textField.borderStyle = UITextBorderStyleNone;
            textField.placeholder = @"Enter proxy URL";
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.keyboardType = UIKeyboardTypeURL;

            // IMPORTANT: set the target to UIApplication, not the cell
            [textField addTarget:[UIApplication sharedApplication]
                          action:@selector(blueTweetyDidChangeText:)
                forControlEvents:UIControlEventEditingChanged];

            // Add the text field to the cell
            [cell.contentView addSubview:textField];
            textField.tag = 100; // Assign a tag to easily retrieve the text field
        } else {
            // Retrieve the text field if the cell is reused
            textField = [cell.contentView viewWithTag:100];
        }

        // Load the saved value into the text field
        textField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"BlueTweetyProxyURL"] ?: @"";

        return cell;
    }

    // Call the original implementation for other cells
    return orig_tableView_cellForRowAtIndexPath(self, _cmd, tableView, indexPath);
}

// Hook for header view in section
static UIView *hook_tableView_viewForHeaderInSection(id self, SEL _cmd, UITableView *tableView, NSInteger section) {
    if (section == CUSTOM_SECTION) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, tableView.frame.size.width - 30, 40)];
        label.text = @"BlueTweety Proxy Server";
        label.font = [UIFont boldSystemFontOfSize:16];
        label.textColor = [UIColor grayColor];
        label.backgroundColor = [UIColor clearColor];

        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 40)];
        headerView.backgroundColor = [UIColor clearColor];
        [headerView addSubview:label];

        return headerView;
    }

    return orig_tableView_viewForHeaderInSection ? orig_tableView_viewForHeaderInSection(self, _cmd, tableView, section) : nil;
}

// Hook for header height in section
static CGFloat hook_tableView_heightForHeaderInSection(id self, SEL _cmd, UITableView *tableView, NSInteger section) {
    if (section == CUSTOM_SECTION) {
        return 35.0; // Height for the custom header
    }

    return orig_tableView_heightForHeaderInSection ? orig_tableView_heightForHeaderInSection(self, _cmd, tableView, section) : 0.0;
}

// Hook the necessary methods
void hook_TwitterSettingsSpecifiers() {
        Class SLTwitterSettingsController = objc_getClass("SLTwitterSettingsController");
    if (SLTwitterSettingsController) {
        MSHookMessageEx(SLTwitterSettingsController,
                        @selector(viewWillDisappear:),
                        (IMP)hook_viewWillDisappear,
                        (IMP *)&orig_viewWillDisappear);

        MSHookMessageEx(SLTwitterSettingsController,
                        @selector(tableView:numberOfSections:),
                        (IMP)hook_tableView_numberOfSections,
                        (IMP *)&orig_tableView_numberOfSections);

        MSHookMessageEx(SLTwitterSettingsController,
                        @selector(tableView:numberOfRowsInSection:),
                        (IMP)hook_tableView_numberOfRowsInSection,
                        (IMP *)&orig_tableView_numberOfRowsInSection);

        MSHookMessageEx(SLTwitterSettingsController,
                        @selector(tableView:cellForRowAtIndexPath:),
                        (IMP)hook_tableView_cellForRowAtIndexPath,
                        (IMP *)&orig_tableView_cellForRowAtIndexPath);

        MSHookMessageEx(SLTwitterSettingsController,
                        @selector(tableView:viewForHeaderInSection:),
                        (IMP)hook_tableView_viewForHeaderInSection,
                        (IMP *)&orig_tableView_viewForHeaderInSection);

        MSHookMessageEx(SLTwitterSettingsController,
                        @selector(tableView:heightForHeaderInSection:),
                        (IMP)hook_tableView_heightForHeaderInSection,
                        (IMP *)&orig_tableView_heightForHeaderInSection);
    }
}