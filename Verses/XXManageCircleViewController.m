//
//  XXManageCircleViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/28/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXManageCircleViewController.h"
#import "Circle+helper.h"
#import "XXNewCircleCell.h"
#import "XXAlert.h"
#import "XXContactCell.h"

@interface XXManageCircleViewController () <UITextFieldDelegate, UITextViewDelegate, UIAlertViewDelegate> {
    UIImageView *navBarShadowView;
    UIBarButtonItem *backButton;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *saveButton;
    UIColor *textColor;
    XXAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    User *_currentUser;
    UISwitch *publicSwitch;
    UITextField *nameTextField;
    UITextView *blurbTextView;
}

@end

@implementation XXManageCircleViewController
@synthesize circle = _circle;

- (void)viewDidLoad
{
    [super viewDidLoad];
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"blackX"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    if (delegate.currentUser){
        _currentUser = delegate.currentUser;
    } else {
        _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    
    //if (_currentUser.contacts.count == 0){
        [self loadContacts];
    //}
    
    if (_circle){
        saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(post)];
        self.navigationItem.rightBarButtonItem = saveButton;
        
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), 44)];
        [footerView setBackgroundColor:[UIColor clearColor]];
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [deleteButton setFrame:CGRectMake(screenWidth()/2-70, 0, 140, 44)];
        [deleteButton setTitle:@"DELETE CIRCLE" forState:UIControlStateNormal];
        [deleteButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:13]];
        [deleteButton addTarget:self action:@selector(confirmDeletion) forControlEvents:UIControlEventTouchUpInside];
        [deleteButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [deleteButton setBackgroundColor:[UIColor clearColor]];
        deleteButton.layer.borderColor = [UIColor redColor].CGColor;
        deleteButton.layer.borderWidth = .5f;
        [footerView addSubview:deleteButton];
        self.tableView.tableFooterView = footerView;
        
    } else {
        _circle = [Circle MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        _circle.publicCircle = [NSNumber numberWithBool:NO];
        _circle.owner = _currentUser;
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        [set addObject:_currentUser];
        _circle.users = set;
        saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:@selector(post)];
        self.navigationItem.rightBarButtonItem = saveButton;
    }
    
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    publicSwitch = [[UISwitch alloc] init];
    
}

