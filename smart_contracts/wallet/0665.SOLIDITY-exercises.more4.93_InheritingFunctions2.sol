//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract A {
    /*We can call a parent function from child contract.
    For that functions must be declared as "public". 
    Way 1 and 3 is only for understanding the topic. This function calling
    is actually used for events(Way-2). */
    
    //WAY-1: write functions
    string public myword = "something";
    function baz() public virtual {
        myword = "something A";
    }
    //WAY-2.1: events
    event Log(string mytext);
    function foo() public virtual {
        emit Log("hello from A");
    }

    //WAY-2.2: events
    event Log2(string mytext);
    function foo2() public virtual {
        emit Log2("hello from A");
    }

    //WAY-3: return functions
    function bar() public pure virtual returns(string memory) {
        return "good evening from A";
    }
}

contract B is A{
    //WAY-3
    function bar() public pure override returns(string memory) {
        A.bar();
        return "good evening from B";
    }

    //WAY 1
    function baz() public override {
        myword = "something B";
        A.baz();
    }

    //WAY 2.1
    function foo() public override {
        emit Log("hello from B");
        A.foo();
    }

    // WAY 2.2
    function foo2() public override {
        emit Log2("hello from B");
        super.foo();
    }

    /* super.foo() and A.foo() are the same. super is more handy because it allows us to access 
    all contracts that we inherit(imageine we are inheriting from 3 contracts instead of just A.
    So, instead of writing the name of the contract each single time, I can just say "super" */
}
