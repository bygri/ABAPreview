//
//  MyDocument.h
//  ABA Preview
//
//  Created by Toby Griffin on 15/02/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@interface MyDocument : NSDocument
{
	NSString *fileContents;
	
	NSDictionary *headerFields;
	NSMutableArray *records;
	NSDictionary *footerFields;
}

@end
