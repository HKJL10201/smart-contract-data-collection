// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import './TruflationClient.sol';

/**
 * LP token representing proof of deposit
 */

contract RobotNFT is ERC721A {
    // Public variables
    mapping(address => bool) public operator;
    mapping(string => string) public tokenURIs;
    bool public transferable = false;
    mapping(address => uint256) public ownerToTokenId;

    // Chainlink Variales
    TruflationClient truflationClient;
    address public truflationClientAddress;

    /**
     * Modifiers
     */
    modifier onlyOperator() {
        require(operator[msg.sender] == true, 'You must be a operator!');
        _;
    }

    modifier whenTransferable() {
        require(transferable, "You can't transfer this token");
        _;
    }

    constructor(address _truflationClientAddress) ERC721A('RobotNFT', 'RNFT') {
        truflationClientAddress = _truflationClientAddress;
        operator[msg.sender] = true;

        tokenURIs['happy'] = 'ipfs/QmaVFDgcZmTWkMpcNT6Mom7Ee8ge3NCFJhRFbd4nm1Rcrt/robot-nft-happy.png';
        tokenURIs['stressed'] = 'ipfs/QmaVFDgcZmTWkMpcNT6Mom7Ee8ge3NCFJhRFbd4nm1Rcrt/robot-nft-stressed-.png';
        tokenURIs['sad'] = 'ipfs/QmaVFDgcZmTWkMpcNT6Mom7Ee8ge3NCFJhRFbd4nm1Rcrt/robot-nft-sad.png';
    }

    /*
     @notice: mint is for TradingBot contract

     The following checks occur, it checks:
      - that the sender is a operator

     Upon passing checks it calls the internal _mint function to perform
     the minting.
     */
    function mint() external payable onlyOperator {
        ownerToTokenId[msg.sender] = _nextTokenId();

        _mint(msg.sender, 1);
    }

    /*
     @notice: burn is for TradingBot contract

     The following checks occur, it checks:
      - that the sender is a operator

     Upon passing checks it calls the internal _burn function to perform
     the minting.
     */
    function burn(uint256 tokenId) public onlyOperator {
        _burn(tokenId, false);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory currentTokenURI) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        int256 inflation = getInflation();

        if (inflation <= 3 * 10**18) {
            currentTokenURI = tokenURIs['happy'];
        } else if (inflation <= 7 * 10**18) {
            currentTokenURI = tokenURIs['stressed'];
        } else {
            currentTokenURI = tokenURIs['sad'];
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public payable override whenTransferable {
        super.transferFrom(_from, _to, _tokenId);
    }

    /**
     * Operator Functions
     */

    function setOperator(address _address, bool _isOperator) external onlyOperator {
        operator[_address] = _isOperator;
    }

    function setTokenURIs(string memory _identifier, string memory _url) external onlyOperator {
        tokenURIs[_identifier] = _url;
    }

    function setTruflationClientAddress(address _truflationClientAddress) public onlyOperator {
        truflationClientAddress = _truflationClientAddress;
    }

    function setTransferable(bool _transferable) external onlyOperator {
        transferable = _transferable;
    }

    /**
     * Internal Functions
     */
    function getInflation() internal view returns (int256) {
        return TruflationClient(truflationClientAddress).inflation();
    }
}
