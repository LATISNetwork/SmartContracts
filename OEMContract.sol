// SPDX-License-Identifier: GPL-3.0
// To Compile Run: solcjs --optimize --bin ManufacturerContract.sol -o Smart_Contract_Binary
pragma solidity >=0.8.0 <0.9.0;

// Information on OpenZeppelin Contracts can be found at: https://docs.openzeppelin.com/contracts/4.x/access-control
import "node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MiddleManContract.sol";
import "UpdateInfo.sol";

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
    bytes32 private constant ADMIN =
        0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42;
    bytes32 private constant VIEWER =
        0x4acc1d14ea2d6e85862a81bf8d5c1251286193eed6e3b81aab32a560eecea7ff;
    bytes32 private constant MAINTAINER =
        0x293ac1473af20b374a0b048d245a81412cd467992bf656b69382c50f310e9f8c;

    bytes32[3] private permissionArray = [ADMIN, VIEWER, MAINTAINER];

    string private constant _errorMessage = "No Permission";

    string private _oemName;

    constructor(string memory _name) ERC20("MyToken", "TKN") {
        _grantRole(ADMIN, msg.sender);
        _oemName = _name;
    }

    struct deviceType {
        mapping(string => UpdateInfo.Update) updates;
    }

    // list of updates
    // deviceName => version => update
    mapping(string => deviceType) myUpdates;
    // UpdateInfo.Update[] private myUpdates;

    // Name of company and associated middle man contracts
    mapping(string => MiddleManContract) private myManufacturers;

    // Add an update to the correct locations
    function addUpdate(
        // Update information
        string memory _device,
        string memory _version,
        uint256 _checksum,
        // file coin information
        uint256 _minerId,
        address _CID,
        address _userAddress,
        string memory _link
    ) public {
        require(hasRole(MAINTAINER, msg.sender), _errorMessage);
        UpdateInfo.FileCoin memory _fileCoin = UpdateInfo.FileCoin(
            _minerId,
            _CID,
            _userAddress,
            _link
        );
        UpdateInfo.Update memory _update = UpdateInfo.Update(
            _checksum,
            _oemName,
            _device,
            _version,
            _fileCoin
        );
        myUpdates[_device].updates[_version] = _update;
    }

    function pushUpdate(
        string memory _device,
        string memory _version,
        string memory _manufacturer
    ) public {
        require(hasRole(MAINTAINER, msg.sender), _errorMessage);
        myManufacturers[_manufacturer].addUpdate(myUpdates[_device].updates[_version]);
    }

    function addManufacturer(
        address _manufacturer,
        string memory _name
    ) public {
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        myManufacturers[_name] = MiddleManContract(_manufacturer);
    }

    function removeManufacturer(
        string memory _name
    ) public {
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        delete myManufacturers[_name];
    }

    function grantPermission(address _to, uint8 _permission) public {
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        _grantRole(permissionArray[_permission], _to);
    }

    function revokePermission(address _to, uint8 _permission) public {
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        _revokeRole(permissionArray[_permission], _to);
    }
}
