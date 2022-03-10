// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IAccount} from "../../interface/core/IAccount.sol";
import {IntegrationTestBase} from "./utils/IntegrationTestBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStableSwapPool {    
    function get_dy(uint256, uint256, uint256) external view returns (uint256);
}


contract curveIntegrationTest is IntegrationTestBase {

    address user = cheats.addr(1);
    address account;

    function setUp() public {
        setupContracts();
        setupWEthController();
        setupCurveController();
        account = openAccount(user);
    }

    function testSwapWEthUSDT(uint8 _value) public {
        // Setup
        cheats.assume(_value != 0);
        uint256 value = uint256(_value) * 1 ether;
        cheats.deal(user, value);
        deposit(user, account, address(0), value);

        // Wrap Eth
        bytes memory wethdata = abi.encodeWithSignature("deposit()");
        cheats.prank(user);
        accountManager.exec(account, WETH, value, wethdata);
        
        // Encode Data
        uint256 minValue = IStableSwapPool(curveEthSwap).get_dy(
            uint256(2),
            uint256(0),
            value
        );
        bytes memory data = abi.encodeWithSignature(
            "exchange(uint256,uint256,uint256,uint256)",
            uint256(2),
            uint256(0),
            value,
            minValue
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, WETH, curveEthSwap, value);
        accountManager.exec(account, curveEthSwap, 0, data);

        // Assert
        assertGe(IERC20(USDT).balanceOf(account), minValue);
        assertEq(IERC20(WETH).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), USDT);
    }
}