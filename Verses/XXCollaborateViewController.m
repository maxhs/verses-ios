//
//  XXCollaborateViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/31/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXCollaborateViewController.h"
#import "XXContactCell.h"
#import "XXCircle.h"

@interface XXCollaborateViewController () {
    AFHTTPRequestOperationManager *manager;
    NSMutableArray *_contacts;
    NSMutableArray *_circles;
    BOOL loading;
    CGRect screen;
    NSIndexPath *indexPathToRemove;
    UIBarButtonItem *cancelButton;
    UIAlertView *addContactAlert;
    UIColor *textColor;
    UIImageView *navBarShadowView;
}

@end

@implementation XXCollaborateViewController
@synthesize collaborators = _collaborators;
@synthesize circleCollaborators = _circleCollaborators;

- (void)viewDidLoad
{
    [super viewDidLoad];
    screen = [UIScreen mainScreen].bounds;
    manager = [AFHTTPRequestOperationManager manager];
    [self loadContacts];
    if (self.modal){
        cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"blackX"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissView)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        self.title = @"Contacts";
    }
    if (!_collaborators) _collaborators = [NSMutableArray array];
    if (!_circleCollaborators) _circleCollaborators = [NSMutableArray array];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:0 alpha:.05]];
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.modal) [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] registerTouchForwardingClass:[XXContactCell class]];
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
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/users/%@/contacts",kAPIBaseUrl,[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting user's contacts: %@",responseObject);
        _contacts = [[Utilities usersFromJSONArray:[responseObject objectForKey:@"users"]] mutableCopy];
        [self loadCircles];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self loadCircles];
        NSLog(@"error getting user's contacts: %@",error.description);
    }];
}

- (void)loadCircles {
    [manager GET:[NSString stringWithFormat:@"%@/circles",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting circles: %@",responseObject);
        _circles = [[Utilities circlesFromJSONArray:[responseObject objectForKey:@"circles"]] mutableCopy];
        loading = NO;
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        loading = NO;
        NSLog(@"error getting user's circles: %@",error.description);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (loading){
        return 0;
    } else {
        if (self.modal){
            return 2;
        } else {
            return 1;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0 && self.modal){
        if (_circles.count == 0 && !loading){
            return 1;
        } else {
            return _circles.count;
        }
    } else {
        if (_contacts.count == 0 && !loading){
            return 1;
        } else {
            return _contacts.count;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && self.modal){
        if (_contacts.count){
            XXContactCell *cell = (XXContactCell *)[tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXContactCell" owner:nil options:nil] lastObject];
            }
            XXCircle *circle = [_circles objectAtIndex:indexPath.row];
            [cell configureCircle:circle];
            [cell.locationLabel setTextColor:textColor];
            [cell.nameLabel setTextColor:textColor];
            if (_circleCollaborators && [_circleCollaborators containsObject:circle.identifier]){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
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
            [nothingButton setFrame:CGRectMake(20, 0, screen.size.width-40, screen.size.height-64)];
            cell.backgroundView = [[UIView alloc] initWithFrame:cell.frame];
            [cell.backgroundView setBackgroundColor:[UIColor clearColor]];
            [self.tableView setScrollEnabled:NO];
            return cell;
        }
    } else {
        if (_contacts.count){
            XXContactCell *cell = (XXContactCell *)[tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXContactCell" owner:nil options:nil] lastObject];
            }
            XXUser *contact = [_contacts objectAtIndex:indexPath.row];
            [cell configureContact:contact];
            [cell.locationLabel setTextColor:textColor];
            [cell.nameLabel setTextColor:textColor];
            if (_collaborators && [_collaborators containsObject:contact.identifier]){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            return cell;
        } else {
            static NSString *CellIdentifier = @"NothingCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            UIButton *nothingButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [nothingButton setTitle:@"You don't have any writing contacts yet." forState:UIControlStateNormal];
            [nothingButton.titleLabel setNumberOfLines:0];
            [nothingButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:20]];
            [nothingButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            nothingButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            [nothingButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [nothingButton setBackgroundColor:[UIColor clearColor]];
            [cell addSubview:nothingButton];
            [nothingButton setFrame:CGRectMake(20, 0, screen.size.width-40, screen.size.height-64)];
            cell.backgroundView = [[UIView alloc] initWithFrame:cell.frame];
            [cell.backgroundView setBackgroundColor:[UIColor clearColor]];
            [self.tableView setScrollEnabled:NO];
            return cell;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_contacts.count == 0 && !loading){
        return screen.size.height-64;
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
        [headerLabel setTextColor:[UIColor darkGrayColor]];
    }
    
    if (IDIOM == IPAD){
        [headerLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:16]];
    } else {
        [headerLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:15]];
    }
    
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
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
    [backgroundToolbar addSubview:headerLabel];
    [headerLabel setFrame:backgroundToolbar.frame];
    headerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    return backgroundToolbar;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.modal){
        if (indexPath.section == 0){
            XXCircle *circle= [_circles objectAtIndex:indexPath.row];
            if ([_circleCollaborators containsObject:circle.identifier]){
                [_circleCollaborators removeObject:circle.identifier];
            } else {
                [_circleCollaborators addObject:circle.identifier];
            }
        } else {
            XXUser *contact = [_contacts objectAtIndex:indexPath.row];
            if ([_collaborators containsObject:contact.identifier]){
                [_collaborators removeObject:contact.identifier];
            } else {
                [_collaborators addObject:contact.identifier];
            }
        }
        [self.tableView reloadData];
    } else {
        
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

- (IBAction)addContact{
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
            NSLog(@"Successfully created contact: %@",responseObject);
            if ([responseObject objectForKey:@"user"]){
                XXUser *newContact = [[XXUser alloc] initWithDictionary:[responseObject objectForKey:@"user"]];
                [_contacts insertObject:newContact atIndex:0];
                if (newContact)[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
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
    XXUser *removeContact = [_contacts objectAtIndex:indexPathToRemove.row];
    [manager DELETE:[NSString stringWithFormat:@"%@/users/%@/remove_contact",kAPIBaseUrl,removeContact.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"successfully removed contact: %@",responseObject);
        [_contacts removeObject:removeContact];
        [self.tableView deleteRowsAtIndexPaths:@[indexPathToRemove] withRowAnimation:UITableViewRowAnimationFade];
        indexPathToRemove = nil;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"Failed to remove contact: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to remove this contact. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.modal){
        return NO;
    } else {
        return YES;
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Collaborators" object:nil userInfo:@{@"collaborators":_collaborators}];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CircleCollaborators" object:nil userInfo:@{@"circleCollaborators":_circleCollaborators}];
}

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
