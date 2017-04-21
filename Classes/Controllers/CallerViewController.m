//
//  CallerViewController.m
//  Keypad
//
//  Created by Adrian on 10/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CallerViewController.h"
#import "SoundEffect.h"
#import "FirstViewController.h"
#import "DialedViewController.h"
#import "KeypadAppDelegate.h"
#import "MBProgressHUD.h"

@implementation CallerViewController

@synthesize numberLabel;
@synthesize phoneNumber;
@synthesize contacts;
@synthesize first;
@synthesize firstName;
@synthesize lastName;
@synthesize country;
@synthesize callRecordNeeded;
@synthesize stvNeeded;
@synthesize shouldShowNavControllerOnExit;
@synthesize v2bf;

#pragma mark -
#pragma mark Constructor and destructor

- (id)init 
{
    //dialer app doesnt use a nib
    if (self = [super initWithNibName:nil bundle:nil]) 
    {
        shouldShowNavControllerOnExit = YES;
        self.hidesBottomBarWhenPushed = YES;
        NSBundle *mainBundle = [NSBundle mainBundle];
        callingSound = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"calling" ofType:@"wav"]];
    }
    return self;
}

- (void)dealloc
{
    [callingSound release];
    [phoneNumber release];
    [contacts release];
    [numberLabel release];
    [first release];
    [firstName release];
    [lastName  release];
    [country release];
    [super dealloc];
}

#pragma mark -
#pragma mark IBAction methods

- (IBAction)cancel:(id)sender
{
    [[self navigationController] popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
   NSLog(@"user pressed Cancel");
}

#pragma mark -
#pragma mark Private methods

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

- (void)viewWillAppear:(BOOL)animated
{
    //check balance and display message if zero; no nib is used in dialer app
	PaymentViewController *pay = [[PaymentViewController alloc] initWithNibName:@"SecondView" bundle:nil];
	//init PaymentViewController before using any of its methods
	[pay viewDidLoad];
	
    //get max duration of current call BEFORE free count gets decremented by checkFreeCalls method below
    int64_t duration = [pay getMaxDuration];
    
	//check number of calls available; this decrements count btw
	[pay checkFreeCalls];
	
	//check also if ok to do free recordings	
    BOOL ok = true;
	if ([pay.paymentOK boolValue] != true) {
        //Show an alert asking user to purchase credit
        NSString *message  = [NSString stringWithFormat:@"%@", @"Please buy credit to proceed"];
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle: @"Buy Credit"
							  message: message
							  delegate:self
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil,
							  nil];
		[alert show];
		[alert release];
        ok = false;
    }
    
    //Display called party's name if present; else tel# will do
    if (ok)
    {
        if ([self isEmpty:firstName] && [self isEmpty:lastName]) {
            numberLabel.text = [NSString stringWithFormat:@"Calling %@", self.phoneNumber];
        }
        else {
            NSString *name   = nil;
            if (![self isEmpty:firstName] && ![self isEmpty:lastName]) {
                name   = [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
            }
            else if (![self isEmpty:firstName]) {
                name = [self.firstName copy];
            }
            else {
                name = [self.lastName copy];
            }
            numberLabel.text = [NSString stringWithFormat:@"Calling %@", name];
            [name release];
        }
    
        //connect the current user and the dialed number iff file url is non-empty
        if (![self isEmpty:v2bf]) {
            NSString *maxLength = [[NSString alloc] initWithFormat:@"%ld", duration];
            [first gotoVoicemail:self.phoneNumber toCcode:first.toCcode duration:maxLength callRecordNeeded:callRecordNeeded
                   stvNeeded:stvNeeded v2bf:self.v2bf];
            [maxLength release];
        }
		
        //store the current call in recents table
        DialedViewController *dvc = [[DialedViewController alloc] init];
        [dvc viewDidLoad]; //this needs to be done prior to calling any method in dvc
        [dvc saveCall:self.firstName last:self.lastName phoneNumber:self.phoneNumber 
              country:self.country contacts:contacts];
        
        //update the tabbarcontroller's view to point to this new dvc
        KeypadAppDelegate *appDelegate       = (KeypadAppDelegate *)[[UIApplication sharedApplication] delegate];
        UITabBarController *tabBarController = [appDelegate tabBarController];
        //Alloc a new array of viewcontrollers
        NSArray   *vcs   = [tabBarController viewControllers];
        //add a nav controller for dvc
        UINavigationController *navController2  = [[UINavigationController alloc] initWithRootViewController:dvc];
        NSArray *vcArray =  [[NSArray alloc] initWithObjects:[vcs objectAtIndex:0], [vcs objectAtIndex:1],
                             navController2, [vcs objectAtIndex:3], nil];
        [tabBarController setViewControllers:vcArray]; //update tabbarcontroller of app
        [dvc release];
        [navController2 release];
        
        //After a call is made successfully, clear label area
        numberLabel.text = @"";
		
		//Add a spinner to current view; show specific message depending on whether a file url is present or not
        spinner = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        if (![self isEmpty:v2bf]) {
            spinner.labelText        = @"Your message is being sent...";
            spinner.detailsLabelText = @"Takes about 10 seconds";
            
            //decrement call balance now
            [pay checkFreeCallsAndDecrement];
        }
        else {
            spinner.labelText        = @"Click on Messages below";
            spinner.detailsLabelText = @"Record your msg now";
        }
        
        //add spinner to current view
        KeypadAppDelegate* myDelegate = (((KeypadAppDelegate*) [UIApplication sharedApplication].delegate));
        //doesnt work [self.view addSubview:spinner];
        [myDelegate.window addSubview:spinner];
        
        //remove after 3 secs
		[NSTimer scheduledTimerWithTimeInterval:3 target:self
									   selector:@selector(dismissSpinner) userInfo:nil repeats:NO];
        
    } //else qty > zero
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

- (void)viewWillDisappear:(BOOL)animated
{
    if (shouldShowNavControllerOnExit)
    {
        //[[self navigationController] setNavigationBarHidden:NO animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    //[[self navigationController] setNavigationBarHidden:NO animated:YES];
    [callingSound play];
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
//{
//    return NO;
//}

@end
