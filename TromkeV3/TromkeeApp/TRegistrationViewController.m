//
//  TRegistrationViewController.m
//  Tromke
//
//  Created by Satyam on 5/23/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TRegistrationViewController.h"
#import "TTermsAndPolicyViewController.h"

@interface TRegistrationViewController ()

@property (weak, nonatomic) IBOutlet UITextField *userName;
@property (weak, nonatomic) IBOutlet UITextField *passWord;
@property (weak, nonatomic) IBOutlet UITextField *email;
@property (weak, nonatomic) IBOutlet UITextField *fullName;

@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;

@end

@implementation TRegistrationViewController

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
    self.view.backgroundColor = [TUtility colorFromHexString:REGISTER_MIDDLEYELLOW];
    self.topView.backgroundColor = [TUtility colorFromHexString:REGISTER_TOPBLUE];
    self.bottomView.backgroundColor = [TUtility colorFromHexString:REGISTER_BOTTOMGREEN];
    
    // Do any additional setup after loading the view.
    UIView *paddingView1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)];
    self.userName.leftView = paddingView1;
    self.userName.leftViewMode = UITextFieldViewModeAlways;

    UIView *paddingView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)];
    self.passWord.leftView = paddingView2;
    self.passWord.leftViewMode = UITextFieldViewModeAlways;
    
    UIView *paddingView3 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)];
    self.email.leftView = paddingView3;
    self.email.leftViewMode = UITextFieldViewModeAlways;

    UIView *paddingView4 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)];
    self.fullName.leftView = paddingView4;
    self.fullName.leftViewMode = UITextFieldViewModeAlways;
    
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)hideKeyboard:(id)gesture {
    [self.userName resignFirstResponder];
    [self.passWord resignFirstResponder];
    [self.email resignFirstResponder];
    [self.fullName resignFirstResponder];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"Terms"]) {
        TTermsAndPolicyViewController* vc = segue.destinationViewController;
        vc.showTerms = YES;
    } else if ([segue.identifier isEqualToString:@"Policy"]) {
        TTermsAndPolicyViewController* vc = segue.destinationViewController;
        vc.showTerms = NO;
    }
}


- (IBAction)skipRegistration:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)registerWithParse:(id)sender {
    [self hideKeyboard:nil];
    
    if (![Reachability isReachable]) {
        return;
    }
    
    NSString* usr = self.userName.text;
    NSString* pwd = self.passWord.text;
    NSString* em = self.email.text;

    
    if (!usr || !usr.length) {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please enter username" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    
    if (!pwd || !pwd.length) {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please enter password" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    
    if (!em || !em.length) {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please enter email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }

    [[[UIAlertView alloc] initWithTitle:@"Accept" message:@"By creating a Tromke Account you acknowledge that you have read, understood and agree to the Terms and Privay Policy"
                              delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self initiateActualRegistration];
    }
}


-(void)initiateActualRegistration {
    NSString* usr = self.userName.text;
    NSString* pwd = self.passWord.text;
    NSString* em = self.email.text;

    __block PFUser* registerUser = [PFUser user];
    registerUser.username = usr;
    registerUser.password = pwd;
    registerUser.email = em;
    
    PF_MBProgressHUD* progress = [PF_MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progress.labelText = @"Registering";
    
    [registerUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [PF_MBProgressHUD hideHUDForView:self.view animated:YES];
            if (succeeded) {
                [self.navigationController popViewControllerAnimated:YES];
            } else if (error) {
                NSLog(@"Registration error: %@", error.localizedDescription);
                if ([error.domain isEqualToString:@"Parse"]) {
                    NSDictionary* usrinfo = error.userInfo;
                    [[[UIAlertView alloc] initWithTitle:@"Warning" message:usrinfo[@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Failed to register, try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                }
            }
        });
    }];
}

#pragma mark - Textfield Delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (IS_IPHONE_5) {
//        if (textField == self.fullName) {
//            [UIView animateWithDuration:0.2 animations:^{
//                CGRect r = self.view.frame;
//                r.origin.y = -70;
//                self.view.frame = r;
//            }];
//        }
    } else {
        if (textField == self.email || textField == self.fullName) {
            [UIView animateWithDuration:0.2 animations:^{
                CGRect r = self.view.frame;
                r.origin.y = -100;
                self.view.frame = r;
            }];
        }
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.2 animations:^{
        CGRect r = self.view.frame;
        r.origin.y = 0;
        self.view.frame = r;
    }];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.userName && self.userName.text.length) {
        [self.passWord becomeFirstResponder];
    } else if (textField == self.passWord && self.passWord.text.length) {
        [self.email becomeFirstResponder];
    } else if (textField == self.email && self.email.text.length) {
//        [self.fullName becomeFirstResponder];
        [self registerWithParse:nil];
    } /*else if (textField == self.fullName) {
        [self registerWithParse:nil];
    }*/
    
    return YES;
}


@end
