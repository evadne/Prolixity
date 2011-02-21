%include {
//
// parser.y
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

    #include "ParserBlock.h"
    #include <assert.h>

    using namespace Prolixity;
    
    #define PROLIXITY_ID_CONCAT_STRING  "$"
    
    namespace Prolixity {
        class InvocationList {
        private:
            std::vector<std::string> methodNameParts;
            ParserBlock argumentExpressions;
            bool hasArgumentExpressions;
        
        public:
            InvocationList() : hasArgumentExpressions(false)
            {
            }
    
            void addMethodNamePart(const std::string& namePart)
            {
                methodNameParts.insert(methodNameParts.begin(), namePart);
            }
        
            void addArgumentExpression(const ParserBlock& exp)
            {
                hasArgumentExpressions = true;
                argumentExpressions.mergeBlock(exp);
                argumentExpressions.addPush();
            }
        
            bool hasArguments() const
            {
                return hasArgumentExpressions;
            }
        
            const std::string combinedMethodName() const
            {
                std::vector<std::string>::size_type mnpSize = methodNameParts.size();
            
                if (!mnpSize) {
                    return std::string();
                }

                std::string result;
            
                if (mnpSize == 1) {
                    result = methodNameParts[0];
                    if (hasArgumentExpressions) {
                        result += ":";
                    }
                    return result;
                }
            
                std::vector<std::string>::size_type i;
                for (i = 0; i < mnpSize - 1 ; i++) {
                    result += methodNameParts[i];
                    result += ":";
                }
            
                result += methodNameParts[i];
                result += ":";
                return result;
            }
        
            const ParserBlock getArgumentExpressions() const
            {
                return argumentExpressions;
            }
        };
    };
}

%extra_argument {ParserBlock *pCurrentBlock}
%left ASSIGN.
%left PLUS MINUS.
%left MUL DIV.

%syntax_error
{
    pCurrentBlock->recordError("Syntax error");
}

%token_type {std::string*}

%token_destructor
{
    delete $$;
}

%token_prefix TOKEN_


%type main {ParserBlock*}
%destructor main { delete $$; }

main ::= statements(Y).
{
    pCurrentBlock->mergeBlock(*Y);
    delete Y;
}


%type statements {ParserBlock*}
%destructor statements { delete $$; }

statements(X) ::= statement(Y).
{
    X = Y;
}

statements(X) ::= statement(Y) terminator statements(Z).
{
    X = Y;
    X->mergeBlock(*Z);
    delete Z;
}


%type statement {ParserBlock*}
%destructor statement { delete $$; }

statement(X) ::= var_statement(Y).
{
    X = Y;
}

statement(X) ::= save_statement(Y).
{
    X = Y;
}

statement(X) ::= assign_statement(Y).
{
    X = Y;
}

statement(X) ::= expression(Y).
{
    X = Y;
}

statement(X) ::= .
{
    X = new ParserBlock;
}

statement(X) ::= error .
{
    X = new ParserBlock;
    X->recordError("Syntax error");
}


%type var_statement {ParserBlock*}
%destructor var_statement { delete $$; }

var_statement(X) ::= VAR identifier(ID).
{
    X = new ParserBlock;
    X->declareVariable(*ID);
    delete ID;
}


%type save_statement {ParserBlock*}
%destructor save_statement { delete $$; }

save_statement(X) ::= SAVE TO identifier(ID) save_statement_tail(TAIL).
{
    X = TAIL;
    X->addStore(*ID);
    delete ID;
}

%type save_statement_tail {ParserBlock*}
%destructor save_statement_tail {delete $$;}

save_statement_tail(X) ::= .
{
    X = new ParserBlock;
}
    
save_statement_tail(X) ::= COMMA expression(EXP).
{
    X = EXP;
}

%type assign_statement {ParserBlock*}
%destructor assign_statement { delete $$; }

assign_statement(X) ::= identifier(ID) ASSIGN expression(EXP).
{
    X = new ParserBlock;
    X->mergeBlock(*EXP);
    X->addStore(*ID);
    delete ID;
    delete EXP;
}


%type expression { ParserBlock* }
%destructor expression { delete $$; }
   
expression(X) ::= invocation(INVOCATION).
{
    X = INVOCATION;
}

expression(X) ::= noninvoke_expression(EXP).
{
    X = EXP;
}


