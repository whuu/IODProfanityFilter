//
//  IODProfanityFilter.m
//  IODProfanityFilter
//
//  Created by John Arnold on 2013-02-27.
//  Copyright (c) 2013 Island of Doom Software Inc. All rights reserved.
//

#import "IODProfanityFilter.h"

@implementation IODProfanityFilter

static NSMutableSet *IODProfanityFilterWordSet;
static NSMutableSet *IODProfanityFilterWordWithSpaceSet;

+ (NSSet*)wordSet
{
    // Load up our word list and keep it around
    if (!IODProfanityFilterWordSet && !IODProfanityFilterWordWithSpaceSet)
    {
        NSStringEncoding encoding;
        NSError *error;
        NSString *fileName = [[NSBundle mainBundle] pathForResource:@"IODProfanityWords" ofType:@"txt"];
        NSString *wordStr = [NSString stringWithContentsOfFile:fileName usedEncoding:&encoding error:&error];
        NSArray *wordArray = [wordStr componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        IODProfanityFilterWordSet = [NSMutableSet new];
        IODProfanityFilterWordWithSpaceSet = [NSMutableSet new];
        
        for (NSString* word in wordArray){
            if ([word rangeOfString:@" "].location == NSNotFound)
                [IODProfanityFilterWordSet addObject:word];
            else
                [IODProfanityFilterWordWithSpaceSet addObject:word];
        }
    }
    return [[NSSet setWithSet:IODProfanityFilterWordSet] setByAddingObjectsFromSet:IODProfanityFilterWordWithSpaceSet];
}

+ (void) addWordsFromSet:(NSSet *)set{
    for (NSString* word in set){
        if ([word rangeOfString:@" "].location == NSNotFound)
            [IODProfanityFilterWordSet addObject:word];
        else
            [IODProfanityFilterWordWithSpaceSet addObject:word];
    }
}

+ (void) removeWordsFromSet:(NSSet *)set{
    for (NSString* word in set){
        if ([word rangeOfString:@" "].location == NSNotFound)
            [IODProfanityFilterWordSet removeObject:word];
        else
            [IODProfanityFilterWordWithSpaceSet removeObject:word];
    }
}

+ (void) resetWordSetForAllLanguages:(BOOL)allLanguages{
    NSStringEncoding encoding;
    NSError *error;
    IODProfanityFilterWordSet = nil;
    IODProfanityFilterWordWithSpaceSet = nil;
    
    if (allLanguages) {
        IODProfanityFilterWordSet = [NSMutableSet new];
        IODProfanityFilterWordWithSpaceSet = [NSMutableSet new];
        for (NSString *language in [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"]) {
            NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:language ofType:@"lproj"]];
            if (bundle == nil)
                continue;
            NSString *fileName = [bundle pathForResource:@"IODProfanityWords" ofType:@"txt"];
            NSString *wordStr = [NSString stringWithContentsOfFile:fileName usedEncoding:&encoding error:&error];
            NSArray *wordArray = [wordStr componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            for (NSString* word in wordArray){
                if ([word rangeOfString:@" "].location == NSNotFound)
                    [IODProfanityFilterWordSet addObject:word];
                else
                    [IODProfanityFilterWordWithSpaceSet addObject:word];
            }
        }
    }else
        [self wordSet];
}

+ (NSArray*)rangesOfFilteredWordsInString:(NSString*)string
{
    NSMutableArray *result = [NSMutableArray array];
    
    if (!IODProfanityFilterWordSet && !IODProfanityFilterWordWithSpaceSet)
    {
        [self wordSet];
    }
    NSSet *wordSet = IODProfanityFilterWordSet;
    NSSet *wordWithSpaceSet = IODProfanityFilterWordWithSpaceSet;
    
    NSCharacterSet *wordCharacters = [NSCharacterSet alphanumericCharacterSet];
    NSCharacterSet *nonWordCharacters = [wordCharacters invertedSet];
    
    //check words containing spaces:
    for (NSString *word in wordWithSpaceSet) {
        NSRange range = [string rangeOfString:word options:NSCaseInsensitiveSearch];
        while (range.location != NSNotFound){
            //check if it's not part of the other word
            BOOL leadAreChars = NO;
            BOOL tailAreChars = NO;
            NSString *leadSubStr = nil;
            NSString *tailSubStr = nil;
            
            if (range.location > 0)
                leadSubStr = [string substringWithRange:NSMakeRange(range.location-1, 1)];
            if (range.location+range.length < string.length)
                tailSubStr = [string substringWithRange:NSMakeRange(range.location+range.length, 1)];
            
            if (leadSubStr.length > 0 && [leadSubStr rangeOfCharacterFromSet:wordCharacters].location != NSNotFound)
                leadAreChars = YES;
            if (tailSubStr.length > 0 && [tailSubStr rangeOfCharacterFromSet:wordCharacters].location != NSNotFound)
                tailAreChars = YES;
            
            if (!leadAreChars && !tailAreChars){
                [result addObject:[NSValue valueWithRange:range]];
                //whole string is offending, return its range
                if (range.location == 0 && range.length == string.length)
                    return result;
            }
            NSRange nextRange = NSMakeRange(range.location+range.length, string.length - (range.location+range.length));
            range = [string rangeOfString:word options:NSCaseInsensitiveSearch range:nextRange];
        }
    }
    
    //check words without spaces:
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = nil;
    while (![scanner isAtEnd])
    {
        // Look for words
        NSString *scanned;
        if ([scanner scanCharactersFromSet:wordCharacters intoString:&scanned]) {
            
            // Found a word, look it up in the word set
            if ([wordSet containsObject:[scanned lowercaseString]])
            {
                // The scan location is now at the end of the word
                NSRange range = NSMakeRange(scanner.scanLocation - scanned.length, scanned.length);
                [result addObject:[NSValue valueWithRange:range]];
            }
        }
        else
        {
            // Skip over non-word characters
            [scanner scanCharactersFromSet:nonWordCharacters intoString:&scanned];
        }
    }
    
    return result;
}

+ (NSString *)stringByFilteringString:(NSString *)string
{
    return [self stringByFilteringString:string withReplacementString:@"∗"];
}

+ (NSString*)stringByFilteringString:(NSString *)string withReplacementString:(NSString *)replacementString
{
    NSMutableString *result = [string mutableCopy];
    
    NSArray *rangesToFilter = [self rangesOfFilteredWordsInString:string];
    for (NSValue *rangeValue in rangesToFilter) {
        NSRange range = [rangeValue rangeValue];
        NSString *replacement = [@"" stringByPaddingToLength:range.length withString:replacementString startingAtIndex:0];
        [result replaceCharactersInRange:range withString:replacement];
    }
    
    return result;
}

@end
