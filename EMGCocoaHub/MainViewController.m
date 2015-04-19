//
//  MainViewController.m
//  EMGCocoaHub
//
//  Created by flynn on 4/18/15.
//  Copyright (c) 2015 Virginia Commonwealth University. All rights reserved.
//

#import "MainViewController.h"

#import "GestureModel.h"
#import "GestureWindowController.h"


@interface MainViewController ()

@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) IBOutlet NSTextView *logTextView;

@property (nonatomic, strong) NSMutableArray *gestures;

@property (nonatomic) BOOL isTraining;

@end


@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.gestures   = [NSMutableArray new];
    self.isTraining = NO;
}


- (void)displayLog:(NSString *)message
{
    NSString *string = [message stringByAppendingString:@"\n"];
    self.logTextView.string = [self.logTextView.string stringByAppendingString:string];
    [self.logTextView scrollToEndOfDocument:nil];
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
        
        if (self.tableView.selectedRow > 0)
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
    if (self.isTraining && self.tableView.selectedRow > 0)
    {
        GestureModel *gesture = [self.gestures objectAtIndex:self.tableView.selectedRow];
        
        if (!gesture.emg_gesture->is_committed)
            commit_training(gesture.emg_gesture);
    }
}


#pragma mark - SerialBluetoothInterfaceDelegate

- (void)serialBluetoothInterface:(SerialBluetoothInterface *)interface
          didEstablishConnection:(BOOL)connectionEstablished
{
    [self displayLog:@"Bluetooth connection established"];
}


- (void)serialBluetoothInterface:(SerialBluetoothInterface *)interface
              didReceiveFeatures:(fmatrix_t *)features
                         isOnset:(BOOL)isOnset
{
    if (self.isTraining)
    {
        if (self.tableView.selectedRow > 0)
        {
            GestureModel *gesture = [self.gestures objectAtIndex:self.tableView.selectedRow];
            [gesture addFeatureVector:features];
            
            [self displayLog:[NSString stringWithFormat:@"Training received for: \"%@\"", gesture.gestureName]];
        }
    }
    else
    {
        if (isOnset)
        {
            GestureModel *gesture = [GestureModel classifyFeatureVector:features gestures:self.gestures];
            
            if (gesture)
            {
                [gesture performKeyDown];
                
                [self displayLog:[NSString stringWithFormat:@"Identified gesture: \"%@\"", gesture.gestureName]];
            }
            else
            {
                [self displayLog:@"Received message but was unable to classify"];
            }
        }
        else
        {
            // Doesn't handle offset yet.
        }
    }
}


- (void)serialBluetoothInterfaceConnectionDidClose:(SerialBluetoothInterface *)interface
{
    [self displayLog:@"Bluetooth connection closed"];
}


@end