%type noninvoke_expression {ParserBlock*}
%destructor noninvoke_expression {delete $$;}

noninvoke_expression(X) ::= nonprs_expression(Y).
{
    X = Y;
}

noninvoke_expression(X) ::= point_expression(Y).
{
    X = Y;
}

noninvoke_expression(X) ::= size_expression(Y).
{
    X = Y;
}

noninvoke_expression(X) ::= rect_expression(Y).
{
    X = Y;
}

noninvoke_expression(X) ::= range_expression(Y).
{
    X = Y;
}


%type point_expression {ParserBlock*}
%destructor point_expression {delete $$;}

point_expression(E) ::= POINT nonprs_expression(X) COMMA nonprs_expression(Y).
{
    E = new ParserBlock;

    if ((*X).isSimpleNumberExp() && (*Y).isSimpleNumberExp()) {        
        E->addLoadPoint((*X).getSimpleNumber(), (*Y).getSimpleNumber());    
    }
    else {
        E->mergeBlock(*Y);
        E->addPush();    
        E->mergeBlock(*X);
        E->addPush();
        E->addLoad("NSValue");
        E->addInvoke("valueWithCGPointNumberX:numberY:");
    }
    
    delete X;
    delete Y;
}

%type size_expression {ParserBlock*}
%destructor size_expression {delete $$;}

size_expression(E) ::= SIZE nonprs_expression(X) COMMA nonprs_expression(Y).
{
    E = new ParserBlock;

    if ((*X).isSimpleNumberExp() && (*Y).isSimpleNumberExp()) {        
        E->addLoadSize((*X).getSimpleNumber(), (*Y).getSimpleNumber());    
    }
    else {
        E->mergeBlock(*Y);
        E->addPush();    
        E->mergeBlock(*X);
        E->addPush();
        // TODO: Create size
    }
    
    delete X;
    delete Y;
}

%type range_expression {ParserBlock*}
%destructor range_expression {delete $$;}

range_expression(E) ::= RANGE nonprs_expression(X) COMMA nonprs_expression(Y).
{
    E = new ParserBlock;

    if ((*X).isSimpleNumberExp() && (*Y).isSimpleNumberExp()) {        
        E->addLoadRange((*X).getSimpleNumber(), (*Y).getSimpleNumber());    
    }
    else {
        E->mergeBlock(*Y);
        E->addPush();    
        E->mergeBlock(*X);
        E->addPush();
    }
    
    // TODO: Create range
    
    delete X;
    delete Y;
}

%type rect_expression {ParserBlock*}
%destructor rect_expression {delete $$;}

rect_expression(E) ::= RECT point_expression(ORIG) COMMA size_expression(SIZE).
{
    E = new ParserBlock;
    E->mergeBlock(*SIZE);
    E->addPush();
    E->mergeBlock(*ORIG);
    E->addPush();
    
    // TODO: Create rect
    
    delete ORIG;
    delete SIZE;
}

rect_expression(E) ::= RECT nonprs_expression(X1) COMMA nonprs_expression(Y1) COMMA nonprs_expression(X2) COMMA nonprs_expression(Y2).
{
    E = new ParserBlock;

    if ((*X1).isSimpleNumberExp() && (*Y1).isSimpleNumberExp() && (*X2).isSimpleNumberExp() && (*Y2).isSimpleNumberExp()) {
        E->addLoadRect4I((*X1).getSimpleNumber(), (*Y1).getSimpleNumber(), (*X2).getSimpleNumber(), (*Y2).getSimpleNumber());        
    }
    else {
        E->mergeBlock(*Y2);
        E->addPush();    
        E->mergeBlock(*X2);
        E->addPush();
        E->mergeBlock(*Y1);
        E->addPush();    
        E->mergeBlock(*X1);
        E->addPush();
    }

    // TODO: Create rect

    delete X1;
    delete Y1;
    delete X2;
    delete Y2;
}

%type nonprs_expression {ParserBlock*}
%destructor nonprs_expression {delete $$;}

nonprs_expression(X) ::= STRING(STR).
{
    X = new ParserBlock;
    X->addLoadString(*STR);
    delete STR;
}

nonprs_expression(X) ::= NUMBER(NUM).
{
    X = new ParserBlock;
    X->addLoadNumber(*NUM);
    delete NUM;
}

nonprs_expression(X) ::= LEFT_PAREN expression(EXP) RIGHT_PAREN.
{
    X = EXP;
}

