//
//  KeypadViewController.m
//  Keypad
//
//  Created by Adrian on 10/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "KeypadViewController.h"
#import "CallerViewController.h"
#import "SoundEffect.h"
#import "FirstViewController.h"
#import "PaymentViewController.h"
#import "KeypadAppDelegate.h"
#import "Reachability.h"
#import "QuartzCore/CAAnimation.h"
#import "ModalViewController.h"
#import "MBProgressHUD.h"
#import "DialedViewController.h"
#import "v2bFile.h"

@implementation KeypadViewController

@synthesize pay, country, picker, parent, mvc, phoneNumber, contacts, firstName, lastName, pickerChosen,
            groupName, defaultGroupName, callsArray, v2bf;

//Incoming call recordings dial this tel#
NSString *REC_INCOMING_CALL = @"tel://18774131547";

#pragma mark -
#pragma mark Constructors and destructors

- (void)viewWillAppear:(BOOL)animated {
    
    //This method is invoked with initial view and when the child country VC pops back to parent
    //So show the chosen country in the country chooser button
    buttonCountry.titleLabel.text = country.chosenCountry;
    
    //display balance in upper right side
    [self displayBalance];
    
}

//check if string is empty
- (BOOL) isEmpty:(id)thing 
{
    return thing == nil
    || [thing isKindOfClass:[NSNull class]]
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}

- (void) displayBalance {
	//fetch and show current calls remaining
	PaymentViewController *pay = [[PaymentViewController alloc] initWithNibName:@"SecondView" bundle:nil];
	//init PaymentViewController before using any of its methods
	[pay viewDidLoad];
    //do this to set the paymentOK flag correctly
    [pay checkFreeCalls];
	
	int64_t qty                 = [pay getBalanceCalls];
	NSString  *prompt           = [NSString stringWithFormat:@"%@%lld", @"Balance:", qty];
    //add as title of button on right side
    [buttonExpiry  setTitle:prompt forState:UIControlStateNormal];
    
    if ([pay.paymentOK boolValue] == false) {
        //expired show red date
        [buttonExpiry setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
    else {
        //unexpired show black date
        [buttonExpiry setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    
	[pay release];
    pay = nil;
} //displayBalance

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    //Gen a new group name if one already hasnt been set by user
    if ([self isEmpty:groupName]) {
        groupName = [defaultGroupName copy];
    }
    
    //init callsArray if its empty
    if ([self isEmpty:callsArray]) {
        callsArray = [[NSMutableArray alloc] init];
    }
}

- (id)init
{
    if (self = [super initWithNibName:@"Keypad" bundle:nil]) 
    {
        self.title = @"Keypad";
        self.tabBarItem.image = [UIImage imageNamed:@"tab-keypad.png"];
        numberLabel.text = @"";
        NSBundle *mainBundle = [NSBundle mainBundle];
        tone0 = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"0" ofType:@"wav"]];
        tone1 = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"1" ofType:@"wav"]];
        tone2 = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"2" ofType:@"wav"]];
        tone3 = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"3" ofType:@"wav"]];
        tone4 = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"4" ofType:@"wav"]];
        tone5 = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"5" ofType:@"wav"]];
        tone6 = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"6" ofType:@"wav"]];
        tone7 = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"7" ofType:@"wav"]];
        tone8 = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"8" ofType:@"wav"]];
        tone9 = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"9" ofType:@"wav"]];
        toneStar = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"star" ofType:@"wav"]];
        toneNumeral = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"numeral" ofType:@"wav"]];
    }
    
    //Do one time inits of children VCs
    //Use global variable called pay because we need to access it from viewWillAppear
	//which is invoked when the payment view is done processing
	pay = [[PaymentViewController alloc] initWithNibName:@"SecondView" bundle:nil];
	//init PaymentViewController before using any of its methods
	[pay viewDidLoad];
    
    //Use global variable called country because we need to access it from viewWillAppear
	//which is invoked when the countryvc is done processing
	country = [[CountryViewController alloc] initWithNibName:nil bundle:nil];
    //call one time init to set default country chosen
    [country init];
    
    //Use global variable called picker for contacts picker
    picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.navigationBar.barStyle = UIBarStyleDefault;
    picker.title = @"Contacts";
    picker.tabBarItem.image = [UIImage imageNamed:@"tab-contacts.png"];
    picker.peoplePickerDelegate = self;
    picker.navigationBarHidden = NO;  //do display cancel button for contacts
    //mark contacts picker as NOT chosen by default
    pickerChosen = [[NSNumber alloc] initWithBool:FALSE];
    
    //set local booleans for buttons false
    callRecordNeeded     = FALSE;
    stvNeeded            = FALSE;
    cancelFlag           = FALSE;
    incomingRecordNeeded = FALSE;
    
    //init modal view dialog to gather further input from user
    mvc = [[ModalViewController alloc] initWithNibName:nil bundle:nil];
    [[NSBundle mainBundle] loadNibNamed:@"ModalDialog" owner:mvc options:nil];
    //call this method to init local vars
    [mvc viewDidLoad];
    
    //init vars used to communicate with mvc
    //Gen a new group name if one already hasnt been set by user
    defaultGroupName = @"2013-01-01";
    groupName  = [[mvc genUniqueGroupname] copy]; //always use a group name with timestamp in it
    callsArray = [[NSMutableArray alloc] init];
    
    return self;
}

