//
//  MainViewController.m
//  EMGCocoaHub
//
//  Created by flynn on 4/18/15.
//  Copyright (c) 2015 Virginia Commonwealth University. All rights reserved.
//

#import "MainViewController.h"

#include "emg_matrix.h"
#include "TestData.h"

#import "GestureModel.h"
#import "GestureWindowController.h"


@interface MainViewController ()

@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) IBOutlet NSTextView *logTextView;

@property (nonatomic, strong) NSMutableArray *gestures;

@property (nonatomic) BOOL isTraining;

@property (nonatomic, strong) BluetoothInterface *bluetoothInterface;

@end


@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.gestures   = [NSMutableArray new];
    self.isTraining = NO;

    BOXCOX_LAMBDA = 0.4;
    MAX_CHANNELS = 2;
    
    self.bluetoothInterface = [[BluetoothInterface alloc] initWithDelegate:self];
    [self.bluetoothInterface connect];
}


- (void)displayLog:(NSString *)message
{
    NSString *string = [message stringByAppendingString:@"\n"];
    self.logTextView.string = [self.logTextView.string stringByAppendingString:string];
    [self.logTextView scrollToEndOfDocument:nil];
}


- (void)handleMotionOnset:(fmatrix_t *)features
{
    if (self.isTraining)
    {
        if (self.tableView.selectedRow >= 0)
        {
            GestureModel *gesture = [self.gestures objectAtIndex:self.tableView.selectedRow];
            [gesture addFeatureVector:features];
            
            [self displayLog:[NSString stringWithFormat:@"Training received for: \"%@\"", gesture.gestureName]];
            NSInteger selectedRow = self.tableView.selectedRow;
            [self.tableView reloadData];
            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
        }
    }
    else
    {
        ClassificationInfo *info = [GestureModel classifyFeatureVector:features gestures:self.gestures];
        
        if (info.gesture)
        {
            [info.gesture performKeyDown];
            
            [self displayLog:[NSString stringWithFormat:@"Identified gesture: \"%@\" with confidence: %@", info.gesture.gestureName, info.confidence]];
        }
        else
        {
            [self displayLog:@"Received message but was unable to classify"];
        }
    }
}


#pragma mark - User Actions

- (IBAction)toggleTrainingMode:(id)sender
{
    NSButton *button = (NSButton *)sender;
    
    self.isTraining = (button.state == NSOnState);
    
    if (self.isTraining)
    {
        [self displayLog:@"Training mode entered."];
    }
    else
    {
        [self displayLog:@"Taken out of training mode."];
        
        if (self.tableView.selectedRow >= 0)
        {
            GestureModel *gesture = [self.gestures objectAtIndex:self.tableView.selectedRow];
            
            if (!gesture.emg_gesture->is_committed)
                commit_training(gesture.emg_gesture);
        }
    }
}


- (IBAction)createGestureAction:(id)sender
{    
    GestureWindowController *gestureWindowController = [[GestureWindowController alloc] initWithGesture:nil];
    
    [self.view.window beginSheet:gestureWindowController.window completionHandler:^(NSModalResponse returnCode) {
    
        if (gestureWindowController.gesture)
        {
            GestureModel *gesture = gestureWindowController.gesture;
            [self.gestures addObject:gesture];
            [self.tableView reloadData];
            [self displayLog:[NSString stringWithFormat:@"Created gesture: \"%@\".", gesture.gestureName]];
        }
    }];
}


- (IBAction)clearGestureAction:(id)sender
{
    if (self.tableView.selectedRow >= 0)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert addButtonWithTitle:@"Clear"];
        [alert addButtonWithTitle:@"Cancel"];
        
        alert.messageText = @"Clear the selected gesture?";
        alert.alertStyle = NSWarningAlertStyle;
        
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            
            if (returnCode == NSAlertFirstButtonReturn) // Clear!
            {
                GestureModel *gesture = [self.gestures objectAtIndex:self.tableView.selectedRow];
                [gesture clearGesture];
                [self.tableView reloadData];
                [self displayLog:[NSString stringWithFormat:@"Cleared gesture: \"%@\".", gesture.gestureName]];
            }
        }];
    }
    else
        [self displayLog:@"No gesture selected."];
}


