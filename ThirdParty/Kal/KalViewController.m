/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalViewController.h"
#import "KalLogic.h"
#import "KalDataSource.h"
#import "KalPrivate.h"

#define PROFILER 0
#if PROFILER
#include <mach/mach_time.h>
#include <time.h>
#include <math.h>
void mach_absolute_difference(uint64_t end, uint64_t start, struct timespec *tp)
{
    uint64_t difference = end - start;
    static mach_timebase_info_data_t info = {0,0};
    
    if (info.denom == 0)
        mach_timebase_info(&info);
    
    uint64_t elapsednano = difference * (info.numer / info.denom);
    tp->tv_sec = elapsednano * 1e-9;
    tp->tv_nsec = elapsednano - (tp->tv_sec * 1e9);
}
#endif

NSString *const KalDataSourceChangedNotification = @"KalDataSourceChangedNotification";

@interface KalViewController ()

- (KalView*)calendarView;

@end

@implementation KalViewController

@synthesize dataSource, delegate;

- (void)setSelectedDate:(NSDate *)selectedDate
{
    [_selectedDates addObject:selectedDate];
    _selectedDate = [self dateWithZeroTime:selectedDate];
    self.calendarView.gridView.beginDate = _selectedDate;
    NSDateFormatter* timeDf = [[NSDateFormatter alloc] init];
    [timeDf setDateFormat:@"HH"];
    self.calendarView.hourlbl.text = [timeDf stringFromDate:selectedDate];
    [self showAndSelectDate:_selectedDate];
}

- (NSDate*)actualDate
{
    int time = [self.calendarView.hourlbl.text intValue];
    NSDate *date = [self.selectedDate dateByAddingTimeInterval:60*60*time];
    return date;
}

- (BOOL)isAutoReminderOn
{
    KalView* kal = ((KalView *)self.view);
    return kal.reminderEverySwitch.on;
}

- (NSString*)reminderFrequency
{
    KalView* kal = ((KalView *)self.view);
    return kal.reminderType.titleLabel.text;
}

- (void)setReminderWithType:(NSString*)type
{
    KalView* kal = ((KalView *)self.view);
    if([type isEqualToString:@""])
        kal.reminderEverySwitch.on = NO;
    else
        kal.reminderEverySwitch.on = YES;
    [kal.reminderType setTitle:type forState:UIControlStateNormal];
}


- (void)setBeginDate:(NSDate *)beginDate
{
    _beginDate = beginDate;
    self.calendarView.gridView.beginDate = _beginDate;
    [self showAndSelectDate:_beginDate];
}

- (void)setEndDate:(NSDate *)endDate
{
    _endDate = endDate;
    self.calendarView.gridView.endDate = _endDate;
    [(KalView *)self.view redrawEntireMonth];
}

- (void)setMinAvailableDate:(NSDate *)minAvailableDate
{
    _minAvailableDate = minAvailableDate;
    ((KalView *)self.view).gridView.minAvailableDate = minAvailableDate;
    [(KalView *)self.view redrawEntireMonth];
}

- (void)setMaxAVailableDate:(NSDate *)maxAVailableDate
{
    _maxAVailableDate = maxAVailableDate;
    ((KalView *)self.view).gridView.maxAVailableDate = maxAVailableDate;
    [(KalView *)self.view redrawEntireMonth];
}

- (id)initWithSelectionMode:(KalSelectionMode)selectionMode
{
    if ((self = [super init])) {
        logic = [[KalLogic alloc] initForDate:[NSDate date]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(significantTimeChangeOccurred) name:UIApplicationSignificantTimeChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:KalDataSourceChangedNotification object:nil];
        self.selectionMode = selectionMode;
        if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
    }
    return self;
}

- (id)initWithSelectionMode:(KalSelectionMode)selectionMode CalendarModeType:(CalendarModeType)mode
{
    if ((self = [super init])) {
        _selectedDates = [NSMutableArray new];
        self.modeType = mode;
        logic = [[KalLogic alloc] initForDate:[NSDate date]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(significantTimeChangeOccurred) name:UIApplicationSignificantTimeChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:KalDataSourceChangedNotification object:nil];
        self.selectionMode = selectionMode;
        if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
    }
    return self;
}


- (id)init
{
    return [self initWithSelectionMode:KalSelectionModeSingle];
}

- (KalView*)calendarView { return (KalView*)self.view; }

- (void)setDataSource:(id<KalDataSource>)aDataSource
{
    if (dataSource != aDataSource) {
        dataSource = aDataSource;
        tableView.dataSource = dataSource;
    }
}

