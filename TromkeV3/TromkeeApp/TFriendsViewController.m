//
//  TFriendsViewController.m
//  Tromke
//
//  Created by Satyam on 8/11/14.
//  Copyright (c) 2014 tromke. All rights reserved.
//

#import "TFriendsViewController.h"
#import "TFriendCell.h"
#import "APContact.h"
#import "APPhoneWithLabel.h"
#import "APAddressBook.h"
#import "TProfileViewController.h"

@import MessageUI;

@interface TFriendsViewController () <TFriendDelegate, UISearchBarDelegate, MFMessageComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tablView;
@property (weak, nonatomic) IBOutlet UIButton* tromersButton;
@property (weak, nonatomic) IBOutlet UIButton* contactsButton;
@property (weak, nonatomic) IBOutlet UISearchBar* searchBar;

@property (nonatomic, strong) NSArray* tromers;
@property (nonatomic, strong) NSArray* contacts;

@property (nonatomic, strong) NSMutableArray* displayData;

@property (nonatomic, strong) APAddressBook *addressBook;
@property (nonatomic) NSInteger option;
@end

@implementation TFriendsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _addressBook = [[APAddressBook alloc] init];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _addressBook = [[APAddressBook alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.option = 0;
    [self loadTromers];
    [self loadContacts];
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


-(void)loadTromers {
    __weak __typeof(self) weakSelf = self;
    PF_MBProgressHUD* progress = [PF_MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progress.labelText = @"Fetching...";
    [PFCloud callFunctionInBackground:@"trommers" withParameters:@{}
        block:^(id result, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    NSMutableArray* arr = [[NSMutableArray alloc] initWithCapacity:10];
                    for (PFUser* usr in result) {
                        [arr addObject:@{@"User": usr, @"Selected":@NO}];
                    }
                    self.tromers = arr;
                    self.displayData = [arr mutableCopy];
                    [weakSelf.tablView reloadData];
                }
                [PF_MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    }];
}


- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)followInvite:(id)sender {
    if (self.option == 0) {
        [self followTomers];
    } else if (self.option == 1) {
        [self inviteContacts];
    }
}

-(void)followTomers {
    NSIndexSet* indexes = [self.displayData indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj[@"Selected"] boolValue] == YES;
    }];
    
    if (indexes.count) {
        
        NSArray* tromkeIDs = [[self.displayData objectsAtIndexes:indexes] valueForKeyPath:@"User.objectId"];

        [PFCloud callFunctionInBackground:@"followTrommers" withParameters:@{@"users" : tromkeIDs}
                                    block:^(id result, NSError *error) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            if (!error) {
                                                [[[UIAlertView alloc] initWithTitle:@"Succesful" message:@"You are following new tromers successfully" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                                            }
                                        });
                                    }];

        
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please select Tromers before following them" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self loadTromers];
}

