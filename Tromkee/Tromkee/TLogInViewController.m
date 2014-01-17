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
    
//    NSString *text = @"Sign up and start sharing your story with your friends.";
//    CGSize textSize = [text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:18.0f] constrainedToSize:CGSizeMake( 255.0f, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
//    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake( ([UIScreen mainScreen].bounds.size.width - textSize.width)/2.0f, 160.0f, textSize.width, textSize.height)];
//    [textLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:18.0f]];
//    [textLabel setLineBreakMode:NSLineBreakByWordWrapping];
//    [textLabel setNumberOfLines:0];
//    [textLabel setText:text];
//    [textLabel setTextColor:[UIColor colorWithRed:214.0f/255.0f green:206.0f/255.0f blue:191.0f/255.0f alpha:1.0f]];
//    [textLabel setBackgroundColor:[UIColor clearColor]];
//    [textLabel setTextAlignment:NSTextAlignmentCenter];
//    [self.logInView addSubview:textLabel];
    
    [self.logInView setLogo:nil];

    UIButton* btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn setTitle:@"Skip, let me  see >>" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(dismissAnimated:) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = [UIColor whiteColor];
    btn.frame = CGRectMake(20, 60, 280, 50);
    [self.logInView addSubview:btn];

    
//    self.fields = PFLogInFieldsUsernameAndPassword | PFLogInFieldsFacebook;
    self.logInView.usernameField.placeholder = @"Enter your email";
}

-(void)dismissAnimated:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
