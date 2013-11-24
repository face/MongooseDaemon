//
//  CIMMongooseExampleViewController.m
//  MongooseDaemon
//
//  Created by Ibanez, Jose on 11/24/13.
//  Copyright (c) 2013 CIM. All rights reserved.
//

#import "CIMMongooseExampleViewController.h"
#import "CIMSwitchCell.h"
#import "CIMTextFieldCell.h"
#import <MongooseDaemon/MongooseDaemon.h>




typedef NS_ENUM(NSInteger, MongooseExampleTableViewRow) {
    MongooseExampleTableViewRowEnable = 0,
    MongooseExampleTableViewRowPort
};
const NSInteger kMongooseExampleTableViewNumberOfRows = 2;

NSString * const kMongooseExampleTableViewSwitchCellIdentifier = @"kMongooseExampleTableViewSwitchCellIdentifier";
NSString * const kMongooseExampleTableViewLabelCellIdentifier = @"kMongooseExampleTableViewLabelCellIdentifier";


@interface CIMMongooseExampleViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) MongooseDaemon *theMongoose;
@property UITableView *tableView;

@end


@implementation CIMMongooseExampleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"Mongoose Example", nil);
        self.editing = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.tableView registerNib:[UINib nibWithNibName:@"CIMSwitchCell" bundle:nil] forCellReuseIdentifier:kMongooseExampleTableViewSwitchCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"CIMTextFieldCell" bundle:nil] forCellReuseIdentifier:kMongooseExampleTableViewLabelCellIdentifier];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}


#pragma mark - Properties

- (MongooseDaemon *)theMongoose {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _theMongoose = [[MongooseDaemon alloc] init];
        
        // set the document root directory to the documents folder
        _theMongoose.documentRoot = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        
        // copy the hello world document to the documents folder
        NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"HelloWorld" ofType:@"html"];
        NSString *destinationPath = [_theMongoose.documentRoot stringByAppendingPathComponent:@"index.html"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
            NSError *error = nil;
            if (![[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error]) {
                NSLog(@"Copy [%@] to [%@] failed with error [%@]", sourcePath, destinationPath, error.localizedDescription);
            }
        }
    });
    return _theMongoose;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return kMongooseExampleTableViewNumberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    switch (indexPath.row) {
        case MongooseExampleTableViewRowEnable: {
            cell = [tableView dequeueReusableCellWithIdentifier:kMongooseExampleTableViewSwitchCellIdentifier forIndexPath:indexPath];
            CIMSwitchCell *switchCell = (CIMSwitchCell *)cell;
            switchCell.label.text = NSLocalizedString(@"Enabled", nil);
            switchCell.theSwitch.on = self.theMongoose.isRunning;
            [switchCell.theSwitch addTarget:self action:@selector(enableMongoose:) forControlEvents:UIControlEventValueChanged];
            break;
        }
        case MongooseExampleTableViewRowPort: {
            cell = [self.tableView dequeueReusableCellWithIdentifier:kMongooseExampleTableViewLabelCellIdentifier forIndexPath:indexPath];
            CIMTextFieldCell *textFieldCell = (CIMTextFieldCell *)cell;
            textFieldCell.label.text = NSLocalizedString(@"Port", nil);
            textFieldCell.textField.text = [NSString stringWithFormat:@"%d", self.theMongoose.listeningPort];
            textFieldCell.textField.enabled = !self.theMongoose.isRunning;
            break;
        }
        default:
            NSAssert1(false, @"Unexpected TableView indexPath [%@]", indexPath);
            break;
    }
    return cell;
}


#pragma mark - Received Actions

- (void)enableMongoose:(id)sender {
    UISwitch *theSwitch = (UISwitch *)sender;
    if (theSwitch.on) {
        CIMTextFieldCell *textFieldCell = (CIMTextFieldCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:MongooseExampleTableViewRowPort inSection:0]];
        self.theMongoose.listeningPort = [textFieldCell.textField.text integerValue];
        [self.theMongoose start];
    } else {
        [self.theMongoose stop];
    }
    [self.tableView reloadData];
}


@end