- (void)dealloc 
{
    [tone0 release];
    [tone1 release];
    [tone2 release];
    [tone3 release];
    [tone4 release];
    [tone5 release];
    [tone6 release];
    [tone7 release];
    [tone8 release];
    [tone9 release];
    [toneStar release];
    [toneNumeral release];
    [pay release];
    [country release];
    [picker release];
    [v2bf release];
    [super dealloc];
}

#pragma mark -
#pragma mark IBAction methods

- (IBAction)typeNumberOrSymbol:(id)sender
{
    //clear out balance before first digit typed
    NSString *num = numberLabel.text;
    if ([num hasPrefix:@"Balance"]) {
            numberLabel.text = @"";
    }
    
    NSString *symbol = @"";
    if (sender == button0)
    {
        [tone0 play];
        symbol = @"0";
    }
    else if (sender == button1)
    {
        [tone1 play];
        symbol = @"1";
    }
    else if (sender == button2)
    {
        [tone2 play];
        symbol = @"2";
    }
    else if (sender == button3)
    {
        [tone3 play];
        symbol = @"3";
    }
    else if (sender == button4)
    {
        [tone4 play];
        symbol = @"4";
    }
    else if (sender == button5)
    {
        [tone5 play];
        symbol = @"5";
    }
    else if (sender == button6)
    {
        [tone6 play];
        symbol = @"6";
    }
    else if (sender == button7)
    {
        [tone7 play];
        symbol = @"7";
    }
    else if (sender == button8)
    {
        [tone8 play];
        symbol = @"8";
    }
    else if (sender == button9)
    {
        [tone9 play];
        symbol = @"9";
    }
    else if (sender == buttonStar)
    {
        [toneStar play];
        symbol = @"*";
    }
    else if (sender == buttonNumeral)
    {
        [toneNumeral play];
        symbol = @"#";
    }
    numberLabel.text = [numberLabel.text stringByAppendingString:symbol];
}

- (IBAction)goBack:(id)sender
{
    NSString *currentValue = numberLabel.text;
    NSUInteger currentLength = [currentValue length];
    if (currentLength > 0)
    {
        NSRange range = NSMakeRange(0, currentLength - 1);
        numberLabel.text = [numberLabel.text substringWithRange:range];
    }
}

//wired to contacts picker now
-(IBAction)gotoWeb:(id)sender
{
    //store parent nav controller before switching to contacts nav controller
    //get the tabbarcontroller inside the app delegate
    KeypadAppDelegate *appDelegate       = (KeypadAppDelegate *)[[UIApplication sharedApplication] delegate];
    UITabBarController *tabBarController = [appDelegate tabBarController];
    parent = [[tabBarController viewControllers] objectAtIndex:0];
	[self presentModalViewController:picker animated:YES];
}

//take user to call rec pro app
-(IBAction)gotoWeb2:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"itms-apps://itunes.apple.com/app/id439516456"]];
}