-(void)inviteContacts {
    NSIndexSet* indexes = [self.displayData indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj[@"IsSelected"] boolValue];
    }];

    if (indexes.count) {
        NSArray* phoneNumbers = [[self.displayData objectsAtIndexes:indexes] valueForKeyPath:@"Phone"];
        
        MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
        if([MFMessageComposeViewController canSendText]) {
            controller.body = @"Hey I really liked this new fun neighborhood ap Tromke and am sure you will like it too. You can download it at http://bit.ly/1qrvxdD. See you soon on Tromke!";
            //[NSString stringWithFormat:@"%@ invites you to use Tromke application. ", [TUtility getDisplayNameForUser:[PFUser currentUser]]];
            controller.recipients = phoneNumbers;
            controller.messageComposeDelegate = self;
            [self presentViewController:controller animated:YES completion:nil];
        }
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please select Contacts before inviting them" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}


- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSString* message;
    NSString* title;
    switch (result) {
        case MessageComposeResultCancelled:
            title = @"Warning";
            message = @"User cancelled the message";
            break;
        case MessageComposeResultSent:
            title = @"Successful";
            message = @"Message sent successfully";
            break;
        case MessageComposeResultFailed:
            title = @"Warning";
            message = @"Failed to send message";
            break;
        default:
            break;
    }
    
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

-(IBAction)changeSelection:(id)sender {
    UIButton* btn = (UIButton*)sender;
    self.option = btn.tag;
    if (self.option == 0) {
//        [self.tromersButton setImage:[UIImage imageNamed:@"NewTromakeSelected"] forState:UIControlStateNormal];
//        [self.contactsButton setImage:[UIImage imageNamed:@"NewContactsUnSelected"] forState:UIControlStateNormal];

        [self.tromersButton setTitleColor:[TUtility colorFromHexString:@"#2DC2EE"] forState:UIControlStateNormal];
        [self.contactsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        
        self.displayData = [self.tromers mutableCopy];
    } else if (self.option == 1) {
//        [self.tromersButton setImage:[UIImage imageNamed:@"NewTromakeUnSelected"] forState:UIControlStateNormal];
//        [self.contactsButton setImage:[UIImage imageNamed:@"NewContactsSelected"] forState:UIControlStateNormal];

        [self.tromersButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.contactsButton setTitleColor:[TUtility colorFromHexString:@"#2DC2EE"] forState:UIControlStateNormal];
        
        self.displayData = [self.contacts mutableCopy];
    }
    
    [self.tablView reloadData];
    [self.tablView setContentOffset:CGPointZero animated:YES];
}

#pragma mark - Tableview methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.displayData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TFriendCell* cell;
    
    if (self.option == 0) {
        static NSString* cellIdentfier = @"TROMERCELL";
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentfier forIndexPath:indexPath];
        cell.delegate = self;
        cell.friendID = indexPath.row;
        
        NSDictionary* dict = self.displayData[indexPath.row];
        PFUser* usr = dict[@"User"];
        cell.friendName.text = [TUtility getDisplayNameForUser:usr];

        PFFile* imgFile = usr[@"profilePictureSmall"];
        if (imgFile) {
            cell.friendImage.file = imgFile;
            [cell.friendImage loadInBackground];
        } else {
            cell.friendImage.image = [UIImage imageNamed:@"Logo"];
        }
        
        if ([dict[@"Selected"] boolValue]) {
            [cell.selection setImage:[UIImage imageNamed:@"NewSelected"] forState:UIControlStateNormal];
        } else {
            [cell.selection setImage:[UIImage imageNamed:@"NewUnSelected"] forState:UIControlStateNormal];
        }
    } else if (self.option == 1){
        static NSString* cellIdentfier = @"CONTACTCELL";
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentfier forIndexPath:indexPath];
        cell.delegate = self;
        cell.friendID = indexPath.row;
        
        NSDictionary* person = self.displayData[indexPath.row];
        cell.friendName.text = person[@"Name"];
        cell.friendPhone.text = person[@"Phone"];
        if (person[@"Thumbnail"]) {
            cell.friendImage.image = person[@"Thumbnail"];
        } else {
            cell.friendImage.image = [UIImage imageNamed:@"NewPhone"];
        }
        
        if ([person[@"IsSelected"] boolValue]) {
            [cell.selection setImage:[UIImage imageNamed:@"NewSelected"] forState:UIControlStateNormal];
        } else {
            [cell.selection setImage:[UIImage imageNamed:@"NewUnSelected"] forState:UIControlStateNormal];            
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
//    if (self.option == 0) {
//        NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:self.displayData[indexPath.row]];
//        if ([dict[@"Selected"] boolValue]) {
//            dict[@"Selected"] = @NO;
//        } else {
//            dict[@"Selected"] = @YES;
//        }
//        [self.displayData replaceObjectAtIndex:indexPath.row withObject:dict];
//    } else if (self.option == 1) {
//        NSMutableDictionary* person = [NSMutableDictionary dictionaryWithDictionary:self.displayData[indexPath.row]];
//        if ([person[@"IsSelected"] boolValue]) {
//            person[@"IsSelected"] = @NO;
//        } else {
//            person[@"IsSelected"] = @YES;
//        }
//        [self.displayData replaceObjectAtIndex:indexPath.row withObject:person];
//    }
//    
//    [self.tablView reloadData];
}

-(UIImage*)makeRoundImage:(UIImage*)squareImage {
    CGSize imageSize = squareImage.size;
    CGRect imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
    // Create the clipping path and add it
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:imageRect];
    [path addClip];
    [squareImage drawInRect:imageRect];
    
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return roundedImage;
}

