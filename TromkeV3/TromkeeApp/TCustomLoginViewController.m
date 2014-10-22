//
//  TCustomLoginViewController.m
//  Tromke
//
//  Created by Satyam on 5/23/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TCustomLoginViewController.h"
#import "TTermsAndPolicyViewController.h"

@interface TCustomLoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *userName;
@property (weak, nonatomic) IBOutlet UITextField *passWord;
@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;
@property (strong, nonatomic) NSMutableData* data;

@end

@implementation TCustomLoginViewController

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
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
    [self.view addGestureRecognizer:tapGesture];
    
    if (!IS_IPHONE_5) {
        self.bgImageView.image = [UIImage imageNamed:@"NewLoginBG4"];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:FIRST_TIME]) {
        [self performSegueWithIdentifier:HELP sender:nil];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:FIRST_TIME];
    }
    
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)hideKeyboard:(id)gesture {
    [self.userName resignFirstResponder];
    [self.passWord resignFirstResponder];
}

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

- (IBAction)authenticateWithParse:(id)sender {
    
    [self hideKeyboard:nil];
    
    if (![Reachability isReachable]) {
        return;
    }

    NSString* usr = self.userName.text;
    NSString* pwd = self.passWord.text;
    
    if (!usr || !usr.length) {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please enter username" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    
    if (!pwd || !pwd.length) {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please enter password" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    
    PF_MBProgressHUD* progress = [PF_MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progress.labelText = @"Authenticating";
    [PFUser logInWithUsernameInBackground:usr password:pwd block:^(PFUser *user, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [PF_MBProgressHUD hideHUDForView:self.view animated:YES];
            if (error) {
                NSLog(@"Failed to authenticate: %@", error.localizedDescription);
                if ([error.domain isEqualToString:@"Parse"]) {
                    NSDictionary* usrinfo = error.userInfo;
                    [[[UIAlertView alloc] initWithTitle:@"Warning" message:usrinfo[@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Failed to authenticate. Try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                }
            } else {
                [self performSegueWithIdentifier:MAIN sender:nil];
            }
        });
    }];
    
}

- (IBAction)signWithFB:(id)sender {
    [self hideKeyboard:nil];
    
    if (![Reachability isReachable]) {
        return;
    }

    [[[UIAlertView alloc] initWithTitle:@"Accept" message:@"By signing in to Tromke Account you acknowledge that you have read, understood and agree to the Terms and Privacy Policy"
                            delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self initiateActualFBAuthentication];
    }
}

-(void)initiateActualFBAuthentication {
    NSArray* permissions = @[@"publish_actions", @"read_friendlists", @"email", @"user_friends"];
    
    PF_MBProgressHUD* progress = [PF_MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progress.labelText = @"Authenticating";
    [PFFacebookUtils logInWithPermissions:permissions block:^(PFUser *user, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [PF_MBProgressHUD hideHUDForView:self.view animated:YES];
            if (!user) {
                //Failed to login
                NSString* msg;
                if (!error) {
                    DLog(@"The user cancelled the Facebook login.");
                    msg = @"User cancelled Facebook Login";
                } else {
                    NSLog(@"An error occurred: %@", error.localizedDescription);
                    msg = @"Failed ao authenticate with Facebook. Try again.";
                }
                
                [[[UIAlertView alloc] initWithTitle:@"Warning" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            } else {
                if (user.isNew) {
                    DLog(@"User signed up and logged in through Facebook!");
                    if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
                        [FBRequestConnection startWithGraphPath:@"me" parameters:[NSDictionary dictionaryWithObject:@"picture,id,birthday,email,name,gender,first_name,last_name" forKey:@"fields"] HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                            if (!error) {
                                [self facebookRequestDidLoad:result];
                            } else {
                                [self facebookRequestDidFailWithError:error];
                            }
                        }];
                    }
                } else {
                    DLog(@"User logged in through Facebook!");
                }
                //successfully logged in
                [self performSegueWithIdentifier:MAIN sender:nil];
            }
        });
    }];
}

#pragma mark - Facebook Methods

- (void)facebookRequestDidLoad:(id)result {
    // This method is called twice - once for the user's /me profile, and a second time when obtaining their friends. We will try and handle both scenarios in a single method.
    PFUser *user = [PFUser currentUser];
    
    if (user) {
        NSString *facebookName = result[@"name"];
        NSString* firstName = result[@"first_name"];
        NSString* lastName = result[@"last_name"];
        
        if (facebookName && [facebookName length] != 0) {
            [user setObject:facebookName forKey:FACEBOOK_DISPLAYNAME];
            DLog(@"FB Name: %@", facebookName);
        } else if ( firstName && firstName.length && lastName && lastName.length ){
            user[FACEBOOK_DISPLAYNAME] = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        } else if (firstName && firstName.length) {
            user[FACEBOOK_DISPLAYNAME] = firstName;
        } else if (lastName && lastName.length) {
            user[FACEBOOK_DISPLAYNAME] = lastName;
        } else {
            [user setObject:@"TromkeeUser" forKey:FACEBOOK_DISPLAYNAME];
        }
        
        NSString *facebookId = result[@"id"];
        if (facebookId && [facebookId length] != 0) {
            DLog(@"FB ID: %@", facebookId);
            [user setObject:facebookId forKey:FACEBOOK_ID_KEY];
        }
        
        NSMutableDictionary* dict = [@{} mutableCopy];
        NSDictionary* pictureURL = result[@"picture"];
        if (pictureURL) {
            dict[@"picture"] = [pictureURL valueForKeyPath:@"data.url"];
        }
        
        NSString* birthday = result[@"birthday"];
        if (birthday) {
            dict[@"birthday"] = birthday;
        }
        
        NSString* email = result [@"email"];
        if (email) {
            dict[@"email"] = email;
        }
        
        NSString* gender = result[@"gender"];
        if (gender) {
            dict[@"gender"] = gender;
        }
        
        user[@"profile"] = dict;
        
        [user saveEventually];
    }
    
    NSURL *profilePictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", [[PFUser currentUser] objectForKey:FACEBOOK_ID_KEY]]];
    NSURLRequest *profilePictureURLRequest = [NSURLRequest requestWithURL:profilePictureURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f]; // Facebook profile picture cache policy: Expires in 2 weeks
    [NSURLConnection connectionWithRequest:profilePictureURLRequest delegate:self];
}

- (void)facebookRequestDidFailWithError:(NSError *)error {
    NSLog(@"Facebook error: %@", error);
    
    if ([PFUser currentUser]) {
        if ([[error userInfo][@"error"][POST_TYPE] isEqualToString:@"OAuthException"]) {
            NSLog(@"The Facebook token was invalidated. Logging out.");
            // Clear all caches
            [PFQuery clearAllCachedResults];
            // Log out
            [PFUser logOut];

        }
    }
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _data = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [TUtility processFacebookProfilePictureData:_data];
}


#pragma mark - Textfield Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.userName && self.userName.text.length) {
        [self.passWord becomeFirstResponder];
    } else if (textField == self.passWord) {
        [self authenticateWithParse:nil];
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (!IS_IPHONE_5) {
        [UIView animateWithDuration:0.5 animations:^{
            CGRect r = self.view.frame;
            r.origin.y = -50;
            self.view.frame = r;
        }];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (!IS_IPHONE_5) {
        [UIView animateWithDuration:0.6 animations:^{
            CGRect r = self.view.frame;
            r.origin.y = 0;
            self.view.frame = r;
        }];
    }
}

@end
