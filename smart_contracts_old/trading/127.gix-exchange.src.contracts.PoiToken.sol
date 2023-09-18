pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PoiToken is ERC20 {
    constructor () public ERC20("Poi Token", "POI") {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
}
// contract PoiToken {
    
//     string public name = "Poi Token";
//     string public symbol = "POI";
//     string public standard = "Poi Token v2.0";
//     uint256 public totalSupply = 1000000000000000000000000;
//     uint8 decimals = 18;
    
//     event Transfer(
//         address indexed _from,
//         address indexed _to,
//         uint256 _value
//     );

//     event Approval(
//         address indexed _owner,
//         address indexed _spender,
//         uint256 _value
//     );
//     mapping(address => uint256) public balanceOf;
//     mapping(address => mapping(address => uint256)) public allowance;
    
//     // constructor (uint256 _initialSupply) {
//     //     balanceOf[msg.sender] = _initialSupply;
//     //     totalSupply = _initialSupply;
//     //     // allocate initial supply
//     // }
//     constructor(){
//         balanceOf[msg.sender] = totalSupply;
//     }
//     function transfer(address _to, uint256 _value) public returns (bool success){
//         // Throw exception if account doesn't have enough tokens
//         require(balanceOf[msg.sender] >= _value);
//         balanceOf[msg.sender] -= _value;
//         balanceOf[_to] += _value;

//         emit Transfer(msg.sender, _to, _value);
//         return true;
//     }

//     function approve(address _spender, uint256 _value) public returns (bool success){
//         allowance[msg.sender][_spender] = _value;
//         emit Approval(msg.sender, _spender, _value);
//         return true;
//     }

//     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
//         require(balanceOf[_from] >= _value);
//         require (_value <= allowance[_from][msg.sender]);

//         balanceOf[_from] -= _value;
//         balanceOf[_to] += _value;

//         allowance[_from][msg.sender] -= _value;

//         emit Transfer(_from, _to, _value);
//         return true;
//     }
// }