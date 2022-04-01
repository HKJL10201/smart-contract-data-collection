pragma solidity >=0.8.7;
import "./SafeMath.sol";

contract BasicMath {

    using SafeMath for uint256;

    uint256 public variable_add = 50;
    uint256 public variable_div = 50;
    uint256 public variable_sub = 50;
    uint256 public variable_mul = 50;
    uint256 public variable_mod = 50;

    function basicMath() public { // I can add *return* here but it works without it
        variable_add = variable_add.add(9);
        variable_div = variable_div.div(9);
        variable_mul = variable_mul.mul(9);
        variable_sub = variable_sub.sub(9);
        variable_mod = variable_mod % 9;
        // I can add *return* here but it doesnt change anything
    }

}