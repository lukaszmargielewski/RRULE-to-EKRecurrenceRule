//
//  EKRecurrenceRule+RRULE.m
//  RRULE
//
//  Created by Jochen Schöllig on 24.04.13.
//  Copyright (c) 2013 Jochen Schöllig. All rights reserved.
//

#import "EKRecurrenceRule+RRULE.h"
#import <objc/runtime.h>

static NSDate *_startDateAAAA;
static NSDate *_endDateAAAA;
static NSDateFormatter *dateFormatter = nil;


@implementation EKRecurrenceRule (RRULE)

- (NSDate *)startDate{
    
    return objc_getAssociatedObject(self, &_startDateAAAA);
}

- (void) setStartDate:(NSDate *)startDate{
    
    objc_setAssociatedObject(self, &_startDateAAAA,
                             startDate, OBJC_ASSOCIATION_RETAIN);
}

- (NSDate *)endDate{
    
    return objc_getAssociatedObject(self, &_endDateAAAA);
}

- (void)setEndDate:(NSDate *)endDate{
    
    objc_setAssociatedObject(self, &_endDateAAAA,
                             endDate, OBJC_ASSOCIATION_RETAIN);
}


- (EKRecurrenceRule *)initWithString:(NSString *)rfc2445String
{
    return [self initWithString:rfc2445String andParseMore:YES];
}

