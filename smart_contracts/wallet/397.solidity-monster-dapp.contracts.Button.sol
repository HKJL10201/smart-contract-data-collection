pragma solidity >=0.4.21 <0.7.0;

contract Button {
    Monster[] public monsters; 
    mapping (address => uint) public ownerToMonsterId; 
    mapping (address => bool) public ownerHasMonster;

    function createMonster(string calldata _name) external {
        Monster memory newMonster = Monster(_name, 0);
        monsters.push(newMonster);
        ownerHasMonster[msg.sender] = true;
        ownerToMonsterId[msg.sender] = monsters.length - 1;
    }

    function levelUp(uint monsterId) external {
        monsters[monsterId].level++;
    }

    function getOwnerHasMonster(address owner) external view returns (bool) {
        return ownerHasMonster[owner];
    }

    function getOwnersMonsterId(address owner) external view returns (uint) {
        return ownerToMonsterId[owner];
    }

    struct Monster {
        string name;
        uint level;
    }
}