// SPDX-License-Identifier: GPL-3.0
// To Compile Run: solcjs --optimize --bin ManufacturerContract.sol -o Smart_Contract_Binary
pragma solidity >=0.8.0 <0.9.0;

// Information on OpenZeppelin Contracts can be found at: https://docs.openzeppelin.com/contracts/4.x/access-control
import "node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MiddleManContract.sol";

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

    bytes32[4] private permissionArray = [ADMIN, VIEWER, MAINTAINER];

    string private constant _errorMessage = "No Permission";

    constructor() ERC20("MyToken", "TKN") {
        _grantRole(ADMIN, msg.sender);
    }

    struct Update {
        uint256 checksum;
        string oem;
        string device;
        string version;
        FileCoin fileCoin;
    }

    struct FileCoin {
        uint256 minerId;
        address CID;
        address userAddress;
        string link;
    }

    // list of updates
    Update[] private myUpdates;

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
        FileCoin storage _fileCoin = FileCoin(
            _minerId,
            _CID,
            _userAddress,
            _link
        );
        Update storage _update = Update(
            _checksum,
            _OEMIdToAddress[msg.sender].oemName,
            _device,
            _version,
            _fileCoin
        );
        myUpdates.push(_update);
    }

    function pushUpdate(
        uint256 _updateIndex,
        string memory _manufacturer
    ) public {
        // This method needs to call the middle man contract with the correct parameters and push the update requrested
        UpdateInfo storage t = myUpdates[_updateIndex];
        FileCoin storage tloc = t.loc;
        myManufacturers[_manufacturer].addUpdate(
            t.device,
            t.version,
            tloc.minerId,
            tloc.CID,
            tloc.userAddress,
            tloc.link
        ); // This line will not work !!!!!!!!!!!!!!!!!!
    }

    function addManufacturer(
        address _manufacturer,
        string memory _name
    ) public {
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        myManufacturers[_name] = new MiddleManContract(_manufacturer); // Need to look more into how to do this aspect
    }

    function removeManufacturer(
        address _manufacturer,
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
