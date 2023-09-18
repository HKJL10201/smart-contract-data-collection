//SPDX-Licence-Identifier: MIT

pragma solidity >=0.8.7;

contract EnumExample {
    enum BurgerSizes {
        CHILDREN, 
        SIZE1, 
        SIZE2, 
        SIZE3
    };
    
    BurgerSizes choice;
    BurgerSizes constant defaultchoice = BurgerSizes.SIZE2;

    function setLarge() external {
        choice = BurgerSizes.SIZE3;
    }
    function setMedium() external {
        choice = BurgerSizes.SIZE2;
    }
    function getSize() external view returns(BurgerSizes) {
        return choice;
    }
    function getDefaultSize() external pure returns(BurgerSizes) {
       return defaultchoice;
    }
}