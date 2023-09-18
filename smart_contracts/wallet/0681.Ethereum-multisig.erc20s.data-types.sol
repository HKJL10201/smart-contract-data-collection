pragma solidity 0.7.5;

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------


/* // 01. DEFINE VARIABLES

int x = 3;  //signed integer
uint ui = 2 ; // unsigned integers (only positive numbers)
string c = "escupe en la chota";
bool b = false;
address ad = mk57Q%Aahaer%&Q@00dDh%agtYJR

*/

*/ // 02. BASICS

contract JohnSalchichon {
    
    string message;
    
    constructor(string memory x_message){
        message = x_message;
    }
    
    function hello() public view returns(string memory){
        if(msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4){
            return "stake your ETH";
        }
        else{
            return message;
        }
        
    }
    
    function hello2() public pure returns(string memory){
        string memory mss = "huele a poto";
        return mss;
    }
}

*/

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------


/* // 03. LOOOPS
contract loops {
    function while_loop(int n) public pure returns(int){
        int i = 0;
        while(i <= 13){
            n = n+1;
            i = i+1;
        }
        return n;
    }
    
    function for_loop(int n) public pure returns(int){
        for(int i=0;i<=10;i++){
            n++;
        }
        return n;
    }
}
    
*/

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------


/* // 04. ARRAYS

contract arrays{
    int num;
    int[7] arr_fix; // fized sized array of 7 elements
    int[] arr;
    
    function add_elem(int nn) public {
        arr.push(nn);                     // similar to python append
    }
    
    function get_elem(uint idd) public view returns(int){
        return arr[idd];                   // get element of the created array
    }
    
    function get_arr() public view returns(int[] memory){
        return arr;                        // get entire array
    }
}

*/

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

*/ // 05. STRUCTURES (similar to python class)

contract structures{
    
    struct person{
        uint age;
        string name;
        int revenue;
    }
    
    person[] PS;
    
    function add_person(uint age_i, string memory name_i, int revenue_i) public {
        person memory new_person = person(age_i, name_i, revenue_i);
        PS.push(new_person);
    }
    
    function get_person(uint idx) public view returns(uint, string memory, int){
        person memory person2return = PS[idx];
        return (person2return.age, person2return.name, person2return.revenue);
    }
}
*/

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------


/* // 06. MAPPINGS (similar to Python dictionaries)


contract mappings{
    
    mapping(address => uint) balance;   // maps 
    
    function add_balance(uint add2) public returns(uint){
        balance[msg.sender] += add2;
        return balance[msg.sender];
    }
    
    function get_balance() public  view returns(uint){
        return balance[msg.sender];
    }
        
}

*/

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

/* // 06. ASSERT & REQUIRE

 contract banking{
    
    mapping(address => uint) balance;   // maps 
    address owner;
    

    // add balance to an address and update
    function add_balance(uint add2) public returns(uint){
        balance[msg.sender] += add2;
        return balance[msg.sender];
    }
    
    // get the current balance of  an address
    function get_balance() public  view returns(uint){
        return balance[msg.sender];
    }
        
    // this function is PRIVATE!! can only be called from this contract,
    // substracts amount from sender and adds it to receipent
    function transfer_funds(address from, address to, uint amount) private{
        balance[from] -= amount;
        balance[to] += amount;
    }
    
    // 
    function transfer(address receipent, uint amount) public{
        require(balance[msg.sender] >= amount, "balance isn't enough");   // verify that the sender has enough money
        require(receipent != msg.sender, "can't transfer to yourself");         // verify that the sender doesn't auto-transfer
        
        uint previous_balance = balance[msg.sender];
        
        // call the ohter function called: transfer_funds
        transfer_funds(msg.sender, receipent, amount);
        
        // assert: checks that conditions are met
        assert(balance[msg.sender]  == previous_balance - amount);
    }
}


*/
	


----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------


/*  // 07. MODIFIERS & CONSTRUCTORS


contract banking{
    
    mapping(address => uint) balance;   // maps 
    address owner;
    
    
    // modifier: restricst access to whatever meets conditions
    modifier onlyVIP {
        require(msg.sender == owner);
        _;   // underscore (;) means to run the function
    }
    
    modifier _cost_(uint gas_cost) {
        require(balance[msg.sender] >= gas_cost);
        _;
    }
    
    
    //constructor: constructs conditions for modifiers
    constructor() {
        owner == msg.sender;
    }

    // add balance to an address and update
    function add_balance(uint add2) public onlyVIP returns(uint){
        balance[msg.sender] += add2;
        return balance[msg.sender];
    }
    
    // get the current balance of  an address
    function get_balance() public  view returns(uint){
        return balance[msg.sender];
    }
        
    // this function is PRIVATE!! can only be called from this contract,
    // substracts amount from sender and adds it to receipent
    function transfer_funds(address from, address to, uint amount) private{
        balance[from] -= amount;
        balance[to] += amount;
    }
    
    // 
    function transfer(address receipent, uint amount) public _cost_(50) {
        require(balance[msg.sender] >= amount, "balance isn't enough");   // verify that the sender has enough money
        require(receipent != msg.sender, "can't transfer to yourself");         // verify that the sender doesn't auto-transfer
        
        uint previous_balance = balance[msg.sender];
        
        // call the ohter function called: transfer_funds
        transfer_funds(msg.sender, receipent, amount);
        
        // assert: checks that conditions are met
        assert(balance[msg.sender]  == previous_balance - amount);
    }
}


*/