-(void)selectedFriend:(NSInteger)friendID {
    if (self.option == 0) {
        NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:self.displayData[friendID]];
        if ([dict[@"Selected"] boolValue]) {
            dict[@"Selected"] = @NO;
        } else {
            dict[@"Selected"] = @YES;
        }
        [self.displayData replaceObjectAtIndex:friendID withObject:dict];
    } else if (self.option == 1) {
        NSMutableDictionary* person = [NSMutableDictionary dictionaryWithDictionary:self.displayData[friendID]];
        if ([person[@"IsSelected"] boolValue]) {
            person[@"IsSelected"] = @NO;
        } else {
            person[@"IsSelected"] = @YES;
        }
        [self.displayData replaceObjectAtIndex:friendID withObject:person];
    }
    
    [self.tablView reloadData];
}

- (void)loadContacts
{
    __weak __typeof(self) weakSelf = self;
    _addressBook.fieldsMask = APContactFieldFirstName | APContactFieldPhones | APContactFieldPhonesWithLabels | APContactFieldThumbnail;
    _addressBook.sortDescriptors = @[
                                     [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES],
                                     [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES]];
    _addressBook.filterBlock = ^BOOL(APContact *contact)
    {
        return contact.phones.count > 0;
    };
    
    [_addressBook loadContacts:^(NSArray *contacts, NSError *error)
     {
         if (!error) {
             weakSelf.contacts = contacts;
         }
         else
         {
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                 message:error.localizedDescription
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil];
             [alertView show];
         }
     }];
}

#pragma mark - Searchbar Delegates

//- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
//    if (searchBar.text.length != 0) {
//        searchBar.showsCancelButton = YES;
//    } else {
//        searchBar.showsCancelButton = NO;
//    }
//}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    if (self.option == 0) {
        if (searchText.length != 0) {
            [self filterWithText:searchText];
        } else {
            self.displayData = [self.tromers mutableCopy];
            [self.tablView reloadData];
        }
    } else if (self.option == 1) {
        if (searchText.length != 0) {
            [self filterWithText:searchText];
        } else {
            self.displayData = [self.contacts mutableCopy];
            [self.tablView reloadData];
        }
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    if (self.option == 0) {
        self.displayData = [self.tromers mutableCopy];
    } else {
        self.displayData = [self.contacts mutableCopy];
    }

    [self.tablView reloadData];
}

-(void)filterWithText:(NSString*)searchText {
    if (self.option == 0) {
        NSIndexSet* indexes = [self.tromers indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            PFUser* usr = obj[@"User"];
            return ([[TUtility getDisplayNameForUser:usr] rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound);
        }];
        
        if (indexes.count) {
            self.displayData = [[self.tromers objectsAtIndexes:indexes] mutableCopy];
            [self.tablView reloadData];
        }
        
    } else if (self.option == 1) {
        NSIndexSet* indexes = [self.contacts indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [obj[@"Name"] rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound;
        }];
        
        if (indexes.count) {
            self.displayData = [[self.contacts objectsAtIndexes:indexes] mutableCopy];
            [self.tablView reloadData];
        }
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"TROMPROFILE"]) {
        NSIndexPath* indxPath = [self.tablView indexPathForSelectedRow];
        
        TProfileViewController* profileVC = segue.destinationViewController;
        profileVC.userProfile = self.displayData[indxPath.row][@"User"];
    }
}
@end
