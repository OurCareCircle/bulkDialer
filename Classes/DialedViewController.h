//
//  DialedViewController.h
//  Dialer
//
//  Created by sanjay krishnamurthy on 7/11/12.
//  Copyright (c) 2012 Infinear Inc. All rights reserved.
//

#import "RootViewController.h"

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "PopoverContentViewController.h"
#import "V2bDialed.h"
#import "v2bFile.h"

@interface DialedViewController : RootViewController {
	NSMutableArray                     *callsArray; //all files currently displaying	
    V2bDialed                          *dialed;     //group vc, this is non null
    v2bFile                            *currFile;   //pass folder and file name via this var to email view
}

@property (nonatomic, retain) NSMutableArray                     *callsArray;
@property (nonatomic, retain) V2bDialed                          *dialed;
@property (nonatomic, retain) v2bFile                            *currFile;

- (void)saveCall:(NSString *)first last:(NSString *)last phoneNumber:(NSString *)phoneNumber
         country:(NSString *)country contacts:(NSString*)contacts;
- (BOOL)checkCallExists:(NSString*)number;
- (V2bDialed*) createDialedObj;
- (BOOL) isEmpty:(id)thing;
- (NSMutableArray*)genContactsArray:(NSString*)numbers contacts:(NSString*)contacts country:(NSString*)country;

@end
