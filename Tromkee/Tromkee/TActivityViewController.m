//
//  TActivityViewController.m
//  Tromke
//
//  Created by Satyanarayana SVV on 2/17/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TActivityViewController.h"
#import "MBProgressHUD.h"
#import "TActivityCell.h"
#import "TAppDelegate.h"

@interface TActivityViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) MBProgressHUD* progress;
@property (nonatomic, strong) NSArray* activities;
@property (nonatomic, weak) IBOutlet UITableView* activitiesTable;
@property (nonatomic, weak) IBOutlet UITextView* activityDescription;
@property (weak, nonatomic) IBOutlet UIView *bottomView;

- (IBAction)postActivityDescription:(id)sender;

@end

@implementation TActivityViewController

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
    [self update];
}

-(void)update {
    self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.progress.labelText = @"Fetching ...";
    self.progress.dimBackground = YES;
    PFQuery* activityQuery = [PFQuery queryWithClassName:@"Activity" predicate:[NSPredicate predicateWithFormat:@"stickersInLocation == %@", self.stickerObject]];
    [activityQuery includeKey:@"fromUser"];

    __weak TActivityViewController* weakSelf = self;
    [activityQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Error in getting activities: %@", error.localizedDescription);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.progress hide:YES];
                weakSelf.activities = objects;
                [weakSelf.activitiesTable reloadData];
            });
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.activities.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TActivityCell* cell;
    if (indexPath.row % 2 == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"LEFT"];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"RIGHT"];
    }
    
    if (indexPath.row == 0) {
        PFObject* user = self.stickerObject[@"user"];
        cell.personName.text = user[@"username"];
        cell.comment.text = self.stickerObject[@"data"];
    } else {
        PFObject* comment = self.activities[indexPath.row - 1];
        PFObject* fromUser = comment[@"fromUser"];
        cell.personName.text = fromUser[@"username"];
        cell.comment.text = comment[@"content"];
    }
    
    return cell;
}

#pragma mark - TextView methods

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return YES;
    }
    
    return textView.text.length + (text.length - range.length) <= POSTDATA_LENGTH;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [UIView animateWithDuration:0.35 animations:^{
        CGRect r = self.bottomView.frame;
        r.origin.y -= 216;
        self.bottomView.frame = r;
    }];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [UIView animateWithDuration:0.1 animations:^{
        CGRect r = self.bottomView.frame;
        r.origin.y += 216;
        self.bottomView.frame = r;
    }];
}

- (IBAction)postActivityDescription:(id)sender {
    [self.activityDescription resignFirstResponder];
    
    if ([self.activityDescription.text length] == 0) {
        return;
    }
    
    if (![PFUser currentUser]) {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"You must login in order to post a sticker !!!" delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles: @"Login", nil] show];
        return;
    }
    
    self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.progress.labelText = @"Fetching ...";
    self.progress.dimBackground = YES;

    PFObject* activiy = [PFObject objectWithClassName:@"Activity"];
    activiy[@"fromUser"] = [PFUser currentUser];
    activiy[@"toUser"] = self.stickerObject[@"user"];
    activiy[@"type"] = @"follows";
    activiy[@"content"] = self.activityDescription.text;
    activiy[@"stickersInLocation"] = self.stickerObject;
    
    __weak TActivityViewController* weakself = self;
    [activiy saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [weakself.progress hide:YES];
        if (succeeded) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Successful" message:@"Comment posted successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                [self update];
            });
        }
    }];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [(TAppDelegate*)[[UIApplication sharedApplication] delegate] presentLoginViewControllerAnimated:NO];
    }
}

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


@end