#pragma mark -
#pragma mark ABPeoplePickerNavigationControllerDelegate methods

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)picker 
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)picker 
      shouldContinueAfterSelectingPerson:(ABRecordRef)person 
                                property:(ABPropertyID)property 
                              identifier:(ABMultiValueIdentifier)identifier
{
    if (property == kABPersonPhoneProperty)
    {
        //Mark flag indicating a contact was chosen
        pickerChosen = [[NSNumber alloc] initWithBool:TRUE];
        
        /* Dont dial out yet; just set user's first+last name in calling area
        NSString *phoneNumber = retrieveValueForPropertyAtIndex(person, property, identifier);
        CallerViewController *caller = [[CallerViewController alloc] init];
        caller.shouldShowNavControllerOnExit = YES;
        caller.phoneNumber = phoneNumber;
        
        //Init firstvc to dialout
        FirstViewController *first = [[FirstViewController alloc] init];
        [first viewDidLoad];
        //store in caller view so that you can call out
        caller.first = first;
        
        //Add first and last name
        caller.firstName = (NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        caller.lastName  = (NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty); 
        [picker pushViewController:caller animated:YES]; */
        
        phoneNumber = retrieveValueForPropertyAtIndex(person, property, identifier);
        firstName = (NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        lastName  = (NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty); 
        
        //set dialing area to show contact's name or dialed tel#
        NSString  *prompt           = @"Contact";
        if (![self isEmpty:firstName] && ![self isEmpty:lastName]) {
            prompt = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        }
        else if (![self isEmpty:firstName]) {
            prompt = firstName;
        }
        else if (![self isEmpty:lastName]){
            prompt = lastName;
        }
        else {
            prompt = phoneNumber;
        }
        numberLabel.text            = prompt;  
        
        //Done with modal view for contacts
        //Dismiss the contacts picker else you will get exception if presented again
        [self dismissModalViewControllerAnimated:YES];
        
        //place call with contact details
        [self call:nil]; //no sender attached
        
        return NO;
    }
    return YES;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)picker
{
    //get the tabbarcontroller inside the app delegate
    KeypadAppDelegate *appDelegate       = (KeypadAppDelegate *)[[UIApplication sharedApplication] delegate];
    UITabBarController *tabBarController = [appDelegate tabBarController];
    
    //Dismiss the contacts picker else you will get exception if presented again
    [self dismissModalViewControllerAnimated:YES];
    
	//012912 force keypad view to be displayed
    //pop back to parent view; 		
    [[[UIApplication sharedApplication] keyWindow] addSubview:tabBarController.view];
}

- (IBAction)call:(id)sender
{
    //set phoneNumber to user entry iff user did NOT use contact picker; contact picker sets phoneNumber before
    //caling this method. Note that when control comes here from Dialedvc, pickerChosen is false.
    //The phoneNumber is already set correctly.
    if (pickerChosen.boolValue == false) {
        phoneNumber = [[NSString alloc] initWithString:numberLabel.text]; //need to retain to keep it past modal vc
    }
    
    //if no number selected, show alert
    if ([self isEmpty:phoneNumber]) {
        [self showAlert2];
    }
    else {
        
        //init modal view dialog to gather further input from user
        mvc = [[ModalViewController alloc] initWithNibName:nil bundle:nil];
        [[NSBundle mainBundle] loadNibNamed:@"ModalDialog" owner:mvc options:nil];
        //call this method to init local vars
        [mvc viewDidLoad];
        
        //xfer dialed country,groupName and callsArray to modalvc
        mvc.country        = country.chosenCountry;
        mvc.groupName.text = [groupName copy];
        mvc.callsArray     = callsArray;
        
        //Connect buttons in modal dialog to this vc methods
        [mvc.stvButton addTarget:self 
                       action:@selector(stvButtonPressed:)
             forControlEvents:UIControlEventTouchDown];
        [mvc.contButton addTarget:self 
                          action:@selector(contButtonPressed:)
                forControlEvents:UIControlEventTouchDown];
        [mvc.callRecordButton addTarget:self 
                          action:@selector(callRecButtonPressed:)
                forControlEvents:UIControlEventTouchDown];
        [mvc.cancelButton addTarget:self 
                                 action:@selector(cancelButtonPressed:)
                       forControlEvents:UIControlEventTouchDown];
        [mvc.incomingRecordButton addTarget:self 
                                 action:@selector(incomingRecordButtonPressed:)
                       forControlEvents:UIControlEventTouchDown];
        
        //Save current dialed number in current group
        [mvc saveCall:self.firstName last:self.lastName phoneNumber:self.phoneNumber
              country:self.country.chosenCountry];
        //zero out label where dialed number is displayed
        numberLabel.text = @"";
        
        //show modal dialog now
        [self showModal:mvc.view];
       // [self presentModalViewController:mvc animated:YES];
        
        //let button actions drive the next step
    }
}

//dialing by contacts and dialing by keypad both end up here
-(void)makeCall {
    //check web access; if unavailable, discontinue
    [self checkWiFi];
    //code will continue after wifi check is done in restOfCall
}

-(void)restOfCall 
{
    // Initiates a network connection to the backend server,
    // which in turn calls the current device back!
    CallerViewController *caller = [[CallerViewController alloc] init];
    caller.shouldShowNavControllerOnExit = NO;
    caller.phoneNumber = [phoneNumber copy];
    caller.contacts    = [contacts copy];
    //first and last name fields are empty
    caller.firstName   = [firstName copy];
    caller.lastName    = [lastName copy];
    //transfer country name from country picker vc
    caller.country     = [country.chosenCountry copy];
    //dialer app is not connected with nib; so set its label field to this view's label field
    caller.numberLabel = numberLabel;
    caller.v2bf        = v2bf;
    //transfer flags for stv and call rec too
    if (callRecordNeeded) {
        caller.callRecordNeeded = [[NSNumber alloc] initWithBool:TRUE];
    }
    else {
        caller.callRecordNeeded = [[NSNumber alloc] initWithBool:FALSE];
    }
    if (stvNeeded) {
        caller.stvNeeded        = [[NSNumber alloc] initWithBool:TRUE];
    }
    else {
        caller.stvNeeded        = [[NSNumber alloc] initWithBool:FALSE];
    }
    
    //before you dial, check both tel#s
    FirstViewController *first = [[FirstViewController alloc] init];
    [first viewDidLoad];
    //store in caller view so that you can call out
    caller.first = first;
    
    //set ccode in firstvc
    NSString *ccode      = [self convertToCcode:caller.country];
    first.toCcode        = [ccode copy];
    [ccode release];
    
    
    if ([first isEmpty:(NSString *)first.telNum.text] || [first isEmpty:(NSString *)first.defaultEmail.text]) {
        [self showAlert1];
    }
    //check if dialed number is empty or has Balance in it instead of a real number
    else  if ([first isEmpty:caller.phoneNumber] || [caller.phoneNumber hasPrefix:@"Balance"]) {
        [self showAlert2];
    }
    else {
        //everything is kosher...go ahead and call out iff balance is greater than zero
        //[self.navigationController pushViewController:caller animated:YES];
        [caller viewWillAppear:true];
        
        //clear state after call
        [self clearState];
    }
}

//clear all local state variables that need to be inited prior to the next call
-(void)clearState {
    pickerChosen         = [[NSNumber alloc] initWithBool:FALSE];    
    callRecordNeeded     = FALSE;
    stvNeeded            = FALSE;
    cancelFlag           = FALSE;
    incomingRecordNeeded = FALSE;
    //empty contacts before next call
    firstName            = @"";
    lastName             = @"";
    phoneNumber          = @"";
    contacts             = @"";
    self.callsArray       = [[NSMutableArray alloc] init];
    self.groupName        = [[mvc genUniqueGroupname] copy];  //always gen a group name with timestamp in it
    self.v2bf             = nil;
    
    //clear state inside modal vc too
    [mvc clearState];
}

//clear all local state variables that need to be inited prior to the next number being entered
-(void)clearStateBetweenEntries {
    //empty contacts before next number entry
    firstName            = @"";
    lastName             = @"";
    pickerChosen         = [[NSNumber alloc] initWithBool:FALSE]; 
    
    //clear state inside modal vc too
    [mvc clearState];
}

-(void)checkWiFi {
	//add activity indicator with appropriate message
	NSString *prompt = [NSString stringWithFormat:@"%@", @"Checking Internet Connectivity.."];	
	//[self addActivityIndicator:prompt];
	
	// check for internet connection	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:)  name:kReachabilityChangedNotification object:nil];	
    internetReachable = [[Reachability reachabilityForInternetConnection] retain];         	
    [internetReachable startNotifier];      
	
	// check if a pathway to a random host exists        	
    hostReachable = [[Reachability reachabilityWithHostName: @"www.apple.com"]  retain];
	[hostReachable startNotifier];         
	
    // now patiently wait for the notification 
} //checkWiFi

- (void) checkNetworkStatus:(NSNotification *)notice     {      
	wifi = FALSE; //use global var to indicate if web is accessible
	
	//remove all notification observers asap
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	//remove activity indicator too
	//[self removeActivityIndicator];
	
    // called after network status changes      	
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    switch (internetStatus){
        case NotReachable:
		{
			NSLog(@"The internet is down.");
			wifi = FALSE;
			break;
		}
		case ReachableViaWiFi:
		{
			NSLog(@"The internet is working via WIFI.");
			wifi = TRUE;
			break;
		}
		case ReachableViaWWAN:
		{
			NSLog(@"The internet is working via WWAN.");
			wifi = TRUE;
			break;
		}
	}
	
	//if on wifi, just continue with recording; else display alert and continue
	if (!wifi) {
		NSString *message  = [NSString stringWithFormat:@"%@", @"You do not have internet access; Cannot send web request to server"];
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle: @"Web Check"
							  message: message
							  delegate:self
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil,
							  nil];
		[alert show];
		[alert release];	
	}
    else {
        //continue with call
        [self restOfCall];
    }
} //checkNetworkStatus

