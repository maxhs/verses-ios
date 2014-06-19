//
//  XXCollaborateViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/31/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXCollaborateViewController.h"
#import "XXContactCell.h"
#import "Circle+helper.h"
#import "XXAlert.h"

@interface XXCollaborateViewController () {
    AFHTTPRequestOperationManager *manager;
    NSMutableArray *_contacts;
    NSMutableArray *_circles;
    BOOL loadingCircles;
    BOOL loadingContacts;
    CGRect screen;
    NSIndexPath *indexPathToRemove;
    UIBarButtonItem *cancelButton;
    UIAlertView *addContactAlert;
    UIColor *textColor;
    UIImageView *navBarShadowView;
    UIBarButtonItem *addButton;
    User *currentUser;
}

@end

@implementation XXCollaborateViewController
@synthesize collaborators = _collaborators;
@synthesize circleCollaborators = _circleCollaborators;

- (void)viewDidLoad
{
    [super viewDidLoad];
    screen = [UIScreen mainScreen].bounds;
    manager = [(XXAppDelegate*)[UIApplication sharedApplication].delegate manager];
    currentUser = [(XXAppDelegate*)[UIApplication sharedApplication].delegate currentUser];
    _contacts = currentUser.contacts.array.mutableCopy;
    _circles = currentUser.circles.array.mutableCopy;
    
    if (self.navigationController.viewControllers.firstObject == self){
        cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"blackX"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissView)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    } else {
        self.title = @"Contacts";
    }
    
    if (_manageContacts){
        addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addContact)];
        self.navigationItem.rightBarButtonItem = addButton;
        [self loadContacts];
    } else {
        self.navigationItem.rightBarButtonItem = nil;
        _contacts = currentUser.contacts.array.mutableCopy;
        [self loadContacts];
        _circles = currentUser.circles.array.mutableCopy;
        [self loadCircles];
    }
    
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:0 alpha:.05]];
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.manageContacts) [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] registerTouchForwardingClass:[XXContactCell class]];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
    }
    navBarShadowView.hidden = YES;
}

