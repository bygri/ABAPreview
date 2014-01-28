//
//  MyDocument.m
//  ABA Preview
//
//  Created by Toby Griffin on 15/02/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	fileContents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (!fileContents)
		return NO;
	
	// Make some reusables
	records = [[NSMutableArray alloc] initWithCapacity:1];
	NSCharacterSet *zeroSet = [NSCharacterSet characterSetWithCharactersInString:@"0"];
	NSArray *headerFieldsKeys = [NSArray arrayWithObjects:
								 @"reelSequence",
								 @"financialInstitution",
								 @"userName",
								 @"userNumber",
								 @"description",
								 @"dateToProcess",
								 nil];
	NSArray *valueFieldKeys = [NSArray arrayWithObjects:
							   @"BSB",
							   @"accountNumber",
							   @"indicator",
							   @"transactionCode",
							   @"amount",
							   @"accountName",
							   @"reference",
							   @"traceBSB",
							   @"traceAccountNumber",
							   @"remitterName",
							   @"withholdingTax",
							   nil];
	NSArray *footerFieldsKeys = [NSArray arrayWithObjects:
								@"netAmount",
								@"creditAmount",
								@"debitAmount",
								@"numberOfRecords",
								nil];
	
	// Split the source file up by lines
	NSArray *fileRecords = [fileContents componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
	
	NSEnumerator *enumerator = [fileRecords objectEnumerator];
	NSString *currentRecord;
	NSString *recordType;
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"ddMMyy"];
	
	while (currentRecord = [enumerator nextObject])
	{
		// check record type and switch based on that
		if ([currentRecord length] > 0)
		{
			recordType = [currentRecord substringToIndex: 1];
			NSLog(@"record type: %@", recordType);
			if ([recordType isEqual:@"0"])
			{
				NSLog(@"header");
				// It's a header
				NSArray *headerFieldsValues = [NSArray arrayWithObjects:
											   [[currentRecord substringWithRange:NSMakeRange(18, 2)] stringByTrimmingCharactersInSet: zeroSet],
											   [currentRecord substringWithRange:NSMakeRange(20, 3)],
											   [[currentRecord substringWithRange:NSMakeRange(30, 26)] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]],
											   [currentRecord substringWithRange:NSMakeRange(56, 6)],
											   [[currentRecord substringWithRange:NSMakeRange(62, 12)] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]],
											   [dateFormatter dateFromString: [currentRecord substringWithRange:NSMakeRange(74, 6)]],	// Processing date
											   nil];
				headerFields = [NSDictionary dictionaryWithObjects: headerFieldsValues
														   forKeys: headerFieldsKeys];
				NSLog(@"header done");
			}
			else if ([recordType isEqual:@"1"])
			{
				// it's a transaction row
				NSLog(@"trans");
				NSArray *recordValues = [NSArray arrayWithObjects:
										 [currentRecord substringWithRange: NSMakeRange(1, 7)],		// BSB
										 [[currentRecord substringWithRange: NSMakeRange(8, 9)] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]],		// Account number
										 [currentRecord substringWithRange: NSMakeRange(17, 1)],	// indicator
										 [currentRecord substringWithRange: NSMakeRange(18, 2)],	// transaction code
										 [NSNumber numberWithFloat:[[currentRecord substringWithRange: NSMakeRange(20, 10)] floatValue] / 100],	// amount
										 [[currentRecord substringWithRange: NSMakeRange(30, 32)] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]],	// account name
										 [[currentRecord substringWithRange: NSMakeRange(62, 18)] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]],	// reference
										 [currentRecord substringWithRange: NSMakeRange(80, 7)],	// trace bsb
										 [[currentRecord substringWithRange: NSMakeRange(87, 9)] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]],	// trace account
										 [[currentRecord substringWithRange: NSMakeRange(96, 16)] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]],	// remitter name
										 [NSNumber numberWithFloat:[[currentRecord substringWithRange: NSMakeRange(112, 8)] floatValue] / 100],	// withholding tax
										 nil];
				[records addObject: [NSDictionary dictionaryWithObjects: recordValues
																forKeys: valueFieldKeys]];
			}
			else if ([recordType isEqual:@"7"])
			{
				// it's a footer
				NSArray *footerFieldsValues = [NSArray arrayWithObjects:
											  [NSNumber numberWithFloat:[[currentRecord substringWithRange: NSMakeRange(20, 10)] floatValue] / 100],
											  [NSNumber numberWithFloat:[[currentRecord substringWithRange: NSMakeRange(30, 10)] floatValue] / 100],
											  [NSNumber numberWithFloat:[[currentRecord substringWithRange: NSMakeRange(40, 10)] floatValue] / 100],
											  [NSNumber numberWithInt:[[currentRecord substringWithRange: NSMakeRange(74, 6)] intValue]],
											  nil];
				footerFields = [NSDictionary dictionaryWithObjects: footerFieldsValues
														   forKeys: footerFieldsKeys];
			}
		}
	}
	return YES;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	NSParameterAssert(rowIndex >= 0 && rowIndex < [records count]);
	return [[records objectAtIndex:rowIndex] objectForKey:[tableColumn identifier]];
}
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [records count];
}
@end