//Show a custom view when GET ops are being done
- (void)addActivityIndicator:(NSString *)prompt
{
    myIndicator                  = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    myIndicator.labelText        = prompt;
    
    //add myIndicator to current view
    KeypadAppDelegate* myDelegate = (((KeypadAppDelegate*) [UIApplication sharedApplication].delegate));
    //doesnt work [self.view addSubview:myIndicator];
    [myDelegate.window addSubview:myIndicator];
    
    //remove after 5 secs
    [NSTimer scheduledTimerWithTimeInterval:5 target:self
                                   selector:@selector(removeActivityIndicator) userInfo:nil repeats:NO];
} //addActivityIndicator

- (void) removeActivityIndicator {
	[myIndicator removeFromSuperview];
} //removeActivityIndicator

//Add an alert when user has not entered a tel# in the settings tab
- (void)showAlert1
{
	//show an alert to the user with data transmission details
	NSString *message  = [NSString stringWithFormat:@"%@", @"Enter your tel# & email in the Settings tab and press Save"];
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle: @"Your tel#??"
						  message: message
						  delegate:self
						  cancelButtonTitle:@"OK"
						  otherButtonTitles:nil,
						  nil];
	[alert show];
	[alert release];
} //showAlert1

//Add an alert when user dialed number is empty
- (void)showAlert2
{
	//show an alert to the user with data transmission details
	NSString *message  = [NSString stringWithFormat:@"%@", @"Dialed number is empty.."];
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle: @"Dialed tel#??"
						  message: message
						  delegate:self
						  cancelButtonTitle:@"OK"
						  otherButtonTitles:nil,
						  nil];
	[alert show];
	[alert release];
} //showAlert2

