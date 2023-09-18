// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract CoveyLedger is Initializable {
    struct CoveyContent {
        address analyst;
        string content;
        uint256 created_at;
    }

    mapping(address => CoveyContent[]) analystContent;
    CoveyContent[] allContent;
    address owner;

    mapping(address => CoveyContent[]) backupContent;

    function initialize() public initializer {
        owner = msg.sender;
    }

    event ContentCreated(
        address indexed analyst,
        string content,
        uint256 indexed created_at
    );

    event AddressSwapped(
        address indexed oldAddress,
        address indexed newAddress
    );

    event LedgerBackup(address indexed analystAddress);
    event LedgerRestored(address indexed analystAddress);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function createContent(string memory content) public {
        CoveyContent memory c = CoveyContent({
            analyst: msg.sender,
            content: content,
            created_at: block.timestamp
        });
        analystContent[msg.sender].push(c);
        allContent.push(c);

        emit ContentCreated(msg.sender, content, block.timestamp);
    }

    function getAnalystContent(address _adr)
        public
        view
        returns (CoveyContent[] memory)
    {
        return analystContent[_adr];
    }

    function getAllContent() public view returns (CoveyContent[] memory) {
        return allContent;
    }

    function AddressSwitch(address oldAddress, address newAddress) public {
        require(msg.sender == oldAddress);
        require(
            analystContent[msg.sender].length > 0,
            'Cannot copy an empty ledger'
        );

        CoveyContent[] storage copyContent = analystContent[msg.sender];

        if (analystContent[newAddress].length > 0) {
            backupLedger(newAddress);
            CoveyContent[] memory existingLedger = analystContent[newAddress];
            delete analystContent[newAddress];
            for (uint256 i = 0; i < copyContent.length; i++) {
                if (copyContent[i].created_at < existingLedger[0].created_at) {
                    analystContent[newAddress].push(copyContent[i]);
                }
            }

            for (uint256 j = 0; j < existingLedger.length; j++) {
                analystContent[newAddress].push(existingLedger[j]);
            }
        } else {
            analystContent[newAddress] = copyContent;
        }

        emit AddressSwapped(oldAddress, newAddress);
    }

    function backupLedger(address analystAddress) private {
        require(analystContent[analystAddress].length > 0, 'Nothing to backup');

        CoveyContent[] storage backup = analystContent[analystAddress];

        backupContent[analystAddress] = backup;
        emit LedgerBackup(analystAddress);
    }

    function restoreLedger(address analystAddress) public {
        require(
            backupContent[analystAddress].length > 0,
            'No backup to restore'
        );

        require(
            msg.sender == analystAddress,
            'Cannot restore address other than your own'
        );
        CoveyContent[] storage backup = backupContent[analystAddress];
        analystContent[analystAddress] = backup;

        delete backupContent[analystAddress];

        emit LedgerRestored(analystAddress);
    }

    function getBackupContent(address _adr)
        public
        view
        returns (CoveyContent[] memory)
    {
        return backupContent[_adr];
    }
}
