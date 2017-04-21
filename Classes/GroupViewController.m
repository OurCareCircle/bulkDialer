//
//  GroupViewController.m
//  bulk
//
//  Created by sanjay krishnamurthy mac mini account on 1/10/13.
//
//

#import "GroupViewController.h"
#import "KeypadViewController.h"

@interface GroupViewController ()

@end

@implementation GroupViewController

@synthesize parent;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)init
{
    // Nothing special to do for groups; override dialedvc behavior
    return self;
}


- (void)viewDidLoad
{
    //need this to setup persistent manager
    //[super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //Add send button to left side iff there is a valid file to be delivered
	UIBarButtonItem *btn_send = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleBordered target:self action:@selector(sendEvent)];
	//Need the nav item on top of the tableview to add buttons
	UINavigationItem       *item = [self navigationItem];
    //check if send btn is needed?
    if (![self isEmpty:currFile]) {
        [item setLeftBarButtonItem:btn_send animated:NO];
    }
    
    //Add an Edit button to right side (just like the Folders view)
	self.navigationItem.rightBarButtonItem = super.editButtonItem;
    
    //take details from v2bdialed obj and init local mutable array of displayed objects
    NSString *name     = [dialed valueForKey:@"name"];
    NSString *number   = [dialed valueForKey:@"number"];
    NSString *country  = [dialed valueForKey:@"country"];
    NSString *contacts = [dialed valueForKey:@"contacts"];
    
    //NOTE: dont use the parent object; you dont want the new v2bdialed objects
    //persisted
    DialedViewController  *dvc = [[DialedViewController alloc] init];
    [dvc viewDidLoad];
    callsArray = [dvc genContactsArray:number contacts:contacts country:country];
}

- (void) sendEvent {
    
    //Get V2bDialed object representing list of contacts
	V2bDialed *event        = (V2bDialed *)dialed;
    
    //dial the selected number
    NSString *name    = [event valueForKey:@"name"];
    NSString *number  = [event valueForKey:@"number"];
    NSString *country = [event valueForKey:@"country"];
    NSString *contacts= [event valueForKey:@"contacts"];
    NSLog(@"Dialing group name %@ number %@ country %@ contacts %@", name, number, country, contacts);
    
    //create a keypad vc and init it to initate a call correctly
    KeypadViewController *kvc = [[KeypadViewController alloc] init];
    [kvc viewWillAppear:false];
    kvc.phoneNumber           = number;
    //set pickerChosen to indicate phoneNumber has already been set
    kvc.pickerChosen          = [[NSNumber alloc] initWithBool:TRUE];
    kvc.firstName             = name;
    kvc.country.chosenCountry = country;
    kvc.groupName             = [name copy];
    kvc.contacts              = contacts;
    kvc.v2bf                  = [self cloneCurrFile:currFile]; //make copy coz we nil it out after send below
    
    //NOTE: dont use the parent object; you dont want the new v2bdialed objects
    //persisted
    DialedViewController  *dvc = [[DialedViewController alloc] init];
    [dvc viewDidLoad];
    //convert contacts string into an array of v2bdialed objects
    kvc.callsArray            = [dvc genContactsArray:number contacts:contacts country:country];
    [dvc release];
    
    //dial outbound call with the params fetched from storage
    [kvc makeCall];
    
    //clear all local state 
    [self popToRoot];
    
}

//make a clone of the currFile obj; so that we can nil out currFile fields before returning
-(v2bFile*) cloneCurrFile:(v2bFile*)currFile {
    
    //NOTE: we use bogus moc below so that this object is not saved
    v2bFile *clone = (v2bFile*)[NSEntityDescription insertNewObjectForEntityForName:@"v2bFile" inManagedObjectContext:parent.managedObjectContext];
    
    [clone setValue:[currFile valueForKey:@"fileURL"] forKey:@"fileURL"];
    [clone setValue:[currFile valueForKey:@"fileName"] forKey:@"fileName"];
    [clone setValue:[currFile valueForKey:@"folderName"] forKey:@"folderName"];
    [clone setValue:[currFile valueForKey:@"fileLength"] forKey:@"fileLength"];
    [clone setValue:[currFile valueForKey:@"emailAddrList"] forKey:@"emailAddrList"];
    [clone setValue:[currFile valueForKey:@"deleted"] forKey:@"deleted"];
    
    return clone;
    
}

//Done with email; pop back to root folder view
- (void)popToRoot {
	UINavigationController *nav = [self navigationController];
	
	//clear local state passed into this view before exiting
	[self clearState];
	
	//Pop all the way back to root; 030311 poptoroot doestn show new folders
	//just pop one level back to files view
	[nav popToRootViewControllerAnimated:NO];
	//[nav popViewControllerAnimated:NO];
    
}

//clear all state vars passed into this view when we are done with bulk send stuff
- (void)clearState {
	[self.v2bf        setValue:nil forKey:@"fileURL"];
    self.dialed       = nil;
    self.v2bf         = nil;
    [self.currFile    setValue:nil forKey:@"fileURL"];
    //self.currFile     = nil;
    parent.currFile   = nil;
}

#pragma mark -
#pragma mark Table view delegate

//When a table row is selected, this toggles between play and pause modes depending on which
//img is currently being displayed
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //Do nothing
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // Remove selected contact from callsArray; then gen update the v2bDialed object and save it
        [callsArray removeObjectAtIndex:indexPath.row];
        // Update the array and table view.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		      
        //need a kvc to gen a new contacts list
        KeypadViewController *kvc = [[KeypadViewController alloc] init];
        [kvc viewWillAppear:false];
        NSString *number   = [kvc concatNumbers:callsArray];
        NSString *contacts = [kvc concatContacts:callsArray];
        
        //update fields of managed object
        [dialed setValue:number   forKey:@"number"];
        [dialed setValue:contacts forKey:@"contacts"];
        
        // Commit the change.
        NSError *error = nil;
        if (![parent.managedObjectContext save:&error]) { //NOTE: only parent dialed vc has moc inited
            // Handle the error.
			NSLog(@"Error deleting call: %@", [error localizedDescription]);
        }
        
        [number release];
        [contacts release];
        [kvc release]; //done with kvc

    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
