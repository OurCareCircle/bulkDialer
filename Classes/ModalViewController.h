//
//  ModalViewController.h
//  Dialer
//
//  Created by sanjay krishnamurthy on 7/12/12.
//  Copyright (c) 2012 Infinear Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "V2bDialed.h"

@interface ModalViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

{
@private
    IBOutlet UIButton    *callRecordButton;
    IBOutlet UIButton    *stvButton;
    IBOutlet UIButton    *contButton;
    IBOutlet UIButton    *cancelButton;
    IBOutlet UIButton    *incomingRecordButton;
    IBOutlet UILabel     *callingCountry;
    IBOutlet UITextField *groupName;
    NSString             *country;
    NSMutableArray       *callsArray; //all dialed calls
    NSString             *defaultGrpName;
}

@property (nonatomic, retain) UIButton        *callRecordButton;
@property (nonatomic, retain) UIButton        *stvButton;
@property (nonatomic, retain) UIButton        *contButton;
@property (nonatomic, retain) UIButton        *cancelButton;
@property (nonatomic, retain) UIButton        *incomingRecordButton;
@property (nonatomic, retain) UILabel         *callingCountry;
@property (nonatomic, retain) UITextField     *groupName;
@property (nonatomic, retain) NSString        *defaultGrpName;
@property (nonatomic, retain) NSString        *country;
@property (nonatomic, retain) NSMutableArray  *callsArray;

- (NSString*)genUniqueGroupname;
- (void)saveCall:(NSString *)first last:(NSString *)last phoneNumber:(NSString *)phoneNumber
         country:(NSString *)country;
- (void)clearState;

@end