//delegate for the sole alert view in this viewcontroller
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"user pressed OK");
    }
    else {
        NSLog(@"user pressed Cancel");
    }
} //alertView

//
// creditButtonPressed:
//
// Handles the extend credit button press action
//
// Parameters:
//    sender - normally, the save button.
//
- (IBAction)creditButtonPressed:(id)sender
{
	
    //before transitioning to payment viewcontroller, set default email address used as key to check
    //active subscriptions
    //Make sure all params to record op are non-empty
    FirstViewController *first = [[FirstViewController alloc] init];
    [first viewDidLoad];
    
    //ensure saved email and tel# are non-nil before use below
    if ([first isEmpty:(NSString *)first.telNum.text] || [first isEmpty:(NSString *)first.defaultEmail.text]) {
        [self showAlert1];
        return; //no more processing
    }
    
    //dont really need this with alert above
    NSString *defEmail         = first.defaultEmail.text;
    if ([first isEmpty:defEmail]) {
        defEmail = @"::";
    }
    NSString *telNum           = first.telNum.text;
    if ([first isEmpty:telNum]) {
        telNum = @"::";
    }
    
    //sanitize all params by  replacing all spaces with at chars
    defEmail     = [defEmail  stringByReplacingOccurrencesOfString:@" " withString:@"@"];
    //set inside payment vc
    pay.defEmail = defEmail;
    pay.telNum   = telNum;
    pay.ccode    = first.ccode; //add country code for validate payment webservice
    [defEmail release];
    [telNum   release];
    [first    release];
		
    //invoke payment vc
    UINavigationController *nav = [self navigationController];
    //default free calls exhausted; send user to pick payment method
    [nav pushViewController:pay animated:true];

}