- (EKRecurrenceRule *)initWithString:(NSString *)rfc2445String andParseMore:(BOOL)more{
    // If the date formatter isn't already set up, create it and cache it for reuse.
    [self createDefaultDateFormatterIfNeeded];
    
    // Begin parsing
    NSArray *components = [rfc2445String.uppercaseString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@";="]];

    EKRecurrenceFrequency frequency = EKRecurrenceFrequencyDaily;
    NSInteger interval              = 1;
    NSMutableArray *daysOfTheWeek   = nil;
    NSMutableArray *daysOfTheMonth  = nil;
    NSMutableArray *monthsOfTheYear = nil;
    NSMutableArray *daysOfTheYear   = nil;
    NSMutableArray *weeksOfTheYear  = nil;
    NSMutableArray *setPositions    = nil;
    EKRecurrenceEnd *recurrenceEnd  = nil;
    
    for (int i = 0; i < components.count; i++)
    {
        NSString *component = [components objectAtIndex:i];
        
        // Frequency
        if ([component isEqualToString:@"FREQ"])
        {
            NSString *frequencyString = [components objectAtIndex:++i];
            
            if      ([frequencyString isEqualToString:@"DAILY"])   frequency = EKRecurrenceFrequencyDaily;
            else if ([frequencyString isEqualToString:@"WEEKLY"])  frequency = EKRecurrenceFrequencyWeekly;
            else if ([frequencyString isEqualToString:@"MONTHLY"]) frequency = EKRecurrenceFrequencyMonthly;
            else if ([frequencyString isEqualToString:@"YEARLY"])  frequency = EKRecurrenceFrequencyYearly;
        }
    
        // Interval
        else if ([component isEqualToString:@"INTERVAL"])
        {
            interval = [[components objectAtIndex:++i] intValue];
        }
        
        // Days of the week
        else if ([component isEqualToString:@"BYDAY"])
        {
            daysOfTheWeek = [NSMutableArray array];
            NSArray *dayStrings = [[components objectAtIndex:++i] componentsSeparatedByString:@","];
            for (NSString *dayString in dayStrings)
            {
                int dayOfWeek = 0;
                int weekNumber = 0;
                
                // Parse the day of the week
                if ([dayString rangeOfString:@"SU"].location != NSNotFound)      dayOfWeek = EKSunday;
                else if ([dayString rangeOfString:@"MO"].location != NSNotFound) dayOfWeek = EKMonday;
                else if ([dayString rangeOfString:@"TU"].location != NSNotFound) dayOfWeek = EKTuesday;
                else if ([dayString rangeOfString:@"WE"].location != NSNotFound) dayOfWeek = EKWednesday;
                else if ([dayString rangeOfString:@"TH"].location != NSNotFound) dayOfWeek = EKThursday;
                else if ([dayString rangeOfString:@"FR"].location != NSNotFound) dayOfWeek = EKFriday;
                else if ([dayString rangeOfString:@"SA"].location != NSNotFound) dayOfWeek = EKSaturday;
                
                // Parse the week number
                weekNumber = [[dayString substringToIndex:dayString.length-2] intValue];
  
                [daysOfTheWeek addObject:[EKRecurrenceDayOfWeek dayOfWeek:dayOfWeek weekNumber:weekNumber]];
            }
        }
        
        // Days of the month
        else if ([component isEqualToString:@"BYMONTHDAY"])
        {
            daysOfTheMonth = [NSMutableArray array];
            NSArray *dayStrings = [[components objectAtIndex:++i] componentsSeparatedByString:@","];
            for (NSString *dayString in dayStrings)
            {
                [daysOfTheMonth addObject:[NSNumber numberWithInt:dayString.intValue]];
            }
        }
        
        // Months of the year
        else if ([component isEqualToString:@"BYMONTH"])
        {
            monthsOfTheYear = [NSMutableArray array];
            NSArray *monthStrings = [[components objectAtIndex:++i] componentsSeparatedByString:@","];
            for (NSString *monthString in monthStrings)
            {
                [monthsOfTheYear addObject:[NSNumber numberWithInt:monthString.intValue]];
            }
        }
        
        // Weeks of the year
        else if ([component isEqualToString:@"BYWEEKNO"])
        {
            weeksOfTheYear = [NSMutableArray array];
            NSArray *weekStrings = [[components objectAtIndex:++i] componentsSeparatedByString:@","];
            for (NSString *weekString in weekStrings)
            {
                [weeksOfTheYear addObject:[NSNumber numberWithInt:weekString.intValue]];
            }
        }
        
        // Days of the year
        else if ([component isEqualToString:@"BYYEARDAY"])
        {
            daysOfTheYear = [NSMutableArray array];
            NSArray *dayStrings = [[components objectAtIndex:++i] componentsSeparatedByString:@","];
            for (NSString *dayString in dayStrings)
            {
                [daysOfTheYear addObject:[NSNumber numberWithInt:dayString.intValue]];
            }
        }
        
        // Set positions
        else if ([component isEqualToString:@"BYSETPOS"])
        {
            setPositions = [NSMutableArray array];
            NSArray *positionStrings = [[components objectAtIndex:++i] componentsSeparatedByString:@","];
            for (NSString *potitionString in positionStrings)
            {
                [setPositions addObject:[NSNumber numberWithInt:potitionString.intValue]];
            }
        }
        
        // RecurrenceEnd
        else if ([component isEqualToString:@"COUNT"])
        {
            NSUInteger occurenceCount = [[components objectAtIndex:++i] intValue];
            recurrenceEnd = [EKRecurrenceEnd recurrenceEndWithOccurrenceCount:occurenceCount];
            
        }
        else if ([component isEqualToString:@"UNTIL"])
        {
            NSDate *endDate =  [dateFormatter dateFromString:[components objectAtIndex:++i]];
            recurrenceEnd = [EKRecurrenceEnd recurrenceEndWithEndDate:endDate];
            
            if(more)
                self.endDate = endDate;
        }
        
        // Start Date
        else if ([component isEqualToString:@"DTSTART"])
        {
            NSDate *startDate =  [dateFormatter dateFromString:[components objectAtIndex:++i]];
            
            self.startDate = startDate;
        }
        
    }
    
    return [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:frequency
                                                        interval:interval
                                                   daysOfTheWeek:daysOfTheWeek
                                                  daysOfTheMonth:daysOfTheMonth
                                                 monthsOfTheYear:monthsOfTheYear
                                                  weeksOfTheYear:weeksOfTheYear
                                                   daysOfTheYear:daysOfTheYear
                                                    setPositions:setPositions
                                                             end:recurrenceEnd];
}

