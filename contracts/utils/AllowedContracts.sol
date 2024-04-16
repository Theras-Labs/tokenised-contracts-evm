// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract AllowedContracts {
    mapping(address => bool) public allowedContracts;

    modifier onlyOperator() {
        require(
            allowedContracts[msg.sender],
            "Only allowed contract can call this function"
        );
        _;
    }
    
    function _addAllowedContract(address contractAddress) internal virtual {
        allowedContracts[contractAddress] = true;
    }

    function _removeAllowedContract(address contractAddress) internal virtual {
        allowedContracts[contractAddress] = false;
    }

    function isContractAllowed(address contractAddress) public view returns (bool) {
        return allowedContracts[contractAddress];
    }

}
