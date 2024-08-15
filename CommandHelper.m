/*
 * Copyright (c) 2006-2016 Hiroto Sakai
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "CommandHelper.h"
#import "PreferenceHelper.h"
#import "64bitTransition.h"

#ifdef DEBUG
#define CommandName @"lha_debug"
#else
#define CommandName @"lha"
#endif

@interface CommandHelper(Private)
- (NSString *)initDestination;
- (NSString *)outputPath;
- (BOOL)isDestinationValid:(NSString *)destination;
- (NSString *)temporaryDestination;
@end

@implementation CommandHelper

- (id)initWithFiles:(NSArray *)filenames
{
    if (self = [super init]) {
        args = [[NSArray alloc] initWithArray:filenames];
        destination = [[NSMutableString alloc] initWithString:[self initDestination]];
    }
    return self;
}

- (void)dealloc
{
    [destination release];
    [args release];
    [super dealloc];
}

- (NSArray *)commandLine
{
    NSMutableArray *cmd;
    NSString *outputPath = [self outputPath];

    // lha xfgw=/hoge/Archive --extract-broken-archive /foo/bar/Archive.lzh
    if (outputPath != nil) {
        cmd = [NSMutableArray arrayWithObject:[self commandPath]];
        [cmd addObjectsFromArray:[self commandOption]];
        [cmd addObjectsFromArray:args];
        return cmd;
    }

    return nil;
}

// return lha command path
- (NSString *)commandPath
{
    return [[[NSBundle mainBundle] resourcePath]
              stringByAppendingPathComponent:CommandName];
}

- (NSArray *)argsWithoutDirectory
{
    int i;
    NSMutableArray *array = [NSMutableArray array];

    for (i=0; i<[args count]; i++) {
        [array addObject:[[args objectAtIndex:i] lastPathComponent]];
    }

    return array;
}

// return lha's option
- (NSArray *)commandOption
{
    NSMutableString *option;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *options;

    option = [NSMutableString stringWithString:@"xfg"];

    if ([defaults boolForKey:@"DecodeMacBinary"]) {
        [option appendString:@"b"];
    }

    [option appendString:@"w="];
    [option appendString:[self outputPath]];

    options = [NSMutableArray arrayWithObject:option];

    [options addObject:@"--extract-broken-archive"];

    return options;
}

- (NSString *)processingItem
{
    return [[args objectAtIndex:0] lastPathComponent];
}

- (NSString *)destination
{
    return destination;
}

- (void)setDestination:(NSString *)path
{
    [destination setString:path];
}

- (NSString *)workingDirectory
{
    // return location of dropped items
    return [[args objectAtIndex:0] stringByDeletingLastPathComponent];
}

#pragma private

- (NSString *)initDestination
{
    NSString *path;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    switch ([defaults integerForKey:@"DestinationType"]) {
    case DestinationTypeSameAsOriginal:
        path = [[args objectAtIndex:0] stringByDeletingLastPathComponent];
        break;
    case DestinationTypeUse:
        path = [defaults stringForKey:@"DestinationDir"];
        break;
    case DestinationTypeDesktop:
        path = [[NSString stringWithString:NSHomeDirectory()]
                    stringByAppendingPathComponent:@"Desktop"];
        break;
    default:
        path = @"";
        break;
    }
    
    if ([self isDestinationValid:path]) {
        return path;
    } else {
        return @"";
    }
}

- (NSString *)outputPath
{
    NSString *dest;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([self isDestinationValid:[self destination]]) {
        dest = [self destination];
    } else {
        dest = [self temporaryDestination];
    }

    if ([defaults boolForKey:@"doNotCreateFolder"]) {
        return dest;
    } else {
        return [dest stringByAppendingPathComponent:[[[args objectAtIndex:0] lastPathComponent] stringByDeletingPathExtension]];
    }
}

- (BOOL)isDestinationValid:(NSString *)path
{
    NSFileManager *manager;
    BOOL isDir;

    manager = [NSFileManager defaultManager];
    if ([path length] < 1)
        return false;
    if (![manager fileExistsAtPath:path isDirectory:&isDir] || !isDir)
        return false;
    if (![manager isWritableFileAtPath:path])
        return false;

    return true;
}

- (NSString *)temporaryDestination
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSInteger rc;

    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:YES];

    rc = [panel runModalForTypes:nil];
    if (rc == NSOKButton) {
        return [panel filename];
    } else {
        return @"";
    }

    return nil;
}

@end
