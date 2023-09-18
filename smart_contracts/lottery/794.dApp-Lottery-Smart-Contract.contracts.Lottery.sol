pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";

contract Lottery is AccessControl{
    
    IERC20 public ERC20Token;

    bytes32 public constant OWNER = keccak256("OWNER_ROLE");
    bytes32 public constant MANAGER = keccak256("MANAGER_ROLE");
    uint public managers;

    uint public entryFee;
    uint public poolContributionBasis;
    uint public ownerFeeBasis;
    uint public poolContribution;
    uint public ownerFee;
    uint public constant cooldown = 300;
    
    uint public last_drawn;
    uint public lotteriesCount;
    uint public pool;
    uint public fees;

    address public winner;
    address[] public players;
    

    constructor(address _tokenAddress, uint _entryFee, uint _poolContributionBasis, uint _ownerFeeBasis) public {
        require((_poolContributionBasis + _ownerFeeBasis == 10000), "Incorrect basis points!");
        ERC20Token = IERC20(_tokenAddress);
        entryFee = _entryFee;
        poolContributionBasis = _poolContributionBasis;
        ownerFeeBasis = _ownerFeeBasis;

        poolContribution = SafeMath.div(SafeMath.mul(entryFee, poolContributionBasis), 10000);
        ownerFee = SafeMath.div(SafeMath.mul(entryFee, ownerFeeBasis), 10000);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER, msg.sender);
        _setRoleAdmin(OWNER, DEFAULT_ADMIN_ROLE);

    }
    

    modifier isOwner(){
        require(hasRole(OWNER, msg.sender), "Caller is not the OWNER");
        _;
    }

    modifier offCooldown(){
        require((block.timestamp > (last_drawn + cooldown)), "This function is on cooldown!");
        _;
    }

    modifier hasAccess(){
        require((hasRole(OWNER, msg.sender) || hasRole(MANAGER, msg.sender)), "Caller does not have permission to do this!");
        _;
    }
    


    function addManager(address managerAddress) public isOwner {
        require(managers < 2, "Too many managers!");
        require(!hasRole(MANAGER, managerAddress), "User is already manager!");
        grantRole(MANAGER, managerAddress);
        managers++;
    }

    function removeManager(address managerAddress) public isOwner {
        require(hasRole(MANAGER, managerAddress), "User is not a manager!");
        revokeRole(MANAGER, managerAddress);
        managers--;
    }



    function enter() public {
        ERC20Token.transferFrom(msg.sender, address(this), entryFee * 10**18);
        pool += poolContribution;
        fees += ownerFee;
        players.push(msg.sender);
    }
    
    function random(uint nonce) private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce)));
    }
    
    function pickWinner() public hasAccess offCooldown {        
        uint index = random(players.length) % players.length;
        winner = players[index];
        last_drawn = block.timestamp;
    }

    function withdraw() public isOwner {
        ERC20Token.approve(address(this), fees * 10**18);
        ERC20Token.transferFrom(address(this), msg.sender, fees * 10**18);
        fees = 0;
    }

    function payout() public isOwner {
        ERC20Token.approve(address(this), pool * 10**18);
        ERC20Token.transferFrom(address(this), winner, pool * 10**18);
        delete players;
        winner = address(0);
        pool = 0;
    }

    function changeEntry(uint fee, uint poolBasis, uint ownerBasis) public isOwner {
        require((poolBasis + ownerBasis) == 10000, "Basis points do not add up to 10000");
        entryFee = fee;
        poolContributionBasis = poolBasis;
        ownerFeeBasis = ownerBasis;
        poolContribution = SafeMath.div(SafeMath.mul(entryFee, poolContributionBasis), 10000);
        ownerFee = SafeMath.div(SafeMath.mul(entryFee, ownerFeeBasis), 10000);
    }
}