//
//  GroupViewController.h
//  bulk
//
//  Created by sanjay krishnamurthy mac mini account on 1/10/13.
//
//

#import "DialedViewController.h"

@interface GroupViewController : DialedViewController {
    
    DialedViewController               *parent;     //use this parent for all methods inside dialed vc
    
}

@property (nonatomic, retain) DialedViewController  *parent;

- (void)    sendEvent;
- (void)    clearState;
- (void)    popToRoot;
-(v2bFile*) cloneCurrFile:(v2bFile*)currFile;

@end