//pick the list of countries from FirstVC
extern NSString *countries[];
extern NSString *ccodes[];

//
// countryButtonPressed:
//
// Handles the country chooser button press action
//
// Parameters:
//    sender - normally, the save button.
//
- (IBAction)countryButtonPressed:(id)sender
{
	
    //before transitioning to countryVC, set the list content
    NSArray               *nms = [self buildNameArray];
    [country setListContent:nms];
    
    //invoke country vc
    UINavigationController *nav = [self navigationController];
    //default free calls exhausted; send user to pick payment method
    [nav pushViewController:country animated:true];
    
}

//Convert NSString * into NSArray
- (NSArray *)buildNameArray{
	int count =[FirstViewController sizeofCountries];
	NSArray *names_array = [[NSArray alloc] initWithObjects:countries count:count];
    return names_array;
}

//convert chosen country name inside countryvc into a country code
- (NSString *)convertToCcode:(NSString *)countryName {
	int       count =[FirstViewController sizeofCountries];
	NSString *ccode = @"1";
    
    //walk thru countries array looking for match
    for (int rownum = 0; rownum < (int)(count); rownum++) {
        if ([countries[rownum] compare:countryName] == NSOrderedSame) {
            ccode = ccodes[rownum];
            break;
        }
    }
    
    return ccode;
}

// Use this to show the modal view (pops-up from the bottom)
- (void) showModal:(UIView*) modalView {   
    
    UIWindow* mainWindow = [[UIApplication sharedApplication] keyWindow];
    CGPoint middleCenter = modalView.center; 
    CGSize offSize = [UIScreen mainScreen].bounds.size;  
    CGPoint offScreenCenter = CGPointMake(offSize.width / 2.0, offSize.height * 1.5);   
    modalView.center = offScreenCenter; 
    // we start off-screen   
    [mainWindow addSubview:modalView];  
    // Show it with a transition effect     
    [UIView beginAnimations:nil context:nil];  
    [UIView setAnimationDuration:0.7];
    // animation duration in seconds  
    modalView.center = middleCenter;
    [UIView commitAnimations]; 
    
}

// Use this to slide the semi-modal view back down. 
- (void) hideModal:(UIView*) modalView {   
    
    CGSize offSize = [UIScreen mainScreen].bounds.size;  
    CGPoint offScreenCenter = CGPointMake(offSize.width / 2.0, offSize.height * 1.5);  
    [UIView beginAnimations:nil context:modalView];   
    [UIView setAnimationDuration:0.7];  
    [UIView setAnimationDelegate:self]; 
    [UIView setAnimationDidStopSelector:@selector(hideModalEnded:finished:context:)]; 
    modalView.center = offScreenCenter;  
    [UIView commitAnimations]; 

}  

//callback for end of animation
- (void) hideModalEnded:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {  
    UIView* modalView = (UIView *)context;
    [modalView removeFromSuperview]; 
} 

//call rec button pressed action; set local boolean
- (IBAction)callRecButtonPressed:(id)sender
{
    callRecordNeeded = TRUE;
    //dismiss modal dialog
    [self hideModal:mvc.view];
    
    //xfer params from mvc to this vc
    [self xferFromMVC:mvc];
    
    //clear state between entries
    [self clearStateBetweenEntries];
}

