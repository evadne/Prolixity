//
// PXBlock.h
//
// Copyright (c) 2011 Lukhnos D. Liu (http://lukhnos.org)
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>

@class PXBlock;

@interface NSObject (PXSupport)
- (void)dump;
@end

@interface NSNumber (PXSupport)
- (NSNumber *)plus:(NSNumber *)inNumber;
- (NSNumber *)mul:(NSNumber *)inNumber;
- (NSNumber *)gt:(NSNumber *)inNumber;
- (NSNumber *)lt:(NSNumber *)inNumber;
- (id)ifTrue:(PXBlock *)inBlock;
- (id)ifFalse:(PXBlock *)inBlock;
@end


@interface NSValue (PXSupport)
+ (NSValue *)valueWithCGPointNumberX:(NSNumber *)x numberY:(NSNumber *)y;
@end

@interface PXBlock : NSObject
{
    NSString *name;
    PXBlock *parent;
    
    id tempValue;
    NSMutableArray *stack;
    NSMutableDictionary *variables;
    NSMutableArray *instructions;
}

+ (NSMutableString *)currentConsoleBuffer;
+ (PXBlock *)blockWithSource:(NSString *)inSource;
+ (PXBlock *)blockWithBlockAssembly:(NSString *)inAsm;
- (id)runWithParent:(PXBlock *)inParent;

- (void)declareVariable:(NSString *)inName;
- (void)exportObject:(id)object toVariable:(id)varName;

- (void)addLoadImmeidate:(id)inObject;
- (void)addLoad:(NSString *)inName;
- (void)addStore:(NSString *)inName;
- (void)addPush;
- (void)addPop;
- (void)addInvoke:(SEL)inSelector;



@property (readonly) NSString *name;
@end


@interface PXLexemeBuilder : NSObject
{
@private
    NSMutableDictionary *synonymMap;
    NSMutableDictionary *directTermMap;
}

- (void)addSynonym:(NSString *)inSynonym forTerm:(NSString *)inTerm;
- (void)addObjectiveCMethod:(SEL)inSelector;
- (void)addObjectiveCClass:(Class)inClass;

- (NSSet *)synonymsForTerm:(NSString *)inTerm;
- (NSArray *)candidateLexemesFromParts:(NSArray *)inParts;
@end
