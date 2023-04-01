// SPDX-License-Identifier: GPL-3.0
// To Compile Run: solcjs --optimize --bin ManufacturerContract.sol -o Smart_Contract_Binary
pragma solidity >=0.8.0 <0.9.0;

// Information on OpenZeppelin Contracts can be found at: https://docs.openzeppelin.com/contracts/4.x/access-control
import "node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

// STRUCTURE OF THE CONTRACT
// 1. State Variables
// 2. Events
// 3. Modifiers
// 4. Constructor
// 5. Functions

// ROLES
// [ADMIN, VIEWER, MAINTAINER]
// ADMIN Privs: Can add/remove roles, can add/remove tokens, can add/remove use, can add/remove updates
// VIEWER Privs: Can view tokens, can view updates, can view use
// MAINTAINER Privs: Can add/remove tokens, can add/remove use, can add/remove updates

// METHODS
// [addToken, removeToken, addUse, removeUse, addUpdate, removeUpdate, getUpdates]

contract OEMContract is ERC20, AccessControl {
    bytes32 private constant ADMIN = keccak256("OEMADMIN");
    bytes32 private constant VIEWER = keccak256("OEMVIEWER");
    bytes32 private constant MAINTAINER = keccak256("OEMMAINTAINER");

    bytes32[4] private permisssionArray = [
        ADMIN,
        VIEWER,
        MAINTAINER
    ];

    address[] private manufacturerUpdates;

    string private constant _errorMessage = "No Permission";

    struct UpdateInfo {
        uint256 checksum;
        fileCoin loc;
    }

    struct fileCoin {
        uint256 minerId;
        address CID;
        address userAddress;
    }

    function updateManufacturer(
        uint256 _checksum,
        uint256 _minerId,
        address _CID,
        address _userAddress
    ) public {
        require(
            hasRole(ADMIN, msg.sender) || hasRole(MAINTAINER, msg.sender),
            _errorMessage
        );
        manufacturerUpdates.push(
            UpdateInfo(_checksum, fileCoin(_minerId, _CID, _userAddress))
        );
    }
}