//stv button pressed action; set local boolean
- (IBAction)stvButtonPressed:(id)sender
{
    stvNeeded = TRUE;
    //dismiss modal dialog
    [self hideModal:mvc.view];
    //[super dismissModalViewControllerAnimated:true];
    
    //place call with contact details
    [self makeCall];
}

//continue button pressed action; set local boolean
- (IBAction)contButtonPressed:(id)sender
{
    //dismiss modal view and continue
    [self hideModal:mvc.view];
    
    //xfer params from mvc to this vc
    [self xferFromMVC:mvc];
    
    //Add group name as dialed name; concat all the tel#s in group and pass on as dialed tel#
    self.firstName   = [self.groupName copy]; //pass group name in as dialed name
    self.lastName    = @"";
    self.phoneNumber = [[self concatNumbers:callsArray] copy];
    self.contacts    = [[self concatContacts:callsArray] copy];
    
    //place call with contact details
    [self makeCall];
}

//copy params from mvc to local vars
-(void) xferFromMVC:(ModalViewController*)mvc {
    //xfer params from mvc to this vc
    groupName  = [mvc.groupName.text copy];
    callsArray = mvc.callsArray;
}

//take all the phone numbers in the array of V2bDialed objects and concatenate them into a string
-(NSString *)concatNumbers:(NSMutableArray *)arr {
    NSString *result = @"";
    
    for (id item in arr) {
        V2bDialed *dialed = (V2bDialed *)item;
        if (![self isEmpty:dialed.number]) {
            if (![self isEmpty:result]) {
                //add comma iff this isnt the first entry in result
                result = [result stringByAppendingString:@","];
            }
            result = [result stringByAppendingString:dialed.number];
        }
    } //for loop
    
    return result;
}

//take all the contacts in the array of V2bDialed objects and concatenate them into a string
-(NSString *)concatContacts:(NSMutableArray *)arr {
    NSString *result = @"";
    
    for (id item in arr) {
        V2bDialed *dialed = (V2bDialed *)item;
        
        //Add name into contacts list if present; else add number
        if (![self isEmpty:dialed.name]) {
            if (![self isEmpty:result]) {
                //add comma iff this isnt the first entry in result
                result = [result stringByAppendingString:@","];
            }
            result = [result stringByAppendingString:dialed.name];
        }
        else if (![self isEmpty:dialed.number]) {
            if (![self isEmpty:result]) {
                //add comma iff this isnt the first entry in result
                result = [result stringByAppendingString:@","];
            }
            result = [result stringByAppendingString:dialed.number];
        }
    } //for loop
    
    return result;
}

//user pressed cancel buton; do nothing
- (IBAction)cancelButtonPressed:(id)sender
{
    //dismiss modal view and continue
    [self hideModal:mvc.view];
    //[super dismissModalViewControllerAnimated:true];

}

//use this popup to display sensible messages to the user
MBProgressHUD *spinner;

//user wants to record ongoing call
- (IBAction)incomingRecordButtonPressed:(id)sender
{
    //dismiss modal view and continue
    [self hideModal:mvc.view];
    //[super dismissModalViewControllerAnimated:true];
        
    //Add a spinner to current view     
    spinner = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    spinner.labelText = @"Press the Merge button";
    spinner.detailsLabelText = @"This merges your call and the recorder";
    
    //add spinner to current view
    KeypadAppDelegate* myDelegate = (((KeypadAppDelegate*) [UIApplication sharedApplication].delegate));
    //doesnt work [self.view addSubview:spinner];
    [myDelegate.window addSubview:spinner];
    
    //remove after 10 secs
    [NSTimer scheduledTimerWithTimeInterval:10 target:self
                                   selector:@selector(dismissSpinner) userInfo:nil repeats:NO];
    
    //place call to start recording
    [[UIApplication sharedApplication] openURL:[NSURL  URLWithString:REC_INCOMING_CALL]];

}

//dismiss annoying activity indicator
-(void)dismissSpinner{
	// Dismiss your view    
    [spinner removeFromSuperview];
    
    //you get msg sent to dealloced instance if you remove spinner like this 
    //[MBProgressHUD hideHUDForView:self.view animated:YES];
    
    //[spinner release];
	
	//pop back after done
	//[[self navigationController] popViewControllerAnimated:NO];
}

#pragma mark -
#pragma mark Private methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return NO;
}

@end