nonprs_expression(X) ::= nonprs_expression(Y) PLUS nonprs_expression(Z).
{
    X = new ParserBlock;
    X->mergeBlock(*Z);
    X->addPush();
    X->mergeBlock(*Y);
    X->addInvoke("plus:");
    delete Y;
    delete Z;
}

nonprs_expression(X) ::= nonprs_expression(Y) MINUS nonprs_expression(Z).
{
    X = new ParserBlock;
    X->mergeBlock(*Z);
    X->addPush();
    X->mergeBlock(*Y);
    X->addInvoke("minus:");
    delete Y;
    delete Z;
}

nonprs_expression(X) ::= nonprs_expression(Y) MUL nonprs_expression(Z).
{
    X = new ParserBlock;
    X->mergeBlock(*Z);
    X->addPush();
    X->mergeBlock(*Y);
    X->addInvoke("mul:");
    delete Y;
    delete Z;
}

nonprs_expression(X) ::= nonprs_expression(Y) DIV nonprs_expression(Z).
{
    X = new ParserBlock;
    X->mergeBlock(*Z);
    X->addPush();
    X->mergeBlock(*Y);
    X->addInvoke("div:");
    delete Y;
    delete Z;
}



nonprs_expression(X) ::= identifier(ID).
{
    X = new ParserBlock;
    X->addLoad(*ID);
    delete ID;
}
    
nonprs_expression(X) ::= block(BLK).
{
    X = new ParserBlock;
    X->addBlock(*BLK);
    X->addLoad(BLK->getName());
    delete BLK;
}

    
%type invocation {ParserBlock*}
%destructor invocation { delete $$; }

invocation(X) ::= optional_on(EXP) INVOKE identifier(NAME_HEAD) invocation_tail(TAIL).
{
    X = new ParserBlock;

    TAIL->addMethodNamePart(*NAME_HEAD);

    // if there are other "taking" clauses, we need to save the last value to a temp var first
    bool needTempVar = TAIL->hasArguments();
    std::string tempVar;
    if (!EXP && needTempVar) {
        tempVar = X->obtainTempVar();
        X->addStore(tempVar);
    }
    
    X->mergeBlock(TAIL->getArgumentExpressions());
    
    if (EXP) {
        X->mergeBlock(*EXP);
    }
    else if (needTempVar) {
        X->addLoad(tempVar);
    }
    
    X->addInvoke(TAIL->combinedMethodName());
    
    if (EXP) {
        delete EXP;
    }

    delete NAME_HEAD;
    delete TAIL;
}


%type optional_on {ParserBlock*}
%destructor optional_on { delete $$; }

optional_on(X) ::= .
{
    X = 0;
}

optional_on(X) ::= ON noninvoke_expression(EXP) COMMA.
{
    X = EXP;    
}


%type invocation_tail {InvocationList*}
%destructor invocation_tail { delete $$; }

invocation_tail(X) ::= COMMA taking_part(PART).
{
    X = PART;
}
    
invocation_tail(X) ::= .
{
    X = new InvocationList;
}


%type taking_part {InvocationList*}
%destructor taking_part { delete $$; }

taking_part(X) ::= TAKING noninvoke_expression(Y) taking_tail(Z).
{
    X = Z;
    X->addArgumentExpression(*Y);
    delete Y;
}


%type taking_tail {InvocationList*}
%destructor taking_tail { delete $$; }

taking_tail(X) ::= .
{
    X = new InvocationList;
}

taking_tail(X) ::= COMMA AND identifier(NAME_PART) invocation_tail(Z).
{
    X = Z;
    X->addMethodNamePart(*NAME_PART);
    delete NAME_PART;
}


%type block {ParserBlock*}
%destructor block { delete $$; }

block(X) ::= BEGIN ELLIPSIS statements(ST) ELLIPSIS END.
{
    X = ST;
    X->obtainName();
}

terminator ::= LF.
terminator ::= PERIOD.

%type identifier {std::string*}
%destructor identifier { delete $$; }

identifier(X) ::= IDENTIFEME(IDSTR).
{ 
    X = IDSTR;
}

identifier(X) ::= identifier(ID) IDENTIFEME(IDSTR).
{
    X = ID;
    *X += PROLIXITY_ID_CONCAT_STRING;
    *X += *IDSTR;
    delete IDSTR;
}
