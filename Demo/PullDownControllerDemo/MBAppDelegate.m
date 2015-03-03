//
//  MBAppDelegate.m
//  PullDownControllerDemo
//
//  Created by Matej Bukovinski on 22. 02. 13.
//  Copyright (c) 2013 Matej Bukovinski. All rights reserved.
//

#import "MBAppDelegate.h"
#import "CKPullDownController.h"
#import "MBImagesViewController.h"
#import "MBSettingsController.h"


@implementation MBAppDelegate

#pragma mark - Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = [self setUpViewControllerHierarchy];
    [self.window makeKeyAndVisible];
    return YES;
}

#pragma mark - Controllers

- (UIViewController *)setUpViewControllerHierarchy {
	MBImagesViewController *front = [[MBImagesViewController alloc] init];
    front.view.backgroundColor = [UIColor colorWithWhite:.85 alpha:1];
	MBSettingsController *back = [[MBSettingsController alloc] init];
    back.view.backgroundColor = [UIColor whiteColor];
	CKPullDownController *pullDownController = [[CKPullDownController alloc] initWithFrontController:front backController:back];
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:pullDownController];
	navigationController.navigationBarHidden = YES;
	// Adjust top spacing for iOS 7 status bar
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
		pullDownController.closedTopOffset += 20.f;
	}
	return navigationController;
}

@end
