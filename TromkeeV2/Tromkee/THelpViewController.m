//
//  THelpViewController.m
//  Tromke
//
//  Created by Satyam on 5/23/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "THelpViewController.h"

@interface THelpViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrlView;
@property (weak, nonatomic) IBOutlet UIButton *signupBtn;

@end

@implementation THelpViewController

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
    self.signupBtn.backgroundColor = [TUtility colorFromHexString:REGISTER_BOTTOMGREEN];
    // Do any additional setup after loading the view.
    UIImageView* img1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, self.view.frame.size.height)];
    
    UIImageView* img2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, 320, self.view.frame.size.height)];

    UIButton* btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"PinkArrow"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(scrollDown:) forControlEvents:UIControlEventTouchUpInside];
    btn.frame = CGRectMake(0, self.view.frame.size.height - 194, 320, 194);
    
    if (IS_IPHONE_5) {
        img1.image = [UIImage imageNamed:@"What5"];
        img2.image = [UIImage imageNamed:@"Green5"];
    } else {
        img1.image = [UIImage imageNamed:@"What4"];
        img2.image = [UIImage imageNamed:@"Green4"];
    }
    
    [self.scrlView addSubview:img1];
    [self.scrlView addSubview:img2];
    [self.scrlView addSubview:btn];
    
    
    self.scrlView.contentSize = CGSizeMake(320, 2 * self.view.frame.size.height);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"%@", segue.identifier);
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


-(void)scrollDown:(id)sender {
    [self.scrlView scrollRectToVisible:CGRectMake(0, self.view.frame.size.height, 320, self.view.frame.size.height) animated:YES];
    self.scrlView.userInteractionEnabled = NO;
    self.signupBtn.hidden = NO;
}

- (IBAction)continueWithApp:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


@end