- (void)loadContacts {
    [ProgressHUD show:@"Finding your contacts..."];
    loadingContacts = YES;
    [manager GET:[NSString stringWithFormat:@"%@/users/%@/contacts",kAPIBaseUrl,[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting user's contacts: %@",[responseObject objectForKey:@"users"]);
        NSMutableOrderedSet *contactSet = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *userDict in [responseObject objectForKey:@"users"]){
            User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[userDict objectForKey:@"id"]];
            if (!user){
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [user populateFromDict:userDict];
            [contactSet addObject:user];
        }
        for (User *user in currentUser.contacts){
            if (![contactSet containsObject:user]){
                NSLog(@"Deleting a contact that no longer exists: %@",user.penName);
                [user MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        
        currentUser.contacts = contactSet;
        _contacts = contactSet.array.mutableCopy;
        loadingContacts = NO;
        
        if (_manageContacts){
            [self.tableView reloadData];
        } else {
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        loadingContacts = NO;
        NSLog(@"error getting user's contacts: %@",error.description);
    }];
}

- (void)loadCircles {
    loadingCircles = YES;
    [manager GET:[NSString stringWithFormat:@"%@/circles",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success fetching circles: %@",responseObject);
        NSMutableOrderedSet *circleSet = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *circleDict in [responseObject objectForKey:@"circles"]){
            Circle *circle = [Circle MR_findFirstByAttribute:@"identifier" withValue:[circleDict objectForKey:@"id"]];
            if (!circle){
                circle = [Circle MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [circle populateFromDict:circleDict];
            [circleSet addObject:circle];
        }
        for (Circle *circle in currentUser.circles){
            if (![circleSet containsObject:circle]){
                NSLog(@"Deleting a circle that no longer exists: %@",circle.name);
                [circle MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        currentUser.circles = circleSet;
        _circles = circleSet.array.mutableCopy;
        loadingCircles = NO;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure getting circles: %@",error.description);
        loadingCircles = NO;
        [ProgressHUD dismiss];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_manageContacts && loadingContacts){
        return 0;
    } else {
        if (_manageContacts){
            return 1;
        } else {
            return 2;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0){
        if (self.manageContacts){
            if (_contacts.count == 0 && !loadingContacts) {
                return 1;
            } else {
                return _contacts.count;
            }
        } else if (_circles.count == 0 && !loadingCircles){
            return 1;
        } else {
            return _circles.count;
        }
    } else {
        if (_contacts.count == 0 && !loadingContacts){
            return 1;
        } else {
            return _contacts.count;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && !self.manageContacts){
        if (_contacts.count){
            XXContactCell *cell = (XXContactCell *)[tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXContactCell" owner:nil options:nil] lastObject];
            }
            Circle *circle = [_circles objectAtIndex:indexPath.row];
            [cell configureCircle:circle];
            [cell.locationLabel setTextColor:textColor];
            [cell.nameLabel setTextColor:textColor];
            cell.accessoryType = UITableViewCellAccessoryNone;
            [_circleCollaborators enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([(NSNumber*)obj isEqualToNumber:circle.identifier]){
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    *stop = YES;
                }
            }];
            return cell;
        } else {
            static NSString *CellIdentifier = @"NothingCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            UIButton *nothingButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [nothingButton setTitle:@"You don't have any writing circles." forState:UIControlStateNormal];
            [nothingButton.titleLabel setNumberOfLines:0];
            [nothingButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:20]];
            [nothingButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            nothingButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            [nothingButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [nothingButton setBackgroundColor:[UIColor clearColor]];
            [cell addSubview:nothingButton];
            [nothingButton setFrame:CGRectMake(20, 0, screen.size.width-40, screen.size.height-84)];

            return cell;
        }
    } else {
        if (_contacts.count){
            XXContactCell *cell = (XXContactCell *)[tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXContactCell" owner:nil options:nil] lastObject];
            }
            User *contact = [_contacts objectAtIndex:indexPath.row];
            [cell configureContact:contact];
            [cell.locationLabel setTextColor:textColor];
            [cell.nameLabel setTextColor:textColor];
            cell.accessoryType = UITableViewCellAccessoryNone;
            if (self.manageContacts){
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            } else {
                [_collaborators enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if ([(NSNumber*)obj isEqualToNumber:contact.identifier]){
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                        *stop = YES;
                    }
                }];
            }
            return cell;
        } else {
            static NSString *CellIdentifier = @"NothingCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            UIButton *nothingButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [nothingButton setTitle:@"No contacts yet :(" forState:UIControlStateNormal];
            [nothingButton.titleLabel setNumberOfLines:0];
            [nothingButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:20]];
            [nothingButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            nothingButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            [nothingButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [nothingButton setBackgroundColor:[UIColor clearColor]];
            [cell addSubview:nothingButton];
            [nothingButton setFrame:CGRectMake(20, 0, screen.size.width-40, screen.size.height-84)];

            return cell;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_contacts.count == 0){
        return screen.size.height-84;
    } else {
        return 80;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 34;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, 34)];
    backgroundToolbar.clipsToBounds = YES;
    backgroundToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UILabel *headerLabel = [[UILabel alloc] init];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
        [headerLabel setTextColor:textColor];
    } else {
        [backgroundToolbar setBarStyle:UIBarStyleDefault];
        [backgroundToolbar setBackgroundColor:[UIColor colorWithWhite:0 alpha:.025]];
        [headerLabel setTextColor:[UIColor blackColor]];
    }
    
    if (IDIOM == IPAD){
        [headerLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:16]];
    } else {
        [headerLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:15]];
    }
    
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    if (!_manageContacts){
        switch (section) {
            case 0:
                [headerLabel setText:@"CIRCLES"];
                break;
            case 1:
                [headerLabel setText:@"CONTACTS"];
                break;

            default:
                [headerLabel setText:@""];
                break;
        }
    } else {
        [headerLabel setText:@"CONTACTS"];
    }
    [backgroundToolbar addSubview:headerLabel];
    [headerLabel setFrame:backgroundToolbar.frame];
    headerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    return backgroundToolbar;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.manageContacts){
        if (indexPath.section == 0){
            Circle *circle= [_circles objectAtIndex:indexPath.row];
            if ([_circleCollaborators containsObject:circle.identifier]){
                [_circleCollaborators removeObject:circle.identifier];
            } else {
                [_circleCollaborators addObject:circle.identifier];
            }
        } else {
            User *contact = [_contacts objectAtIndex:indexPath.row];
            if ([_collaborators containsObject:contact.identifier]){
                [_collaborators removeObject:contact.identifier];
            } else {
                [_collaborators addObject:contact.identifier];
            }
        }
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
    cell.backgroundColor = [UIColor clearColor];
}

- (void)addContact{
    addContactAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Your contact's email:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
    addContactAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [addContactAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == addContactAlert && [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]){
        [self createContact:[addContactAlert textFieldAtIndex:0].text];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove"]){
        [self removeContact];
    }
}

- (void)createContact:(NSString*)email {
    if (email.length){
        [manager POST:[NSString stringWithFormat:@"%@/users/%@/add_contact",kAPIBaseUrl,[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:@{@"email":email} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Successfully created contact: %@",responseObject);
            if ([responseObject objectForKey:@"user"]){
                User *newContact = [User MR_findFirstByAttribute:@"identifier" withValue:[[responseObject objectForKey:@"user"] objectForKey:@"id"]];
                if (!newContact){
                    newContact = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [newContact populateFromDict:[responseObject objectForKey:@"user"]];
                [_contacts insertObject:newContact atIndex:0];
                if (newContact && _contacts.count > 1)[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
                else [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            } else if ([[responseObject objectForKey:@"failure"] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
                [XXAlert show:[NSString stringWithFormat:@"%@ doesn't user Verses yet. We've sent them an invite.",email] withTime:2.7f];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to send this invitation. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to create contact: %@",error.description);
        }];
    }
}

- (void)confirmRemove:(NSIndexPath*)indexPath {
    [[[UIAlertView alloc] initWithTitle:@"Confirmation" message:@"Are you sure you want to remove this contact?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Remove", nil] show];
    indexPathToRemove = indexPath;
}

- (void)removeContact {
    User *removeContact = [_contacts objectAtIndex:indexPathToRemove.row];
    [manager DELETE:[NSString stringWithFormat:@"%@/users/%@/remove_contact",kAPIBaseUrl,removeContact.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"successfully removed contact: %@",responseObject);
        [currentUser removeContact:removeContact];
        [removeContact MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        [_contacts removeObject:removeContact];
        if (_contacts.count){
            [self.tableView deleteRowsAtIndexPaths:@[indexPathToRemove] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self.tableView reloadData];
        }
        indexPathToRemove = nil;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"Failed to remove contact: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to remove this contact. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.manageContacts){
        return YES;
    } else {
        return NO;
    }
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self confirmRemove:indexPath];
        //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (void)dismissView {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!_manageContacts){
        if (_collaborators){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Collaborators" object:nil userInfo:@{@"collaborators":_collaborators}];
        }
        if (_circleCollaborators){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CircleCollaborators" object:nil userInfo:@{@"circleCollaborators":_circleCollaborators}];
        }
    }
}


@end
