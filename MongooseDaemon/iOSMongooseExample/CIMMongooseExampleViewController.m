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

NSString * const kMongooseExampleTableViewCellIdentifier = @"kMongooseExampleTableViewCellIdentifier";
NSString * const kMongooseExampleTableViewSwitchCellIdentifier = @"kMongooseExampleTableViewSwitchCellIdentifier";
NSString * const kMongooseExampleTableViewLabelCellIdentifier = @"kMongooseExampleTableViewLabelCellIdentifier";


@interface CIMMongooseExampleViewController () <UITableViewDataSource, UITableViewDelegate, MongooseDaemonDelegate>

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
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMongooseExampleTableViewCellIdentifier];
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
    
    _theMongoose.delegate = self;
    
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
  return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case 0:
      return kMongooseExampleTableViewNumberOfRows;
    default:
      return 1;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = nil;
  switch (indexPath.section) {
    case 0:
      switch (indexPath.row) {
        case MongooseExampleTableViewRowEnable: {
          cell = [tableView dequeueReusableCellWithIdentifier:kMongooseExampleTableViewSwitchCellIdentifier forIndexPath:indexPath];
          CIMSwitchCell *switchCell = (CIMSwitchCell *)cell;
          switchCell.label.text = NSLocalizedString(@"Enabled", nil);
          switchCell.theSwitch.on = self.theMongoose.isRunning;
          [switchCell.theSwitch addTarget:self action:@selector(enableMongoose:) forControlEvents:UIControlEventValueChanged];
          switchCell.accessoryType = UITableViewCellAccessoryNone;
          break;
        }
        case MongooseExampleTableViewRowPort: {
          cell = [self.tableView dequeueReusableCellWithIdentifier:kMongooseExampleTableViewLabelCellIdentifier forIndexPath:indexPath];
          CIMTextFieldCell *textFieldCell = (CIMTextFieldCell *)cell;
          textFieldCell.label.text = NSLocalizedString(@"Port", nil);
          textFieldCell.textField.text = [NSString stringWithFormat:@"%ld", (long)self.theMongoose.listeningPort];
          textFieldCell.textField.enabled = !self.theMongoose.isRunning;
          textFieldCell.accessoryType = UITableViewCellAccessoryNone;
          break;
        }
        default:
          NSAssert1(false, @"Unexpected TableView indexPath [%@]", indexPath);
          break;
      }
      break;
      
    case 1: {
      cell = [tableView dequeueReusableCellWithIdentifier:kMongooseExampleTableViewCellIdentifier forIndexPath:indexPath];
      cell.textLabel.text = NSLocalizedString(@"index.html", nil);
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case 2: {
      cell = [tableView dequeueReusableCellWithIdentifier:kMongooseExampleTableViewLabelCellIdentifier forIndexPath:indexPath];
      CIMTextFieldCell *textFieldCell = (CIMTextFieldCell *)cell;
      textFieldCell.label.text = NSLocalizedString(@"StatusCode", nil);
      textFieldCell.textField.text = [NSString stringWithFormat:@"%d", 200];
      textFieldCell.textField.enabled = YES;
      textFieldCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    default:
      NSAssert1(false, @"Unexpected TableView indexPath [%@]", indexPath);
      break;
  }

  return cell;
}


#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.theMongoose.isRunning && (indexPath.section != 0)) {
    return indexPath;
  } else {
    return nil;
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  UIViewController *vc = [[UIViewController alloc] init];
  vc.title = NSLocalizedString(@"Local Web Server", nil);
  UIWebView *webView = [[UIWebView alloc] initWithFrame:vc.view.bounds];
  [vc.view addSubview:webView];
  
  NSURL *localhost = [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%ld", (long)self.theMongoose.listeningPort]];
  NSURL *url = nil;
  if (indexPath.section == 1) {
    url = localhost;
  } else if (indexPath.section == 2) {
    CIMTextFieldCell *textFieldCell = (CIMTextFieldCell *)[tableView cellForRowAtIndexPath:indexPath];
    url = [localhost URLByAppendingPathComponent:[NSString stringWithFormat:@"errors?code=%@", textFieldCell.textField.text]];
  }
  NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
  [webView loadRequest:request];
  
  [self.navigationController pushViewController:vc animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  switch (section) {
    case 0:
      return [NSString stringWithFormat:NSLocalizedString(@"Mongoose [%@] Settings", nil), [MongooseDaemon versionString]];
    case 1:
      return NSLocalizedString(@"Static File", nil);
    case 2:
      return NSLocalizedString(@"Delegate", nil);
    default:
      NSAssert1(false, @"Unexpected TableView section [%ld]", (long)section);
      return nil;
  }
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


#pragma mark - MongooseDaemonDelegate

- (NSHTTPURLResponse *)mongooseDaemon:(MongooseDaemon *)daemon customResponseForRequest:(NSURLRequest *)request withResponseData:(NSData *__autoreleasing *)responseData {
  NSLog(@"%s: [%@]%@", __PRETTY_FUNCTION__, request.HTTPMethod, [request.URL absoluteString]);
  
  if (![request.URL.pathComponents containsObject:@"errors"]) {
    return nil;
  }
  
  NSInteger statusCode = 200;
  NSString *query = request.URL.query;
  NSString *queryValue = [[query componentsSeparatedByString:@"="] lastObject];
  statusCode = [queryValue integerValue];
  
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                            statusCode:statusCode
                                                           HTTPVersion:@"HTTP/1.1"
                                                          headerFields:nil];
  
  NSString *responseString = [NSString stringWithFormat:@"Custom response!\nRequest [%@]\nMethod [%@]\nstatusCode [%ld]", request.URL, request.HTTPMethod, (long)statusCode];
  *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
  return response;
}

- (void)mongooseDaemon:(MongooseDaemon *)daemon didCompleteRequest:(NSURLRequest *)request withStatusCode:(NSInteger)statusCode {
  NSLog(@"%s: %@ %ld", __PRETTY_FUNCTION__, [request.URL absoluteString], (long)statusCode);
}

- (BOOL)mongooseDaemon:(MongooseDaemon *)daemon shouldLogMessage:(NSString *)message {
  NSLog(@"%s: %@", __PRETTY_FUNCTION__, message);
  return YES;
}

@end
