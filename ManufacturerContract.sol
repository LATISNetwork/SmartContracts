// SPDX-License-Identifier: GPL-3.0
// To Compile Run: solcjs --optimize --bin ManufacturerContract.sol -o Smart_Contract_Binary
pragma solidity >=0.8.0 <0.9.0;

// Information on OpenZeppelin Contracts can be found at: https://docs.openzeppelin.com/contracts/4.x/access-control
import "node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "MiddleManContract.sol";

contract ManufacturerContract is ERC20, AccessControl {
    MiddleManContract middleManContract;

    // Instatnitate all the different permission levels
    bytes32 private ADMIN =
        0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42;
    bytes32 private ASSIGN_UPDATE =
        0x293ac1473af20b374a0b048d245a81412cd467992bf656b69382c50f310e9f8c;
    bytes32 private IMPLEMENT_UPDATE =
        0x02ab26f719f5550031a1a942ddcb6b91a1c5b98639464444f1bb36c8a35efc27;
    bytes32 private VIEW_PENDING_UPDATES =
        0x4acc1d14ea2d6e85862a81bf8d5c1251286193eed6e3b81aab32a560eecea7ff;
    bytes32[4] private permissionArray = [
        VIEW_PENDING_UPDATES, // VIEW_PENDING_UPDATES
        IMPLEMENT_UPDATE, // IMPLEMENT_UPDATE
        ASSIGN_UPDATE, // ASSIGN_UPDATE
        ADMIN // ADMIN
    ];

    // Error Message if user has incorrect permission
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

    mapping(address => UpdateInfo) private myDirectory;
    address[] private pendingUpdates;
    address[] private failedUpdates;

    constructor() ERC20("MyToken", "TKN") {
        _grantRole(ADMIN, msg.sender);
        middleManContract = new MiddleManContract();
    }

    function assignUpdate(
        address _to,
        uint256 _checksum,
        uint256 _minerId,
        address _CID,
        address _userAddress
    ) public {
        require(hasRole(ASSIGN_UPDATE, msg.sender), _errorMessage);
        myDirectory[_to] = UpdateInfo(
            _checksum,
            fileCoin(_minerId, _CID, _userAddress)
        );
        pendingUpdates.push(_to);
    }

    function viewUpdates()
        public
        view
        returns (address[] memory _pendingUpdates)
    {
        require(hasRole(VIEW_PENDING_UPDATES, msg.sender), _errorMessage);
        return (pendingUpdates);
    }

    function implementUpdate()
        public
        view
        returns (uint256, uint256, address, address)
    {
        require(hasRole(IMPLEMENT_UPDATE, msg.sender), _errorMessage);
        return (
            myDirectory[msg.sender].checksum,
            myDirectory[msg.sender].loc.minerId,
            myDirectory[msg.sender].loc.CID,
            myDirectory[msg.sender].loc.userAddress
        );
    }

    function successUpdate(address _id) public {
        require(hasRole(IMPLEMENT_UPDATE, msg.sender), _errorMessage);
        delete myDirectory[_id];
    }

    function failUpdate(address _id) public {
        require(hasRole(IMPLEMENT_UPDATE, msg.sender), _errorMessage);
        failedUpdates.push(_id);
    }

    function grantPermission(address _to, uint8 _permission) public {
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        _grantRole(permissionArray[_permission], _to);
    }

    function revokePermission(address _to, uint8 _permission) public {
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        _revokeRole(permissionArray[_permission], _to);
    }

    function getMiddleManContract() public view returns(MiddleManContract _middleMan) {
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        return middleManContract;
    }
    
    function addOEM(address _oemAddress) public{
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        middleManContract.addOEM(_oemAddress);
    }

    function removeOEM(address _oemAddress) public{
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        middleManContract.removeOEM(_oemAddress);
    }
}
