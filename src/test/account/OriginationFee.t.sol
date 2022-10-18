// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {TestBase} from "../utils/TestBase.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IAccount} from "../../interface/core/IAccount.sol";

import {LEther} from "../../tokens/LEther.sol";
import {LToken} from "../../tokens/LToken.sol";
import {Proxy} from "../../proxy/Proxy.sol";

contract OriginationFeeTests is TestBase {
    using FixedPointMathLib for uint96;
    using FixedPointMathLib for uint;

    address public account;
    address lp = cheats.addr(100);
    address borrower = cheats.addr(101);

    uint fee = 1e3;

    function setUp() public {
        setupContracts();
        lEth = LEther(payable(address(new Proxy(address(lEthImplementation)))));
        lEth.init(weth, "LEther", "LEth", registry, fee, treasury, 0, type(uint).max);

        lErc20 = LToken(address(new Proxy(address(lErc20Implementation))));
        lErc20.init(erc20, "LTestERC20", "LERC20", registry, fee, treasury, 0, type(uint).max);

        registry.setLToken(address(weth), address(lEth));
        registry.setLToken(address(erc20), address(lErc20));

        lEth.initDep('RATE_MODEL');
        lErc20.initDep('RATE_MODEL');
        account = openAccount(borrower);
    }

    function testOriginationFee(uint96 depositAmt, uint96 borrowAmt) public {
        cheats.assume(borrowAmt > 10 ** (18 - 2));
        // Test
        cheats.assume(
            (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold()
        );
        deposit(borrower, account, address(erc20), depositAmt);
        borrow(borrower, account, address(erc20), borrowAmt);

        // Assert
        assertTrue(!IAccount(account).hasNoDebt());
        assertEq(erc20.balanceOf(address(lErc20)), 0);
        assertEq(lErc20.getBorrowBalance(address(account)), borrowAmt);
        assertEq(
            erc20.balanceOf(address(account)),
            uint(depositAmt) + borrowAmt - borrowAmt.mulDivDown(fee, 10 ** erc20.decimals())
        );
        assertEq(
            erc20.balanceOf(treasury),
            borrowAmt.mulDivDown(fee, 10 ** erc20.decimals())
        );
    }

}