- (void)confirmDeletion {
    [[[UIAlertView alloc] initWithTitle:@"Confirmation needed" message:@"Are you sure you want to delete this circle? This can't be undone." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
}

- (void)deleteCircle {
    
    [manager DELETE:[NSString stringWithFormat:@"%@/circles/%@",kAPIBaseUrl,_circle.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success deleting circle: %@",responseObject);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DeleteCircle" object:nil userInfo:@{@"circle":_circle}];
        [self dismissViewControllerAnimated:YES completion:^{
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to delete circle: %@",error.description);
        
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]){
        [self deleteCircle];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteBack"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([_circle.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        //[titleTextField becomeFirstResponder];
    }
}

- (void)loadContacts {

    [manager GET:[NSString stringWithFormat:@"%@/users/%@/contacts",kAPIBaseUrl,[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting user's contacts: %@",[responseObject objectForKey:@"users"]);
        NSMutableOrderedSet *contactSet = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *userDict in [responseObject objectForKey:@"users"]){
            User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[userDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!user){
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [user populateFromDict:userDict];
            [contactSet addObject:user];
        }
        for (User *user in _currentUser.contacts){
            if (![contactSet containsObject:user]){
                NSLog(@"Deleting a contact that no longer exists: %@",user.penName);
                [user MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        
        _currentUser.contacts = contactSet;
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error getting user's contacts: %@",error.description);
    }];
}

- (void)back {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (NSString*)processUsers {
    NSMutableArray *array = [NSMutableArray array];
    for (User *user in _circle.users){
        [array addObject:user.identifier];
    }
    return [array componentsJoinedByString:@","];
}

- (void)post {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (nameTextField.text.length){
        [parameters setObject:nameTextField.text forKey:@"name"];
    }
    if (blurbTextView.text.length){
        [parameters setObject:blurbTextView.text forKey:@"description"];
    }
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    
    NSString *userIds = [self processUsers];
    [parameters setObject:userIds forKey:@"users"];
    
    if (!_circle || [_circle.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        [ProgressHUD show:@"Creating your writing circle..."];
        
        [manager POST:[NSString stringWithFormat:@"%@/circles",kAPIBaseUrl] parameters:@{@"circle":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success creating a new writing circle: %@",responseObject);
            [XXAlert show:@"Circle created" withTime:2.1f];
            [_circle populateFromDict:[responseObject objectForKey:@"circle"]];
            [_currentUser addCircle:_circle];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CreateCircle" object:nil userInfo:@{@"circle":_circle}];
            
            [ProgressHUD dismiss];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                
                [self dismissViewControllerAnimated:YES completion:^{
                    
                }];
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error creating new writing circle: %@",error.description);
            [ProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to create this writing circle. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }];
    } else {
        [ProgressHUD show:@"Updating your writing circle..."];
        [manager PATCH:[NSString stringWithFormat:@"%@/circles/%@",kAPIBaseUrl,_circle.identifier] parameters:@{@"circle":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success updating writing circle: %@",responseObject);
            [XXAlert show:@"Circle updated" withTime:2.1f];
            [_circle populateFromDict:[responseObject objectForKey:@"circle"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [ProgressHUD dismiss];
                [self dismissViewControllerAnimated:YES completion:^{
                    
                }];
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error updating writing circle: %@",error.description);
            [ProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to update your writing circle. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }];
    }
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0){
        return 3;
    } else {
        return _currentUser.contacts.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0){
        switch (indexPath.row) {
            case 0:
                return 54;
                break;
            case 1:
                return 100;
                break;
            case 2:
                return 54;
                break;
            default:
                return 0;
                break;
        }
    } else {
        return 80;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0){
        return 0;
    } else {
        return 34;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), 44)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, screenWidth()-20, 44)];
    [headerLabel setTextColor:textColor];
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    [headerLabel setBackgroundColor:[UIColor clearColor]];
    [headerLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:13]];
    [headerLabel setText:@"MANAGE MEMBERS"];
    [headerView addSubview:headerLabel];
    
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        XXNewCircleCell *cell = (XXNewCircleCell *)[tableView dequeueReusableCellWithIdentifier:@"NewCircleCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXNewCircleCell" owner:nil options:nil] lastObject];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            cell.textField.keyboardAppearance = UIKeyboardAppearanceDark;
            cell.textView.keyboardAppearance = UIKeyboardAppearanceDark;
        } else {
            cell.textField.keyboardAppearance = UIKeyboardAppearanceDefault;
            cell.textView.keyboardAppearance = UIKeyboardAppearanceDefault;
        }
        
        //reset values to nothing/nil before setting them to something 
        [cell.textField setText:@""];
        [cell.textLabel setText:@""];
        cell.accessoryView = UITableViewCellAccessoryNone;
    
        switch (indexPath.row) {
            case 0:
                nameTextField = cell.textField;
                [cell.textField setDelegate:self];
                [cell.textField setHidden:NO];
                [cell.textField setTextColor:textColor];
                [cell.textView setHidden:YES];
                
                if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
                    if (_circle.name.length){
                        [cell.textField setText:_circle.name];
                    } else {
                        [cell.textField setText:kCircleNamePlaceholder];
                    }
                } else {
                    if (_circle.name.length){
                        [cell.textField setText:_circle.name];
                    }
                }
                [cell.textField setPlaceholder:kCircleNamePlaceholder];
                [cell.textField setFont:[UIFont fontWithName:kSourceSansProSemibold size:19]];
                break;
            case 1:
                if (_circle.blurb.length){
                    [cell.textView setText:_circle.blurb];
                    [cell.textView setTextColor:textColor];
                } else {
                    [cell.textView setText:kCircleBlurbPlaceholder];
                    [cell.textView setTextColor:kPlaceholderTextColor];
                }
                [cell.textView setDelegate:self];
                [cell.textView setHidden:NO];
                blurbTextView = cell.textView;
                [cell.textField setHidden:YES];
                [cell.textView setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
                break;
            case 2:
                [cell.textView setHidden:YES];
                [cell.textField setHidden:YES];
                cell.accessoryView = publicSwitch;
                [cell.textLabel setTextColor:textColor];
                if ([_circle.publicCircle isEqualToNumber:[NSNumber numberWithBool:YES]]){
                    [cell.textLabel setText:@"Circle is public"];
                    [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:16]];
                } else {
                    [cell.textLabel setText:@"Circle is not public"];
                    [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProLight size:16]];
                }
                [publicSwitch setOn:_circle.publicCircle.boolValue];
                [publicSwitch addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
                break;
                
            default:
                break;
        }
        return cell;
    } else {
        XXContactCell *cell = (XXContactCell *)[tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXContactCell" owner:nil options:nil] lastObject];
        }
        User *contact = [_currentUser.contacts objectAtIndex:indexPath.row];
        [cell configureContact:contact];
        [cell.locationLabel setTextColor:textColor];
        [cell.nameLabel setTextColor:textColor];
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        [_circle.users enumerateObjectsUsingBlock:^(User *user, NSUInteger idx, BOOL *stop) {
            if ([user.identifier isEqualToNumber:contact.identifier]){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                *stop = YES;
            }
        }];

        return cell;
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
        [selectionView setBackgroundColor:[UIColor colorWithWhite:.9 alpha:.23]];
    }
    
    cell.selectedBackgroundView = selectionView;
    cell.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1){
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        User *user = _currentUser.contacts[indexPath.row];
        if ([_circle.users containsObject:user]){
            [_circle removeUser:user];
        } else {
            [_circle addUser:user];
        }
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)toggleSwitch:(UISwitch*)theSwitch {
    [_circle setPublicCircle:[NSNumber numberWithBool:theSwitch.isOn]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    });
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem = doneButton;
    if ([textField.text isEqualToString:kCircleNamePlaceholder]){
        [textField setText:@""];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        if (textField.text.length && ![textField.text isEqualToString:kCircleNamePlaceholder]){
            _circle.name = textField.text;
        }
    } else {
        if (textField.text.length && ![textField.text isEqualToString:kCircleNamePlaceholder]){
            _circle.name = textField.text;
        }
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.navigationItem.rightBarButtonItem = doneButton;
    if ([textView.text isEqualToString:kCircleBlurbPlaceholder]){
        [textView setText:@""];
        [textView setTextColor:textColor];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length){
        [textView setTextColor:textColor];
        _circle.blurb = textView.text;
    } else {
        [textView setText:kCircleBlurbPlaceholder];
        [textView setTextColor:kPlaceholderTextColor];
    }
}

- (void)doneEditing {
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = saveButton;
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
