//
//  ViewController.h
//  Shimerun
//
//  Created by miminashi on 2016/08/09.
//  Copyright © 2016年 miminashi. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AWSIoT/AWSIoT.h>

@interface ViewController : UIViewController

@property (nonatomic) AWSIoTDataManager *iotDataManager;

@property (weak, nonatomic) IBOutlet UILabel *lockStateLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *lockStateUpdateActivityIndicator;

- (IBAction)openButtonDidTap:(id)sender;
- (IBAction)closeButtonDidTap:(id)sender;

@end

