//
//  ViewController.m
//  CompanyScouter
//
//  Created by shuichi on 9/7/13.
//  Copyright (c) 2013 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
#import "CrunchBaseClient.h"
#import "KloutAPIClient.h"
#import "SVProgressHUD.h"
#import "Utils.h"
#import <QuartzCore/QuartzCore.h>


#define kSpecialColor [UIColor colorWithRed:0.0 green:85./255.0 blue:0.0 alpha:1.0]
#define kBtnColor [UIColor colorWithRed:0.582 green:0.752 blue:0.148 alpha:1.000]


@interface ViewController ()
<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) IBOutlet UILabel *scoreLabel;
@property (nonatomic, weak) IBOutlet UITextField *inputTextView;
@property (nonatomic, weak) IBOutlet UIButton *startBtn;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (assign) NSUInteger numPendingScores;
@property (assign) CGFloat totalScore;
@property (nonatomic, strong) NSMutableArray *scores;
@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // appearance set up
    UIImage *btnColorImage = [Utils drawImageOfSize:CGSizeMake(1, 1) andColor:kBtnColor];
    [self.startBtn setBackgroundImage:btnColorImage forState:UIControlStateNormal];
    [self.startBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.startBtn.layer.cornerRadius = 5.0;
    self.startBtn.layer.masksToBounds = YES;
    
    [self clearScouterResults];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// =============================================================================
#pragma mark - Private

- (void)clearScouterResults {

    self.scoreLabel.text = nil;
    self.tableView.hidden = YES;
}

- (void)finishScounterIfNeeded {

    self.numPendingScores--;

    // all score have been retrieved
    if (self.numPendingScores <= 0) {

        [SVProgressHUD dismiss];

        // show result
        self.scoreLabel.text = [NSString stringWithFormat:@"%.0f", self.totalScore];
        self.tableView.hidden = NO;
        
        [self.tableView reloadData];
    }
}


// =============================================================================
#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    return @"  Scores";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.scores count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                      reuseIdentifier:CellIdentifier];
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:@"Futura-Medium" size:16.0];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.font = [UIFont fontWithName:@"Futura-Medium" size:16.0];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.backgroundColor = [UIColor clearColor];
    }
    
	NSDictionary *scoreInfo = [self.scores objectAtIndex:indexPath.row];

    NSString *nickname = scoreInfo[@"nick"];
    cell.textLabel.text = [NSString stringWithFormat:@"@%@", nickname];
    
    CGFloat score = [KloutAPIClient scoreFromScoreResult:scoreInfo];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f", score];
    
    return cell;
}


// =============================================================================
#pragma mark UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UILabel *indexLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    indexLabel.font                 = [UIFont fontWithName:@"Futura-Midium" size: 18.0];
    indexLabel.textColor            = [UIColor whiteColor];
    indexLabel.shadowColor          = [UIColor clearColor];
    indexLabel.shadowOffset         = CGSizeMake(0, 0);
    indexLabel.backgroundColor      = kSpecialColor;
    [indexLabel sizeToFit];
    indexLabel.opaque   = YES;
    
    indexLabel.text = @"  Scores";

    return indexLabel;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 34.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}


// =============================================================================
#pragma mark - UITextFieldDelegate




// =============================================================================
#pragma mark - IBAction

- (IBAction)pressStart {

    if (![self.inputTextView.text length]) {
        
        NSLog(@"no company name");
        
        return;
    }
    
    [self.inputTextView resignFirstResponder];
    
    [self clearScouterResults];
    
    __weak ViewController *weakSelf = self;
    
    [SVProgressHUD showWithStatus:@"Loading..."
                         maskType:SVProgressHUDMaskTypeGradient];
    
    [CrunchBaseClient personsWithCompanyName:self.inputTextView.text
                                     handler:
     ^(NSArray *result, NSError *error) {

         if (error) {
             
             NSLog(@"error:%@", error);
             [SVProgressHUD showErrorWithStatus:error.localizedDescription];
         }
         else {
                          
             weakSelf.numPendingScores = [result count];
             weakSelf.totalScore = 0.;
             weakSelf.scores = @[].mutableCopy;
             
             NSUInteger numValidPerson = 0;
             
             for (NSDictionary *person in result) {
                 
                 NSString *screenName = person[@"twitter_username"];

                 if ([screenName isKindOfClass:[NSString class]] && [screenName length]) {

                     numValidPerson++;

                     // Klout APIは1秒あたり10回までの制限があり、scoreWithTwitterは内部で2回APIを呼ぶので、0.2秒ずつずらせばよい
                     // 余裕をもって0.25秒ずつずらす
                     // Klout API is limited to 10 Calls per second

                     dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW,
                                                          0.25 * numValidPerson * NSEC_PER_SEC);
                     
                     dispatch_queue_t queue;
                     queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                     
                     dispatch_after(when, queue, ^{
                        
                         [KloutAPIClient scoreWithTwitterScreenName:screenName
                                                            handler:
                          ^(NSDictionary *result, NSError *error) {
                              
                              NSLog(@"screenName:%@, result:%@, error:%@", screenName, result, error);
                              if (!error) {
                                  CGFloat score = [KloutAPIClient scoreFromScoreResult:result];
                                  weakSelf.totalScore += score;
                                  [weakSelf.scores addObject:result];
                              }
                              [weakSelf finishScounterIfNeeded];
                          }];
                     });
                 }
                 else {
                     [weakSelf finishScounterIfNeeded];
                 }                 
             }
         }
     }];
}

@end
