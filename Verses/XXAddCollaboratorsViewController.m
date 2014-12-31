//
//  XXAddCollaboratorsViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/28/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXAppDelegate.h"
#import "XXAddCollaboratorsViewController.h"
#import <AddressBook/AddressBook.h>
#import "XXAddressBookContactCell.h"
#import "XXAddCollaboratorEmailCell.h"
#import "User+helper.h"
#import "XXAlert.h"

@interface XXAddCollaboratorsViewController () <UITextFieldDelegate> {
    NSMutableArray *_addressBookContacts;
    NSArray *_peopleArray;
    AFHTTPRequestOperationManager *manager;
    UIImageView *navBarShadowView;
    UIColor *textColor;
    UIBarButtonItem *backButton;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *doneButton;
    NSMutableArray *_selectedContacts;
    NSMutableArray *_invitations;
    UITextField *emailTextField;
}

@end

@implementation XXAddCollaboratorsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    manager = [(XXAppDelegate*)[UIApplication sharedApplication].delegate manager];
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
    _peopleArray = [NSArray array];
    _addressBookContacts = [NSMutableArray array];
    _selectedContacts = [NSMutableArray array];
    _invitations = [NSMutableArray array];
    
    self.tableView.rowHeight = 80.f;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.title = @"Add Collaborators";
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"blackX"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneEditing)];
    saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(addContacts)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    if (!_currentUser){
        _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    
    [self.tableView setBackgroundColor:[UIColor clearColor]];
}

- (void)viewWillAppear:(BOOL)animated {
    navBarShadowView.hidden = YES;
    CFErrorRef error = nil;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    if (!addressBook){
        //some sort of error preventing us from grabbing the address book
        return;
    }
    
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (granted){
            CFArrayRef arrayOfPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
            _peopleArray = (__bridge NSArray *)(arrayOfPeople);
            CFRelease(arrayOfPeople);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self sortPeople];
            });
        } else {
            [XXAlert show:@"Verses doesn't have access to your address book. If you'd like to add collaborators from your address book, please go into your device settings and give Verses access." withTime:4.f];
        }
    });
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
    }
}

- (void)back {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)sortPeople {
    for (int i = 0;i < _peopleArray.count;i++) {
        ABRecordRef person = (__bridge ABRecordRef)([_peopleArray objectAtIndex:i]);
        if (person) {
            NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(person,kABPersonFirstNameProperty);
            NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(person,kABPersonLastNameProperty);
            
            NSString *email;
            ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
            if (emails != nil){
                CFIndex ix = ABMultiValueGetIndexForIdentifier(emails, 0);
                if (ix >= 0){
                    CFStringRef emailRef = ABMultiValueCopyValueAtIndex(emails, ix);
                    if (emailRef != nil) email = (__bridge_transfer NSString*) (emailRef);
                }
                CFRelease(emails);
            }
            
            
            
            ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
            NSString *phone1;
            if (phones != nil){
                CFIndex px = ABMultiValueGetIndexForIdentifier(phones, 0);
                if (px >= 0) {
                    CFStringRef phoneRef = ABMultiValueCopyValueAtIndex(phones, px);
                    phone1 = (__bridge_transfer NSString*) (phoneRef);
                }
                CFRelease(phones);
            }
            
            
            NSMutableDictionary *userDict = [NSMutableDictionary dictionary];
            
            NSData *imgData = (NSData*)CFBridgingRelease(ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail));
            
            if (imgData != nil) {
                [userDict setObject:[UIImage imageWithData:imgData] forKey:@"image"];
            }
            if (firstName) {
                [userDict setObject:firstName forKey:@"first_name"];
            }
            if (lastName){
                [userDict setObject:lastName forKey:@"last_name"];
            }
            if (phone1) {
                phone1 = [phone1 stringByReplacingOccurrencesOfString:@"+" withString:@""];
                phone1 = [phone1 stringByReplacingOccurrencesOfString:@"-" withString:@""];
                phone1 = [phone1 stringByReplacingOccurrencesOfString:@"(" withString:@""];
                phone1 = [phone1 stringByReplacingOccurrencesOfString:@")" withString:@""];
                [userDict setObject:[phone1 stringByReplacingOccurrencesOfString:@" " withString:@""] forKey:@"phone"];
            }
            if (email) {
                [userDict setObject:email forKey:@"email"];
            }
            
            if ([userDict objectForKey:@"first_name"] || [userDict objectForKey:@"email"]){
                [_addressBookContacts addObject:userDict];
            }
        }
    }
    
    
    NSArray *newArray = [_addressBookContacts sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSString *first = [(NSDictionary*)a objectForKey:@"first_name"];
        NSString *second = [(NSDictionary*)b objectForKey:@"first_name"];
        return [first compare:second];
    }];
    _addressBookContacts = [newArray mutableCopy];
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (void)addContacts {
    for (NSDictionary *contactDict in _selectedContacts){
        if (![_currentUser.contacts containsObject:contactDict]) {
            [self createContact:contactDict];
        }
    }
}

