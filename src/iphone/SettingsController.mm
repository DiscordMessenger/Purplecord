#import "SettingsController.h"
#import "UIColorScheme.h"
#import "UIProgressHUD.h"
#import "NetworkController.h"
#include "../discord/Util.hpp"
#include "../discord/LocalSettings.hpp"
#include "../discord/DiscordInstance.hpp"

@implementation SettingsController {
	BOOL purging;
}

- (void)settingsWillApplyAfterRestart
{
	UIAlertView *alert = [
		[UIAlertView alloc]
		initWithTitle:@"Settings Change"
		message:@"The changes will completely apply after the app has been restarted. You may see incomplete changes until then."
		delegate:nil
		cancelButtonTitle:@"OK"
		otherButtonTitles:nil
	];
	
	[alert show];
	[alert release];
}

- (instancetype)init
{
	[super initWithStyle:UITableViewStyleGrouped];
	self.tableView.backgroundColor = [UIColorScheme getBackgroundColor];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.title = @"Settings";
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tv
{
	return 4;
}

- (NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:
			return 1;
		case 1:
			return 2; // Show Embeds does nothing yet.
		case 2:
			return 1; // From Links doesn't do anything yet.
		case 3:
			return 2;
	}
	return 0;
}

- (NSString*)tableView:(UITableView*)tv titleForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:
			return @"Appearance";
		case 1:
			return @"Chat";
		case 2:
			return @"Show Images";
		case 3:
			return @"Data Cleanup";
	}
	return nil;
}

- (void)darkModeToggle:(UISwitch*)sender {
	GetLocalSettings()->SetDarkMode(sender.on);
	GetLocalSettings()->Save();
	[self settingsWillApplyAfterRestart];
}

- (void)replyMentionByDefaultToggle:(UISwitch*)sender {
	GetLocalSettings()->SetReplyMentionByDefault(sender.on);
	GetLocalSettings()->Save();
}
- (void)disableFormattingToggle:(UISwitch*)sender {
	GetLocalSettings()->SetDisableFormatting(sender.on);
	GetLocalSettings()->Save();
}
- (void)showAttachmentsToggle:(UISwitch*)sender {
	GetLocalSettings()->SetShowAttachmentImages(sender.on);
	GetLocalSettings()->Save();
}
- (void)showEmbedsToggle:(UISwitch*)sender {
	GetLocalSettings()->SetShowEmbedContent(sender.on);
	GetLocalSettings()->Save();
}
- (void)showEmbedImagesToggle:(UISwitch*)sender {
	GetLocalSettings()->SetShowEmbedImages(sender.on);
	GetLocalSettings()->Save();
}

#define RESET_TO_DEFAULT @"Reset to Default"
#define LOG_OUT @"Log Out"

- (void)resetToDefault {
	UIActionSheet* actionSheet = [[UIActionSheet alloc]
		initWithTitle:nil
		delegate:self
		cancelButtonTitle:@"Cancel"
		destructiveButtonTitle:RESET_TO_DEFAULT
		otherButtonTitles:nil
	];
	
	[actionSheet showInView:self.view];
	[actionSheet release];
}

