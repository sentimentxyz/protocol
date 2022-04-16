// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IRegistry {
    event AccountCreated(address indexed account, address indexed owner);

    function initialize() external;

    function addressFor(string calldata id) external view returns (address);
    function ownerFor(address account) external view returns (address);

    function getAllLTokens() external view returns (address[] memory);
    function LTokenFor(address underlying) external view returns (address);

    function setAddress(string calldata id, address _address) external;
    function setLToken(address underlying, address lToken) external;

    function addAccount(address account, address owner) external;
    function updateAccount(address account, address owner) external;
    function closeAccount(address account) external;
    
    function getAllAccounts() external view returns(address[] memory);
    function accountsOwnedBy(address user)
        external view returns (address[] memory);
}