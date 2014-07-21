//
//  TWelcomeViewController.m
//  Tromke
//
//  Created by Satyam on 7/21/14.
//  Copyright (c) 2014 tromke. All rights reserved.
//

#import "TWelcomeViewController.h"
#import "TAppDelegate.h"

@interface TWelcomeViewController ()

@end

@implementation TWelcomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self performSelector:@selector(updateUI) withObject:nil afterDelay:0.05];
}


-(void)updateUI {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:FIRST_TIME]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:FIRST_TIME];
        [(TAppDelegate*)[[UIApplication sharedApplication] delegate] showHelpViewController];
    } else if (![PFUser currentUser] || ![[PFUser currentUser] isAuthenticated]) {
        [(TAppDelegate*)[[UIApplication sharedApplication] delegate] showLoginViewController];
    } else {
        [(TAppDelegate*)[[UIApplication sharedApplication] delegate] showMainViewController];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
