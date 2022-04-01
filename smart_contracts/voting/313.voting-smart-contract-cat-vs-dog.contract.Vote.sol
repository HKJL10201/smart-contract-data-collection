pragma solidity ^0.8.1;

contract Vote {
    
    uint256 private cats = 0;
    uint256 private dogs = 0;
    
    function vote(uint256 catOrDog) public {
        /**
         * if catOrDog == 0, then the user is voting for cat
         * if catOrDog == 1, then the user is voting for dog
         */
         
        require(catOrDog < 2, "invalid input!!");
         
        if(catOrDog == 0) {
            cats++;
        }
        else if(catOrDog == 1) {
            dogs++;
        }
    }
    
    function winner() public view returns(string memory) {
        if(cats > dogs) {
            return "CATS";
        }
        else if(dogs > cats) {
            return "DOGS";
        }
        return "DRAW";
    }
    
}
