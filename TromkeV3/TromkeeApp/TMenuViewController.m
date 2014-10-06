//
//  TMenuViewController.m
//  Tromke
//
//  Created by Satyanarayana SVV on 2/13/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TMenuViewController.h"

@interface TMenuViewController ()

@property (nonatomic, strong) NSArray* menuItems;

@end

@implementation TMenuViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.menuItems = @[@"My Profile", @"People you may like", @"Help", @"Logout"];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [self.delegate userClickedMenu:indexPath.row];
//}
//
#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MenuCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = self.menuItems[indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate userClickedMenu:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
