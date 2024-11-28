#include <dlfcn.h>
#import "KMCGeigerCounter.h"

//__attribute__((constructor))
int EntryPoint() {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // NSDictionary *settingDic = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.dongle.fpscounter.plist"];

    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    // NSString *formatedIdentifier = [NSString stringWithFormat:@"fpscounterEnabled-%@", identifier];

    if(![identifier isEqual:@"com.apple.springboard"]) [KMCGeigerCounter sharedGeigerCounter].enabled = YES;

    [pool drain];

	return 1;
}

__attribute__((destructor))
void deEntry(){
}

%hook UIWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        EntryPoint();
    });
	return %orig;
}
%end

/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.

%hook ClassName

// Hooking a class method
+ (id)sharedInstance {
	return %orig;
}

// Hooking an instance method with an argument.
- (void)messageName:(int)argument {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.

	%orig; // Call through to the original function with its original arguments.
	%orig(nil); // Call through to the original function with a custom argument.

	// If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
}

// Hooking an instance method with no arguments.
- (id)noArguments {
	%log;
	id awesome = %orig;
	[awesome doSomethingElse];

	return awesome;
}

// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end
*/
