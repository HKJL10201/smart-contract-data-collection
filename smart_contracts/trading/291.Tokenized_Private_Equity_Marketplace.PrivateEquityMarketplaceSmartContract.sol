pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

// import ERC721 from OpenZeppelin
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import ERC721Enumerable from OpenZeppelin
import "../ERC721.sol";
// import ERC721Burnable from OpenZeppelin
import "../extensions/ERC721Enumerable.sol";
// import ERC721Pausable from OpenZeppelin
import "../extensions/ERC721Burnable.sol";
// import ERC721Pausable from OpenZeppelin
import "../extensions/ERC721Pausable.sol";
// import ERC721Pausable from OpenZeppelin
import "../../../access/AccessControlEnumerable.sol";
// import ERC721Pausable from OpenZeppelin
import "../../../utils/Context.sol";
// import ERC721Pausable from OpenZeppelin
import "../../../utils/Counters.sol";

// Security Token contract
contract SecurityToken is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    // import Counters for Counters.Counter;
    using Counters for Counters.Counter;
    // set roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // set token ID tracker
    Counters.Counter private _tokenIdTracker;
    // set token name and symbol
    string public name;
    string public symbol;
    // set owner of contract
    address public owner;
    // set base token URI
    string private _baseTokenURI;

    // Investor Struct to store investor details
    struct Investor {
        // investor name
        string name;
        // investor address
        address payable investorAddress;
        // investor email
        string email;
        // investor phone number
        string phoneNumber;
        // investor accredited status
        bool isAccredited;

    }

    // Investors Array
    Investor[] public investors;

    // Investor Company to store investor details
    struct Company {
        // investor name
        string name;
        // company address
        address payable investorAddress;
        // company email
        string email;
        // company phone number
        string phoneNumber;
        // company accredited status
        bool isAccredited;

    }

    // Compamy Array
    Company[] public companies;

    // mapping to store accredited investors
    mapping(address => bool) public accreditedInvestors;
    // mapping to store accredited companies
    mapping(address => bool) public accreditedCompanies;

    // mapping to store security token balances
    mapping(address => uint256) public securityTokenBalances;
    // mapping to freeze accounts
    mapping(address => bool) public freeze;


  // constructor to set name and symbol & owner of contract

 constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address _owner
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        address owner = _owner; // set owner of contract

        _setupRole(owner, msg.sender);

        _setupRole(MINTER_ROLE, msg.sender);

        _setupRole(PAUSER_ROLE, msg.sender);

        _setRoleAdmin(BURNER_ROLE, owner);

        _setRoleAdmin(DEFAULT_ADMIN_ROLE, owner);
    }

    // set base token URI
    function _baseURI() internal view virtual override returns (string memory) {
        // set base token URI
        baseURI = "https://weinode.tech/api/token/" + _tokenIdTracker.current() + "/";
        // return base token URI
        return baseURI;
    }


     // require accredited investor before minting token
    function mint(address _to, uint256 _tokenId, string memory _metadata, uint256 _tokenIdTracker) public virtual {

        // Require that the caller has the MINTER_ROLE
        require(hasRole(MINTER_ROLE, _msgSender()));
        // Require that the caller is not frozen
        require(!freeze[_to]);
        // Require that the caller is an accredited investor
        require(accreditedInvestors[_to]);
        // Require that the caller has a balance greater than 0
        require(investorBalances[_to] > 0);

        // Mint token
        _mint(to, _tokenId, _tokenIdTracker.current());

        // Emit event to
        emit TokenMint(_to, _tokenId, _metadata, _tokenIdTracker.current());

        // Increment token ID

        }
        // event to emit metadata
        event TokenMint(address indexed _to, uint256 indexed _tokenId, string _metadata, uint256 _tokenIdTracker.current());
        tokenIdTracker += 1;

    // check that sender is contract address
    function approvedForAll(address _owner, address _operator) public {
        // require that the sender is the contract address
        require(msg.sender == address(this));
        // require that the sender is not frozen
        _setApprovalForAll(_owner, _operator, true);

    }
    // pause contract
        function pause() public virtual {
        // Require that the caller has the PAUSER_ROLE
        require(hasRole(PAUSER_ROLE, _msgSender()), "Function Caller: must have pauser role to pause");
        // Require that the contract is not paused
        require(!paused(), "Contract: must not be paused to pause");
        // Pause contract
        _pause();
        // Emit event to confirm contract is paused
        emit Paused(_msgSender());
    }
    // unpause contract
    function unpause() public virtual {
        // Require that the caller has the PAUSER_ROLE
        require(hasRole(PAUSER_ROLE, _msgSender()), "Function Caller : must have pauser role to unpause");
        // Require that the contract is paused
        require(paused(), "Contract: must be paused to unpause");
        // Unpause contract
        _unpause();
        // Require that the contract is not paused
        require(!paused());
        // Emit event to confirm contract is unpaused
        emit Unpaused(_msgSender());
    }

     // transfer token
    function transfer(address _to, uint256 _tokenId) public {
        // Require that the sender is the contract address
        require(msg.sender == DEFAULT_ADMIN_ROLE());
        // Require that the sender is not frozen
        require(!freeze[msg.sender]);
        // Require that the recipient is not frozen
        require(!freeze[_to]);
        // Require that the recipient is an accredited investor
        _transfer=(address(this),_to, _tokenId);
        // Require that the recipient has a balance greater than 0
        require(investorBalances[_to] > 0);
    }
    // approve token transfer
    function approve(address _to, uint256 _tokenId) public {
        // Require that the sender is the contract address
        require(msg.sender == DEFAULT_ADMIN_ROLE());
        // Require that the sender is not frozen
        require(!freeze[msg.sender]);
        // Require that the recipient is not frozen
        _approve(_to, _tokenId);
    }
    // burn token
    function burn(uint256 _tokenId) public {
        // Require that the sender is the contract address
        require(msg.sender == BURNER_ROLE());
        // burn token
        _burn(_tokenId);
    }
    // freeze accounts
    function freezeAccount(address _target, bool _status) public {
        // Require that the sender is the contract address
        require(msg.sender == DEFAULT_ADMIN_ROLE());
        // Require that the sender is not frozen
        require(!freeze[msg.sender]);
        // freeze account
        freeze[_target] = _status;
    }

    // add accredited investor
    function addAccreditedInvestor(address[] memory _investors) public {
        //
        require(msg.sender == owner());
        // add accredited investor
    for (uint i = 0; i < investors.length; i++) {
        // add accredited investor to mapping
        accreditedInvestors[investors[i]] = true;
        }
    }

    // add accredited company
    function addAccreditedCompany(address[] memory _companies) public {
        //
        require(msg.sender == owner());
        // add accredited company
    for (uint i = 0; i < companies.length; i++) {
        // add accredited company to mapping
        accreditedCompanies[companies[i]] = true;
        }

    }

    // add security token tranfer future between companies and investors
function transferFuture(address _from, address _to, uint256 _tokenId) public {
    // Require that the sender is the contract address
    require(msg.sender == DEFAULT_ADMIN_ROLE());
    // Require that the sender is not frozen
    require(!freeze[msg.sender]);
    // Require that the recipient is not frozen
    require(!freeze[_to]);
    // Require that both parties are accredited
    require(accreditedInvestors[_from] && accreditedCompanies[_to]);

    // transfer token from investor to company
    _transferFrom(_from, _to, _tokenId);

    // Emit event to confirm token transfer
    emit TokenTransferFuture(_from, _to, _tokenId);
}

}

