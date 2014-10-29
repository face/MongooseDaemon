//
//  CIMLabelCell.h
//  MongooseDaemon
//
//  Created by Ibanez, Jose on 11/24/13.
//  Copyright (c) 2013 CIM. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CIMTextFieldCell : UITableViewCell <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UILabel *label;
@property (nonatomic, weak) IBOutlet UITextField *textField;

@end