+ (NSString *)shortLabelFromRRule:(NSString *)rrule{

    if (!rrule) {
        return NSLocalizedString(@"Will not repeat", @"");
    }
    
        // TODO: Implement labeling here...
    
    // Begin parsing
    NSArray *components = [rrule componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@";="]];
    
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:200];
    
    
    NSInteger  frequency = -1;
    NSInteger interval = -1;
    NSInteger occurenceCount = -1;
    NSDate *endDate = nil;
    
    for (int i = 0; i < components.count; i++)
    {
        NSString *component = [components objectAtIndex:i];
        
        // Frequency
        if ([component isEqualToString:@"FREQ"])
        {
            NSString *frequencyString = [components objectAtIndex:++i];
            
            if      ([frequencyString isEqualToString:@"DAILY"])   frequency = EKRecurrenceFrequencyDaily;
            else if ([frequencyString isEqualToString:@"WEEKLY"])  frequency = EKRecurrenceFrequencyWeekly;
            else if ([frequencyString isEqualToString:@"MONTHLY"]) frequency = EKRecurrenceFrequencyMonthly;
            else if ([frequencyString isEqualToString:@"YEARLY"])  frequency = EKRecurrenceFrequencyYearly;
        }
        
        // Interval
        else if ([component isEqualToString:@"INTERVAL"])
        {
            interval = [[components objectAtIndex:++i] intValue];
        }

        
        // RecurrenceEnd
        else if ([component isEqualToString:@"COUNT"])
        {
            occurenceCount = [[components objectAtIndex:++i] intValue];

            
        }
        else if ([component isEqualToString:@"UNTIL"])
        {
            endDate =  [dateFormatter dateFromString:[components objectAtIndex:++i]];
            
        }
    
    }
    
    if (frequency > -1 && interval > 0) {
        
        [string appendString:NSLocalizedString(@"Every ", @"")];
        
        switch (frequency) {
            case EKRecurrenceFrequencyDaily:
            {
                NSString *format = interval == 1 ? NSLocalizedString(@"dag", @"") : NSLocalizedString(@"%i. dag", @"");
                [string appendFormat:format, interval];
            }
                break;
            case EKRecurrenceFrequencyWeekly:
            {
                NSString *format = interval == 1 ? NSLocalizedString(@"uge", @"") : NSLocalizedString(@"%i. uge", @"");
                [string appendFormat:format, interval];
            }
                break;
            case EKRecurrenceFrequencyMonthly:
            {
                NSString *format = interval == 1 ? NSLocalizedString(@"%måned", @"") : NSLocalizedString(@"%i. måned", @"");
                [string appendFormat:format, interval];
            }
                break;
                
            case EKRecurrenceFrequencyYearly:
            {
                NSString *format = interval == 1 ? NSLocalizedString(@"år", @"") : NSLocalizedString(@"%i. åre", @"");
                [string appendFormat:format, interval];
            }
                break;
                
            default:
                break;
        }
    }
    
    if (occurenceCount > 0) {
        
        [string appendString:@", "];
        NSString *format = occurenceCount == 1 ? NSLocalizedString(@"%i gentagelse", @"") : NSLocalizedString(@"%i gentagelser", @"");
        [string appendFormat:format, occurenceCount];
    
    }else if (endDate){
    
        [string appendString:NSLocalizedString(@", until ", @"")];
        NSDateFormatter *df= [[NSDateFormatter alloc] init];
        df.dateFormat = @"d. MM yyyy";
        [string appendString:[df stringFromDate:endDate]];
    }
    
    return string;
}
+ (NSString *)shortLabelFromEKRecurrenceRule:(EKRecurrenceRule *)recurrenceRule{
    
    NSString *rrule = [recurrenceRule rfc2445String];
    return [EKRecurrenceRule shortLabelFromRRule:rrule];
    
}

- (void)createDefaultDateFormatterIfNeeded{

    // If the date formatter isn't already set up, create it and cache it for reuse.
    if (dateFormatter == nil)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        
        [dateFormatter setLocale:enUSPOSIXLocale];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSXXX"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
}

