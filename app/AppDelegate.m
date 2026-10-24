//
//  AppDelegate.m
//  OpenTune 9
//

#import "AppDelegate.h"
#import "OTRootViewController.h"
#import "OTTheme.h"
#import "OTStore.h"

#import <AVFoundation/AVFoundation.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self restoreAppearance];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [OTTheme background];

    [self configureAudioSession];
    [self configureAppearance];

    OTRootViewController *root = [[OTRootViewController alloc] init];
    self.window.rootViewController = root;
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[OTStore sharedStore] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[OTStore sharedStore] synchronize];
}

#pragma mark - Configuracion

- (void)restoreAppearance
{
    id accent = [[OTStore sharedStore] settingForKey:@"ot.accent"];
    if (accent) {
        [OTTheme setAccentHex:[accent unsignedIntegerValue]];
    }
    id pureBlack = [[OTStore sharedStore] settingForKey:@"ot.pureBlack"];
    if (pureBlack) {
        [OTTheme setPureBlack:[pureBlack boolValue]];
    }
}

- (void)configureAudioSession
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:NULL];
    [session setActive:YES error:NULL];
}

- (void)configureAppearance
{
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setBarTintColor:[OTTheme background]];
    [[UINavigationBar appearance] setTintColor:[OTTheme primary]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
        NSForegroundColorAttributeName: [OTTheme text],
        NSFontAttributeName: [OTTheme font:17.0 weight:UIFontWeightSemibold]
    }];

    [[UISwitch appearance] setOnTintColor:[OTTheme primary]];
    [[UIProgressView appearance] setTrackTintColor:[OTTheme surfaceHigh]];
    [[UIProgressView appearance] setProgressTintColor:[OTTheme primary]];
}

@end
