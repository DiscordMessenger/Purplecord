#import "SettingsController.h"
#import "UIColorScheme.h"
#include "../discord/Util.hpp"
#include "../discord/LocalSettings.hpp"

@implementation SettingsController

- (instancetype)init
{
	[super initWithStyle:UITableViewStyleGrouped];
	self.tableView.backgroundColor = [UIColorScheme getBackgroundColor];
	self.tableView.allowsSelection = NO;
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.title = @"Settings";
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tv
{
	return 2;
}

- (NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:
			return 2;
		case 1:
			return 3;
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
	}
	return nil;
}

- (void)darkModeToggle:(UISwitch*)sender {
	GetLocalSettings()->SetDarkMode(sender.on);
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

- (NSString*)textForRowAtIndexPath:(NSIndexPath*)indexPath andHasSwitch:(BOOL*)hasSwitch andSelector:(SEL*)selector andDefaultState:(BOOL*)defaultState
{
	*hasSwitch = NO;
	*defaultState = NO;
	*selector = nil;
	
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
				case 1:
					*hasSwitch = YES;
					*selector = @selector(disableFormattingToggle:);
					*defaultState = GetLocalSettings()->DisableFormatting();
					return @"Disable Formatting";
			}
			break;
		}
		case 1:
		{
			switch (indexPath.row)
			{
				case 0:
					*hasSwitch = YES;
					*selector = @selector(showAttachmentsToggle:);
					*defaultState = GetLocalSettings()->ShowAttachmentImages();
					return @"Show Attached Images";
				case 1:
					*hasSwitch = YES;
					*selector = @selector(showEmbedsToggle:);
					*defaultState = GetLocalSettings()->ShowEmbedContent();
					return @"Show Embedded Content";
				case 2:
					*hasSwitch = YES;
					*selector = @selector(showEmbedImagessToggle:);
					*defaultState = GetLocalSettings()->ShowEmbedImages();
					return @"Show Embedded Images";
			}
		}
	}
	
	return @"Unknown";
}

- (UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	SEL sel;
	BOOL hasSwitch , defaultState;
	NSString* text = [self textForRowAtIndexPath:indexPath andHasSwitch:&hasSwitch andSelector:&sel andDefaultState:&defaultState];
	
	static NSString* cellIdentifier = @"SettingsCell";
	UITableViewCell* cell = [tv dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell)
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
	
	cell.textLabel.text = text;
	cell.backgroundColor = [UIColorScheme getTextBackgroundColor];
	cell.textLabel.textColor = [UIColorScheme getTextColor];
	
	if (hasSwitch)
	{
		UISwitch* toggle = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
		
		if (sel) {
			[toggle addTarget:self action:sel forControlEvents:UIControlEventValueChanged];
			toggle.on = defaultState;
		}
		
		cell.accessoryView = toggle;
	}
	else
	{
		cell.accessoryView = nil;
	}
	
	return cell;
}

@end
