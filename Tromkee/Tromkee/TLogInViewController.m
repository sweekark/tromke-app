//
//  PAPLogInViewController.m
//  Anypic
//
//  Created by Mattieu Gamache-Asselin on 5/17/12.
//

#import "TLogInViewController.h"

@implementation TLogInViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    if ([UIScreen mainScreen].bounds.size.height > 480.0f) {
//        // for the iPhone 5
//        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"BackgroundLogin-568h.png"]];
//    } else {
//        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"BackgroundLogin.png"]];
//    }
    
//    [self.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo"]]];
//    CGRect logoRect = self.logInView.logo.frame;
//    logoRect.origin.y = 10;
//    self.logInView.logo.frame = logoRect;

    UIButton* btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn setTitle:@"Skip, let me  see >>" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(dismissAnimated:) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.frame = CGRectMake(20, self.view.frame.size.height - 190, 280, 15);
    [self.logInView addSubview:btn];

    self.logInView.usernameField.placeholder = @"Enter your email";
}

-(void)dismissAnimated:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
