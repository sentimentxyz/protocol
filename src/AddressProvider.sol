// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./utils/Ownable.sol";

contract AddressProvider is Ownable {
    
    mapping(bytes32 => address) public contractAddressMapping;
    mapping(address => address) public tokenLTokenMapping;

    event AddressSet(bytes32 indexed contractName, address indexed contractAddress);
    event LTokenMappingSet(address indexed token, address indexed lToken);

    constructor() {
        admin = msg.sender;
    }

    function setAddress(bytes32 _contractName, address _contractAddress) public adminOnly {
        contractAddressMapping[_contractName] = _contractAddress;
        emit AddressSet(_contractName, _contractAddress);
    }

    function getAddress(bytes32 _contractName) public view returns (address) {
        return contractAddressMapping[_contractName];
    }

    function setLToken(address _token, address _lToken) public adminOnly {
        tokenLTokenMapping[_token] = _lToken;
        emit LTokenMappingSet(_token, _lToken);
    }

    function getLToken(address _token) public view returns (address) {
        return tokenLTokenMapping[_token];
    }
}