- (IBAction)editGestureAction:(id)sender
{
    if (self.tableView.selectedRow >= 0)
    {
        GestureModel *gesture = [self.gestures objectAtIndex:self.tableView.selectedRow];
        GestureWindowController *gestureWindowController = [[GestureWindowController alloc] initWithGesture:gesture];
        
        [self.view.window beginSheet:gestureWindowController.window completionHandler:^(NSModalResponse returnCode) {
            // Capture gestureWindowController in this block so it doesn't get released when it is dismissed.
            GestureModel *gesture = gestureWindowController.gesture; gesture = gesture;
            
            if (returnCode == NSModalResponseContinue)
                [self.tableView reloadData];
        }];
    }
    else
        [self displayLog:@"No gesture selected."];
}


- (IBAction)deleteGestureAction:(id)sender
{
    if (self.tableView.selectedRow >= 0)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert addButtonWithTitle:@"Delete"];
        [alert addButtonWithTitle:@"Cancel"];
        
        alert.messageText = @"Delete the selected gesture?";
        alert.alertStyle = NSWarningAlertStyle;
        
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            
            if (returnCode == NSAlertFirstButtonReturn) // Delete!
            {
                GestureModel *gesture = [self.gestures objectAtIndex:self.tableView.selectedRow];
                [self.gestures removeObject:gesture];
                [self.tableView reloadData];
                [self displayLog:[NSString stringWithFormat:@"Deleted gesture: \"%@\".", gesture.gestureName]];
            }
        }];
    }
    else
        [self displayLog:@"No gesture selected."];
}


#pragma mark - NSTableViewDataSource/Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.gestures.count;
}


- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    GestureModel *gesture = [self.gestures objectAtIndex:row];

    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if ([tableColumn.identifier isEqualToString:@"GestureName"])
    {
        cellView.textField.stringValue = gesture.gestureName;
    }
    else if ([tableColumn.identifier isEqualToString:@"Key"])
    {
        cellView.textField.stringValue = gesture.assignedKeyString;
    }
    else if ([tableColumn.identifier isEqualToString:@"NumObs"])
    {
        cellView.textField.stringValue = [gesture.numberOfObservations stringValue];
    }
    else if ([tableColumn.identifier isEqualToString:@"DeviceName"])
    {
        cellView.textField.stringValue = gesture.deviceName;
    }
    
    return cellView;
}


- (void)tableViewSelectionIsChanging:(NSNotification *)notification
{
    if (self.isTraining && self.tableView.selectedRow >= 0)
    {
        GestureModel *gesture = [self.gestures objectAtIndex:self.tableView.selectedRow];
        
        if (!gesture.emg_gesture->is_committed)
            commit_training(gesture.emg_gesture);
    }
}


#pragma mark - BluetoothInterfaceDelegate

- (void)bluetoothInterfaceDidConnectToDevice:(BluetoothInterface *)interface
{
    NSLog(@"Connected!");
}


- (void)bluetoothInterfaceFailedToConnectToDevice:(BluetoothInterface *)interface
{
    NSLog(@"Failed!");
}


- (void)bluetoothInterface:(BluetoothInterface *)interface didReceiveFeatures:(fmatrix_t *)features isOnset:(BOOL)onset
{
    if (onset)
        [self handleMotionOnset:features];
}


#pragma mark - Tests

- (IBAction)testA:(id)sender
{
    static unsigned index;
    
    fmatrix_t features = init_fmatrix(1, TEST_NUM_COLS);
    
    for (int i = 0; i < TEST_NUM_COLS; i++)
        features.values[0][i] = test_a[index % TEST_A_NUM_ROWS][i];
    
    [self handleMotionOnset:&features];
    
    index++;
}


- (IBAction)testB:(id)sender
{
    static unsigned index;
    
    fmatrix_t features = init_fmatrix(1, TEST_NUM_COLS);
    
    for (int i = 0; i < TEST_NUM_COLS; i++)
        features.values[0][i] = test_b[index % TEST_B_NUM_ROWS][i];
    
    [self handleMotionOnset:&features];
    
    index++;
}


- (IBAction)testC:(id)sender
{
    static unsigned index;
    
    fmatrix_t features = init_fmatrix(1, TEST_NUM_COLS);
    
    for (int i = 0; i < TEST_NUM_COLS; i++)
        features.values[0][i] = test_c[index % TEST_C_NUM_ROWS][i];
    
    [self handleMotionOnset:&features];
    
    index++;
}


- (IBAction)testD:(id)sender
{
    static unsigned index;
    
    fmatrix_t features = init_fmatrix(1, TEST_NUM_COLS);
    
    for (int i = 0; i < TEST_NUM_COLS; i++)
        features.values[0][i] = test_d[index % TEST_D_NUM_ROWS][i];
    
    [self handleMotionOnset:&features];
    
    index++;
}


@end
