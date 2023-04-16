// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface UpdateInfo {
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
}
