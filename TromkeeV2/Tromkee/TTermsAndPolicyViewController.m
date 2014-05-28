//
//  TTermsAndPolicyViewController.m
//  Tromke
//
//  Created by Satyam on 5/27/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TTermsAndPolicyViewController.h"

@interface TTermsAndPolicyViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UILabel *viewTitle;


- (IBAction)goBack:(id)sender;

@end

@implementation TTermsAndPolicyViewController

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
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString* fName;
    if (self.showTerms) {
        self.viewTitle.text = @"Tromke Terms of Use";
        fName = @"Terms";
    } else {
        self.viewTitle.text = @"Policy";
        fName = @"Policy";
    }
    NSString* filePath = [[NSBundle mainBundle] pathForResource:fName ofType:@"html"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]]];
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

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