- (void)createContact:(NSDictionary*) contactDict{
    //NSLog(@"contactDict: %@",contactDict);
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([contactDict objectForKey:@"email"]){
        [parameters setObject:[contactDict objectForKey:@"email"] forKey:@"email"];
    }
    if ([contactDict objectForKey:@"phone"]){
        [parameters setObject:[contactDict objectForKey:@"phone"] forKey:@"phone"];
    }
    if ([contactDict objectForKey:@"first_name"]){
        [parameters setObject:[contactDict objectForKey:@"first_name"] forKey:@"first_name"];
    }
    if ([contactDict objectForKey:@"last_name"]){
        [parameters setObject:[contactDict objectForKey:@"last_name"] forKey:@"last_name"];
    }
    [manager POST:[NSString stringWithFormat:@"%@/users/%@/add_contact",kAPIBaseUrl,[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Successfully created contact: %@",responseObject);
        if ([responseObject objectForKey:@"user"]){
            User *newContact = [User MR_findFirstByAttribute:@"identifier" withValue:[[responseObject objectForKey:@"user"] objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!newContact){
                newContact = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [newContact populateFromDict:[responseObject objectForKey:@"user"]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AddContact" object:self userInfo:@{@"contact":newContact}];
        } else if ([[responseObject objectForKey:@"failure"] isEqualToNumber:@YES]) {
            [_invitations addObject:contactDict];
        }
        if (contactDict == _selectedContacts.lastObject){
            [self processedLastContact];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to create contact: %@",error.description);
        if (contactDict == _selectedContacts.lastObject){
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    }];
}

- (void)processedLastContact {
    if (_invitations.count){
        if (_invitations.count == 1){
            NSDictionary *contactDict = _invitations.firstObject;
            NSString *contactString;
            if ([contactDict objectForKey:@"email"]){
                contactString = [contactDict objectForKey:@"email"];
            } else if ([contactDict objectForKey:@"first_name"]){
                contactString = [contactDict objectForKey:@"first_name"];
            }
            
            [XXAlert show:[NSString stringWithFormat:@"%@ doesn't use Verses yet, but we've sent them an invite to join you.",contactString] withTime:3.7f];
        } else {
            [XXAlert show:@"Some of those folks dont use Verses yet, but we've sent them invites to join you." withTime:3.7f];
            NSLog(@"multiple invitations");
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        if (_selectedContacts.count == 1){
            [XXAlert show:[NSString stringWithFormat:@"Collaborator added"] withTime:2.7f];
        } else {
            [XXAlert show:[NSString stringWithFormat:@"Collaborators added"] withTime:2.7f];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }/* else {
      [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to send this invitation. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
      }*/
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0){
        return 1;
    } else {
        return _addressBookContacts.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        XXAddCollaboratorEmailCell *cell = (XXAddCollaboratorEmailCell *)[tableView dequeueReusableCellWithIdentifier:@"AddCollaboratorCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXAddCollaboratorEmailCell" owner:nil options:nil] lastObject];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [cell.textField setFont:[UIFont fontWithName:kSourceSansPro size:16]];
        cell.textField.placeholder = kAddCollaboratorPlaceholder;
        emailTextField = cell.textField;
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
        cell.textField.leftView = paddingView;
        cell.textField.leftViewMode = UITextFieldViewModeAlways;
        cell.textField.delegate = self;
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [cell.textField setKeyboardAppearance:UIKeyboardAppearanceDark];
            if (!cell.textField.text.length){
                [cell.textField setTextColor:[UIColor whiteColor]];
                [cell.textField setText:kAddCollaboratorPlaceholder];
            }
        } else {
            [cell.textField setKeyboardAppearance:UIKeyboardAppearanceDefault];
        }
        
        [cell.createButton setTitleColor:textColor forState:UIControlStateNormal];
        [cell.createButton.titleLabel setFont:[UIFont fontWithName:kSourceSansPro size:17]];
        [cell.createButton addTarget:self action:@selector(addEmail) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    } else {
        XXAddressBookContactCell *cell = (XXAddressBookContactCell *)[tableView dequeueReusableCellWithIdentifier:@"AddressBookContactCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXAddressBookContactCell" owner:nil options:nil] lastObject];
        }
        NSDictionary *userDict = _addressBookContacts[indexPath.row];
        [cell configureContact:userDict];
        [cell.textLabel setTextColor:textColor];
        [cell.detailTextLabel setTextColor:textColor];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        if ([_selectedContacts containsObject:userDict]){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    }
}

- (void)addEmail {
    if (emailTextField.text.length && [emailTextField.text rangeOfString:@"@"].location != NSNotFound){
        NSDictionary *emailDict = @{@"email":emailTextField.text};
        [_selectedContacts addObject:emailDict];
        [self createContact:emailDict];
        [self doneEditing];
    } else {
        [[[UIAlertView alloc] initWithTitle:nil message:@"Please make sure you've added a valid email address." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1){
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        NSDictionary *userDict = _addressBookContacts[indexPath.row];
        if ([_selectedContacts containsObject:userDict]){
            [_selectedContacts removeObject:userDict];
        } else {
            [_selectedContacts addObject:userDict];
        }
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
    }
    UIView *selectionView = [[UIView alloc] initWithFrame:cell.frame];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [selectionView setBackgroundColor:kTableViewCellSelectionColorDark];
    } else {
        [selectionView setBackgroundColor:kTableViewCellSelectionColor];
    }
    
    cell.selectedBackgroundView = selectionView;
    cell.backgroundColor = [UIColor clearColor];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        [self addEmail];
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem = doneButton;
    if ([textField.text isEqualToString:kAddCollaboratorPlaceholder]){
        [textField setText:@""];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [textField setTextColor:[UIColor whiteColor]];
        }
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField.text isEqualToString:kAddCollaboratorPlaceholder]){
        [textField setTextColor:[UIColor whiteColor]];
        [textField setText:kAddCollaboratorPlaceholder];
    }
}

-(void)doneEditing {
    [self.view endEditing:YES];
    self.navigationItem.rightBarButtonItem = saveButton;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