- (NSString *)rfc2445String{
   
    [self createDefaultDateFormatterIfNeeded];
    

    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:200];
    
    
    EKRecurrenceEnd *recurrenceEnd  = self.recurrenceEnd;
    
    if (self.startDate)
    {
        
        
        [string appendFormat:@"DTSTART=%@;", [dateFormatter stringFromDate:self.startDate]];
    }
    
    if (recurrenceEnd || self.endDate) {
        
        if (recurrenceEnd && recurrenceEnd.occurrenceCount) {
            
            [string appendFormat:@"COUNT=%lu;", (unsigned long)recurrenceEnd.occurrenceCount];
            
        }else if (recurrenceEnd.endDate || self.endDate){
            
            NSDate *endDate = recurrenceEnd.endDate ? recurrenceEnd.endDate : self.endDate;
            [string appendFormat:@"UNTIL=%@;", [dateFormatter stringFromDate:endDate]];
        }
    }
    
    
    EKRecurrenceFrequency frequency = self.frequency;
    NSInteger interval              = self.interval;
    NSArray *daysOfTheWeek   = self.daysOfTheWeek;
    NSArray *daysOfTheMonth  = self.daysOfTheMonth;
    NSArray *monthsOfTheYear = self.monthsOfTheYear;
    NSArray *daysOfTheYear   = self.daysOfTheYear;
    NSArray *weeksOfTheYear  = self.weeksOfTheYear;
    NSArray *setPositions    = self.setPositions;
    
    
    
    // Frequency:
    switch (frequency) {
        case EKRecurrenceFrequencyDaily:
        [string appendString:@"FREQ=DAILY;"];
        break;
        case EKRecurrenceFrequencyWeekly:
        [string appendString:@"FREQ=WEEKLY;"];
        break;
        case EKRecurrenceFrequencyMonthly:
        [string appendString:@"FREQ=MONTHLY;"];
        break;
        case EKRecurrenceFrequencyYearly:
        [string appendString:@"FREQ=YEARLY;"];
        break;
        default:
        break;
    }
    
    // Interval:
    if (interval > 0) {
        [string appendFormat:@"INTERVAL=%li;", (long)interval];
    }

    if (daysOfTheWeek && daysOfTheWeek.count) {
        
        [string appendString:@"BYDAY="];
        
        int i = 0;
        
        for (EKRecurrenceDayOfWeek *dayOfTheWeek in daysOfTheWeek) {
            
            NSInteger dayOfWeek = dayOfTheWeek.dayOfTheWeek;
            
            if (i > 0) {
                [string appendString:@","];
            }
            
            NSInteger weekNumber = dayOfTheWeek.weekNumber;
            
            if (weekNumber > 0) {
                [string appendFormat:@"%li", (long)weekNumber];
            }
            switch (dayOfWeek) {
                case EKSunday:
                [string appendString:@"SU"];
                break;
                case EKMonday:
                [string appendString:@"MO"];
                break;
                case EKTuesday:
                [string appendString:@"TU"];
                break;
                case EKWednesday:
                [string appendString:@"WE"];
                break;
                case EKThursday:
                [string appendString:@"TH"];
                break;
                case EKFriday:
                [string appendString:@"FR"];
                break;
                case EKSaturday:
                [string appendString:@"SA"];
                break;
            }
            
            
            
            
            i++;
        }
        
        [string appendString:@";"];
    }
    
    
    // Days of the month
    if (daysOfTheMonth && daysOfTheMonth.count) {
        
        [string appendString:@"BYMONTHDAY="];
        
        int i = 0;
        
        for (NSNumber *dayNr in daysOfTheMonth) {
            
            
            if (i > 0) {
                [string appendString:@","];
            }
            
            [string appendString:[NSString stringWithFormat:@"%li", (long)[dayNr integerValue]]];
            
            i++;
        }
        
        [string appendString:@";"];
    }
    
    // Months of the year
    if (monthsOfTheYear && monthsOfTheYear.count) {
        
        [string appendString:@"BYMONTH="];
        
        int i = 0;
        
        for (NSNumber *monthNr in monthsOfTheYear) {
            
            
            if (i > 0) {
                [string appendString:@","];
            }
            
            [string appendString:[NSString stringWithFormat:@"%li", (long)[monthNr integerValue]]];
            
            i++;
        }
        
        [string appendString:@";"];
    }
    
    // Weeks of the year
    if (weeksOfTheYear && weeksOfTheYear.count) {
        
        [string appendString:@"BYWEEKNO="];
        
        int i = 0;
        
        for (NSNumber *weekNr in weeksOfTheYear) {
            
            
            if (i > 0) {
                [string appendString:@","];
            }
            
            [string appendString:[NSString stringWithFormat:@"%li", (long)[weekNr integerValue]]];
            
            i++;
        }
        
        [string appendString:@";"];
    }

        
    // Days of the year
    if (daysOfTheYear && daysOfTheYear.count) {
        
        [string appendString:@"BYYEARDAY="];
        
        int i = 0;
        
        for (NSNumber *dayNr in daysOfTheYear) {
            
            
            if (i > 0) {
                [string appendString:@","];
            }
            
            [string appendString:[NSString stringWithFormat:@"%li", (long)[dayNr integerValue]]];
            
            i++;
        }
        
        [string appendString:@";"];
    }
    
        // Set positions
    if (setPositions && setPositions.count) {
        
        [string appendString:@"BYYEARDAY="];
        
        int i = 0;
        
        for (NSNumber *positionNr in setPositions) {
            
            
            if (i > 0) {
                [string appendString:@","];
            }
            
            [string appendString:[NSString stringWithFormat:@"%li", (long)[positionNr integerValue]]];
            
            i++;
        }
        
        [string appendString:@";"];
    }

   
    
    return string;

}

- (EKEvent*)eventWithRecurrenceRuleFromString:(NSString*)rfc2445String;
{
    EKRecurrenceRule* newRule = [self initWithString:rfc2445String andParseMore:YES];
    EKEvent* newEvent = [[EKEvent alloc] init];
    [newEvent addRecurrenceRule:newRule];
    newEvent.startDate = self.startDate;
    newEvent.endDate = self.endDate;
    
    return newEvent;
}

@end