- (void)setDelegate:(id<UITableViewDelegate>)aDelegate
{
    if (delegate != aDelegate) {
        delegate = aDelegate;
        tableView.delegate = delegate;
    }
}

- (void)clearTable
{
    [dataSource removeAllItems];
    [tableView reloadData];
}

- (void)reloadData
{
    [dataSource presentingDatesFrom:logic.fromDate to:logic.toDate delegate:self];
}

- (void)significantTimeChangeOccurred
{
    [[self calendarView] jumpToSelectedMonth];
    [self reloadData];
}

// -----------------------------------------
#pragma mark KalViewDelegate protocol

- (NSDate*)dateWithZeroTime:(NSDate*)date
{
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *components = [gregorian components: NSUIntegerMax fromDate: date];
    [components setHour: 0];
    [components setMinute: 0];
    [components setSecond: 0];
    NSDate *startDate = [gregorian dateFromComponents: components];
    return startDate;
}

- (void)didSelectDate:(NSDate *)date
{
    _selectedDate = date;
    NSDate *from = [date cc_dateByMovingToBeginningOfDay];
    NSDate *to = [date cc_dateByMovingToEndOfDay];
    [self clearTable];
    [dataSource loadItemsFromDate:from toDate:to];
    [tableView reloadData];
    [tableView flashScrollIndicators];
}

- (void)didSelectBeginDate:(NSDate *)beginDate endDate:(NSDate *)endDate
{
    _beginDate = beginDate;
    _endDate = endDate;
    [self clearTable];
    [dataSource loadItemsFromDate:beginDate toDate:endDate];
    [tableView reloadData];
    [tableView flashScrollIndicators];
}

- (void)tapOnDate:(NSDate *)date
{
    if(![_selectedDates containsObject:date])
        [_selectedDates addObject:date];
    else
        [_selectedDates removeObject:date];
    [dataSource tapOnDate:date];
}

- (void)removeSelectionOnDate:(NSDate *)date
{
    if([_selectedDates containsObject:date])
    {
        [_selectedDates removeObject:date];
        [[self calendarView] removeDate:date];
    }
}

- (void)showPreviousMonth
{
    [self clearTable];
    [logic retreatToPreviousMonth];
    [[self calendarView] slideDown];
    [self reloadData];
}

- (void)showFollowingMonth
{
    [self clearTable];
    [logic advanceToFollowingMonth];
    [[self calendarView] slideUp];
    [self reloadData];
}

// -----------------------------------------
#pragma mark KalDataSourceCallbacks protocol

- (void)loadedDataSource:(id<KalDataSource>)theDataSource;
{
    NSArray *markedDates = [theDataSource markedDatesFrom:logic.fromDate to:logic.toDate];
    NSMutableArray *dates = [markedDates mutableCopy];
    for (int i=0; i<[dates count]; i++)
        [dates replaceObjectAtIndex:i withObject:[dates objectAtIndex:i]];
    
    [[self calendarView] markTilesForDates:dates];
}

// ---------------------------------------
#pragma mark -

- (void)showAndSelectDate:(NSDate *)date
{
    if ([[self calendarView] isSliding])
        return;
    
    [logic moveToMonthForDate:date];
    
#if PROFILER
    uint64_t start, end;
    struct timespec tp;
    start = mach_absolute_time();
#endif
    
    [[self calendarView] jumpToSelectedMonth];
    
#if PROFILER
    end = mach_absolute_time();
    mach_absolute_difference(end, start, &tp);
    printf("[[self calendarView] jumpToSelectedMonth]: %.1f ms\n", tp.tv_nsec / 1e6);
#endif
    
    [self reloadData];
}

// -----------------------------------------------------------------------------------
#pragma mark UIViewController

- (void)loadView
{
    if(self.modeType == CalendarModeTypeDueDate)
        self.title = @"Calendar";
    else
        self.title = @"Reminder";
    KalView *kalView = [[KalView alloc] initWithFrame:CGRectMake(0, 0, 320, 480) delegate:self logic:logic withModeType:self.modeType];
    kalView.gridView.selectionMode = self.selectionMode;
    self.view = kalView;
    tableView = kalView.tableView;
    tableView.dataSource = dataSource;
    tableView.delegate = delegate;
    [self reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    tableView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [tableView reloadData];
    if ([self.navigationController.navigationBar respondsToSelector:@selector(setBarTintColor:)]) {
        self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
        self.navigationController.navigationBar.tintColor = [UIColor orangeColor];
    } else {
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    }
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : kLightGrayColor, NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:20]};
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [tableView flashScrollIndicators];
}

#pragma mark -

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationSignificantTimeChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KalDataSourceChangedNotification object:nil];
}

@end
