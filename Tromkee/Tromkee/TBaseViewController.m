//
//  TBaseViewController.m
//  Tromke
//
//  Created by Satyanarayana SVV on 4/10/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TBaseViewController.h"

@interface TBaseViewController ()

@property (nonatomic, strong) UILabel* notificationCountValue;

@end

@implementation TBaseViewController

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
    UIButton* notificationCount = [UIButton buttonWithType:UIButtonTypeCustom];
    notificationCount.frame = CGRectMake(60, 27, 30, 30);
    [notificationCount setImage:[UIImage imageNamed:@"Callout"] forState:UIControlStateNormal];
    [notificationCount addTarget:self action:@selector(showUserActivity) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:notificationCount];
    
    self.notificationCountValue = [[UILabel alloc] initWithFrame:CGRectMake(60, 27, 30, 21)];
    self.notificationCountValue.textColor = [UIColor whiteColor];
    self.notificationCountValue.font = [UIFont boldSystemFontOfSize:11];
    self.notificationCountValue.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.notificationCountValue];
}


-(void)showUserActivity {
    UIViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"USERACTIVITY"];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)viewWillAppear:(BOOL)animated {
    [self updateNotificationCount];
    [super viewWillAppear:animated];
}

-(void)updateNotificationCount {
    PFQuery* query = [PFQuery queryWithClassName:@"Installation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count) {
            PFObject* obj = [objects firstObject];
            self.notificationCountValue.text = [obj[@"badge"] stringValue];
        } else {
            self.notificationCountValue.text = @"0";
        }
    }];
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
