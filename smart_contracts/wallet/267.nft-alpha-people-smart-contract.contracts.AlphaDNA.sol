// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./DNAData.sol";

contract AlphaDNA is DNAData {

    uint8 constant DNA_LENGTH = 2;

    function _getDNASection (uint256 _dna, uint8 _rightJump)
        internal
        pure
        returns (uint8) {
            return uint8((_dna % (10 ** (_rightJump + DNA_LENGTH))) / 10 ** _rightJump);
        }
    
    function _getAccesoryType (uint256 _dna)
        public
        view
        returns(string memory) {
            uint8 _dnaSection = _getDNASection(_dna,0);
            uint pos = _dnaSection % _accessoriesType.length;
            return _accessoriesType[pos];
    }

    function _getClotheColor (uint256 _dna)
        public
        view
        returns(string memory) {
            uint8 _dnaSection = _getDNASection(_dna,2);
            uint pos = _dnaSection % _clotheColor.length;
            return _clotheColor[pos];
    }

    function _getClotheType (uint256 _dna)
        public
        view
        returns(string memory) {
            uint8 _dnaSection = _getDNASection(_dna,4);
            uint pos = _dnaSection % _clotheType.length;
            return _clotheType[pos];
    }

    function _getEyeType (uint256 _dna)
        public
        view
        returns(string memory) {
            uint8 _dnaSection = _getDNASection(_dna,6);
            uint pos = _dnaSection % _eyeType.length;
            return _eyeType[pos];
    }

    function _getEyebrowType (uint256 _dna)
        public
        view
        returns(string memory) {
            uint8 _dnaSection = _getDNASection(_dna,8);
            uint pos = _dnaSection % _eyebrowType.length;
            return _eyebrowType[pos];
    }

    function _getFacialHairColor (uint256 _dna)
        public
        view
        returns(string memory) {
            uint8 _dnaSection = _getDNASection(_dna,10);
            uint pos = _dnaSection % _facialHairColor.length;
            return _facialHairColor[pos];
    }

    function _getFacialHairType (uint256 _dna)
        public
        view
        returns(string memory) {
            uint8 _dnaSection = _getDNASection(_dna,12);
            uint pos = _dnaSection % _facialHairType.length;
            return _facialHairType[pos];
    }

    function _getHairColor (uint256 _dna)
        public
        view
        returns(string memory) {
            uint8 _dnaSection = _getDNASection(_dna,14);
            uint pos = _dnaSection % _hairColor.length;
            return _hairColor[pos];
    }

    function _getHatColor (uint256 _dna)
        public
        view
        returns(string memory) {
            uint8 _dnaSection = _getDNASection(_dna,16);
            uint pos = _dnaSection % _hatColor.length;
            return _hatColor[pos];
    }

    function _getGraphicType (uint256 _dna)
        public
        view
        returns(string memory) {
            uint8 _dnaSection = _getDNASection(_dna,18);
            uint pos = _dnaSection % _graphicType.length;
            return _graphicType[pos];
    }

    function _getMouthType (uint256 _dna)
        public
        view
        returns(string memory) {
            uint8 _dnaSection = _getDNASection(_dna,20);
            uint pos = _dnaSection % _mouthType.length;
            return _mouthType[pos];
    }

    function _getSkinColor (uint256 _dna)
        public
        view
        returns(string memory) {
            uint8 _dnaSection = _getDNASection(_dna,22);
            uint pos = _dnaSection % _skinColor.length;
            return _skinColor[pos];
    }

    function _getTopType (uint256 _dna)
        public
        view
        returns(string memory) {
            uint8 _dnaSection = _getDNASection(_dna,24);
            uint pos = _dnaSection % _topType.length;
            return _topType[pos];
    }

    // Should not be used in production
    // the _dna is not dna really, is the tokenId used to generate next DNA
    function pseudoRandomDNA (uint256 _dna, address _minter)
        public
        pure
        returns (uint256)
    {
        uint256 combined = _dna + uint160(_minter);
        bytes memory encodedParams = abi.encodePacked(combined);
        bytes32 hashedParams = keccak256(encodedParams);

        return uint256(hashedParams);
    }

}


