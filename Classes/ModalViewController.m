//
//  ModalViewController.m
//  Dialer
//
//  Created by sanjay krishnamurthy on 7/12/12.
//  Copyright (c) 2012 Infinear Inc. All rights reserved.
//

#import "ModalViewController.h"
#import "DialedViewController.h"

@interface ModalViewController ()

@end

@implementation ModalViewController

@synthesize stvButton, callRecordButton, contButton, cancelButton, incomingRecordButton, callingCountry,
            country, groupName, defaultGrpName, callsArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        defaultGrpName = @"2013-01-01";
    }
    return self;
}

//check if object (string or array) is empty
- (BOOL) isEmpty:(id)thing
{
    return thing == nil
    || [thing isKindOfClass:[NSNull class]]
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}

//save  call with inputs first name,last name, phone#, ccode
- (void)saveCall:(NSString *)first last:(NSString *)last phoneNumber:(NSString *)phoneNumber
         country:(NSString *)country {
    
	NSLog(@"In Modal view saving call first %@ last %@ url tel %@ country %@", first, last, phoneNumber, country);
    NSString *name = @"";
    if (![self isEmpty:first] && ![self isEmpty:last]) {
        name = [NSString stringWithFormat:@"%@ %@", first, last];
    }
    else if (![self isEmpty:first]) {
        name = first;
    }
    else if (![self isEmpty:last]) {
        name = last;
    }
           
    //Add current file name to top of table view
    //create a V2bDialed obj
    DialedViewController *dvc = [[DialedViewController alloc] init];
    [dvc viewDidLoad];
    V2bDialed  *event         = [dvc createDialedObj];
    [dvc release];

	[event setName:name];
    [event setNumber:phoneNumber];
    [event setCountry:country];
    [event setDialedTime:[NSDate date]]; //todays date
    [callsArray insertObject:event atIndex:0];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    //Gen a new group name if one already hasnt been set by user
    if ([self isEmpty:groupName.text] || [groupName.text compare:defaultGrpName] == NSOrderedSame) {
        groupName.text = [self genUniqueGroupname];
    }
    
    //init callsArray if its empty
    if ([self isEmpty:callsArray]) {
        callsArray = [[NSMutableArray alloc] init];
    }
    
    //Add done button to text field
    [groupName setReturnKeyType: UIReturnKeyDone];
    [groupName setDelegate:self];
    [groupName addTarget:self
                       action:@selector(textFieldShouldReturn:)
             forControlEvents:UIControlEventEditingDidEndOnExit];
}

-(NSString*)genUniqueGroupname {
    //Gen a unique groupname for this group of contacts
    NSString *grpName = @"";
    NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"yyyy-MM-dd-HH-MM-SS"];
    NSDate* date       = [NSDate date];
    NSString* str      = [formatter stringFromDate:date];
    grpName            = [grpName stringByAppendingString:str];

    return grpName;
}

//clear all state vars passed into this view when we are done
- (void)clearState {
	self.callsArray       = [[NSMutableArray alloc] init];
    self.groupName.text   = defaultGrpName;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [callsArray count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ModalCell1";
	
    // Dequeue or create a new cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        //cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
        //reuseIdentifier:CellIdentifier] autorelease];
        //use this cell type to add a label on right side
        cell = [[[UITableViewCell alloc]  initWithStyle:UITableViewCellStyleSubtitle
                                        reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
	
    V2bDialed  *event           = (V2bDialed *)[callsArray objectAtIndex:indexPath.row];
	
	//Set main area of cell to be name and subtext to be dialed number. If name is null, dialed number
    //moves to the main area
    NSString *name    = [event valueForKey:@"name"];
    NSString *number  = [event valueForKey:@"number"];
    NSString *country = [event valueForKey:@"country"];
    if ([self isEmpty:name]) {
        name = number;
        number = @"";
    }
    
    cell.textLabel.text       = name;
    cell.detailTextLabel.text = number;
    
    //add country as accessory view
    CGRect frame             = CGRectMake(180.0, 10.0, 100, 25);
    UILabel *newLabel        = [[[UILabel alloc] initWithFrame:frame] autorelease];
    newLabel.text            = country;
    newLabel.backgroundColor = [UIColor colorWithRed:0.773f green:0.80f blue:0.831f alpha:1.0f];
    cell.accessoryView = newLabel;
	
	NSLog(@"Displaying cell with name %@ number %@ country %@", name, number, country);
	
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (void)viewWillAppear:(BOOL)animated
{
    //Change text field showing which country is being called
    NSString *text      = [NSString stringWithFormat:@"Calling %@...", country];
    callingCountry.text = text;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//Dismiss keyboard when done button pressed
-(BOOL)textFieldShouldReturn:(UITextField *)Done {
	[Done resignFirstResponder];
	return YES;
}

@end