- (void)logOut {
	UIActionSheet* actionSheet = [[UIActionSheet alloc]
		initWithTitle:nil
		delegate:self
		cancelButtonTitle:@"Cancel"
		destructiveButtonTitle:LOG_OUT
		otherButtonTitles:nil
	];
	
	[actionSheet showInView:self.view];
	[actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *buttonName = [actionSheet buttonTitleAtIndex:buttonIndex];
	
	if ([buttonName isEqualToString:RESET_TO_DEFAULT])
	{
		DbgPrintF("Reset To Default Confirmed");
		return;
	}
	if ([buttonName isEqualToString:LOG_OUT])
	{
		GetLocalSettings()->SetToken("");
		GetDiscordInstance()->CloseGatewaySession();
		[GetNetworkController() sendToLoginPrompt];
		return;
	}
}

- (void)purgeCache
{
	if (purging)
		return;
	
	UIWindow* window = self.view.window;
	
	UIProgressHUD* hud = [[UIProgressHUD alloc] initWithWindow:window];
	[hud setText:@"Loading"];
	[hud setShowsText:YES];
	[hud show:YES];
	
	[self performSelectorInBackground:@selector(purgeCacheBGThread:) withObject:hud];
}

- (void)purgeCacheBGThread:(NSObject*)object
{
@autoreleasepool {
	purging = YES;
	
	UIProgressHUD* hud = (UIProgressHUD*)object;
	
	std::string directory = GetCachePath();
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* path = [NSString stringWithUTF8String:directory.c_str()];
	NSError* error = nil;
	NSArray* contents = [fm contentsOfDirectoryAtPath:path error:&error];
	if (!contents) {
		[hud performSelector:@selector(hide) withObject:nil];
		[hud release];
		purging = NO;
		return;
	}
	
	for (NSString* item in contents) {
		NSString* fullPath = [path stringByAppendingPathComponent:item];
		[fm removeItemAtPath:fullPath error:&error];
	}
	
	[hud performSelectorOnMainThread:@selector(done) withObject:nil waitUntilDone:NO];
	[hud performSelectorOnMainThread:@selector(setText:) withObject:@"Done" waitUntilDone:NO];
	
	// hide after 1 second
	usleep(500000);
	[hud performSelector:@selector(hide) withObject:nil];
	[hud release];
	purging = NO;
}
}

- (NSString*)textForRowAtIndexPath:(NSIndexPath*)indexPath andHasSwitch:(BOOL*)hasSwitch andSelector:(SEL*)selector andDefaultState:(BOOL*)defaultState andIsButton:(BOOL*)isButton
{
	*selector = nil;
	*isButton = NO;
	*hasSwitch = NO;
	*defaultState = NO;
	
	switch (indexPath.section)
	{
		case 0:
		{
			switch (indexPath.row)
			{
				case 0:
					*hasSwitch = YES;
					*selector = @selector(darkModeToggle:);
					*defaultState = GetLocalSettings()->UseDarkMode();
					return @"Dark Mode";
			}
			break;
		}
		case 1:
		{
			switch (indexPath.row)
			{
				case 0:
					*hasSwitch = YES;
					*selector = @selector(disableFormattingToggle:);
					*defaultState = GetLocalSettings()->DisableFormatting();
					return @"Disable Formatting";
				case 1:
					*hasSwitch = YES;
					*selector = @selector(replyMentionByDefaultToggle:);
					*defaultState = GetLocalSettings()->ReplyMentionByDefault();
					return @"Mention By Default";
				case 2:
					*hasSwitch = YES;
					*selector = @selector(showEmbedsToggle:);
					*defaultState = GetLocalSettings()->ShowEmbedContent();
					return @"Show Embeds";
			}
		}
		case 2:
		{
			switch (indexPath.row)
			{
				case 0:
					*hasSwitch = YES;
					*selector = @selector(showAttachmentsToggle:);
					*defaultState = GetLocalSettings()->ShowAttachmentImages();
					return @"From Attachments";
				case 1:
					*hasSwitch = YES;
					*selector = @selector(showEmbedImagesToggle:);
					*defaultState = GetLocalSettings()->ShowEmbedImages();
					return @"From Links";
			}
		}
		case 3:
		{
			switch (indexPath.row)
			{
				case 0:
					*isButton = YES;
					*selector = @selector(purgeCache);
					return @"Purge Cache";
				case 1:
					*isButton = YES;
					*selector = @selector(logOut);
					return @"Log Out";
			}
		}
	}
	
	return @"Unknown";
}

- (UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	SEL sel;
	BOOL isButton, hasSwitch, defaultState;
	NSString* text = [self textForRowAtIndexPath:indexPath andHasSwitch:&hasSwitch andSelector:&sel andDefaultState:&defaultState andIsButton:&isButton];
	
	static NSString* cellIdentifier = @"SettingsCell";
	UITableViewCell* cell = [tv dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell)
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
	
	cell.textLabel.text = text;
	cell.backgroundColor = [UIColorScheme getTextBackgroundColor];
	cell.textLabel.textColor = [UIColorScheme getTextColor];
	
	if (isButton)
	{
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.textLabel.textAlignment = UI_TEXT_ALIGNMENT_CENTER;
		cell.accessoryView = nil;
	}
	else if (hasSwitch)
	{
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.textLabel.textAlignment = UI_TEXT_ALIGNMENT_LEFT;
		UISwitch* toggle = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
		
		if (sel) {
			[toggle addTarget:self action:sel forControlEvents:UIControlEventValueChanged];
			toggle.on = defaultState;
		}
		
		cell.accessoryView = toggle;
	}
	else
	{
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.textLabel.textAlignment = UI_TEXT_ALIGNMENT_LEFT;
		cell.accessoryView = nil;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	SEL sel;
	BOOL isButton, hasSwitch, defaultState;
	NSString* text = [self textForRowAtIndexPath:indexPath andHasSwitch:&hasSwitch andSelector:&sel andDefaultState:&defaultState andIsButton:&isButton];
	
	if (!isButton)
		return;
	
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	[self performSelector:sel];
}

@end
