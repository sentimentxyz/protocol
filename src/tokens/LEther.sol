// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LToken} from "./LToken.sol";
import {Helpers} from "../utils/Helpers.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";
import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";

interface IWETH {
    function withdraw(uint) external;
    function deposit() external payable;
}

contract LEther is LToken {
    using Helpers for address;
    using PRBMathUD60x18 for uint;
    
    constructor(
        ERC20 _asset, 
        string memory _name, 
        string memory _symbol,
        IRegistry _registry,
        uint _reserveFactor
    ) LToken(_asset, _name, _symbol, _registry, _reserveFactor) {}

    function depositEth() external payable {
        uint assets = msg.value;
        uint shares = previewDeposit(assets);
        require(shares != 0, "ZERO_SHARES");
        IWETH(address(asset)).deposit{value: assets}();
        _mint(msg.sender, shares);
        emit Deposit(msg.sender, msg.sender, assets, shares);
    }

    function redeemEth(uint shares) external {
        uint assets = previewRedeem(shares);
        _burn(msg.sender, shares);
        emit Withdraw(msg.sender, msg.sender, msg.sender, assets, shares);
        IWETH(address(asset)).withdraw(assets);
        msg.sender.safeTransferEth(assets);
    }
    
    receive() external payable {}
}