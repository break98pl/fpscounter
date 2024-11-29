#import "KMCGeigerCounter.h"

%hook UIWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
		if([identifier isEqual:@"com.apple.springboard"]){
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1), dispatch_get_main_queue(), ^(void){
				[KMCGeigerCounter sharedGeigerCounter].enabled = YES;
			});
		}
		else {
			NSDictionary *settingDic = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.dongle.fpscounter.plist"];
			NSString *formatedIdentifier = [NSString stringWithFormat:@"fpscounterDisabled-%@", identifier];
			if (![[settingDic objectForKey:formatedIdentifier] boolValue]) {
				[KMCGeigerCounter sharedGeigerCounter].enabled = YES;
			}
		}
    });
	return %orig;
}
%end

