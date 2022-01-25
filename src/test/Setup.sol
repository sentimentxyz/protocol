// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@ds-test/src/test.sol";
import { ERC20PresetMinterPauser } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

import "./mocks/oracle.sol";
import "./Cheatcode.sol";

import "../LERC20.sol";
import "../LEther.sol";
import "../DefaultRateModel.sol";
import "../interface/IERC20.sol";
import "../AccountManager.sol";
import "../RiskEngine.sol";
import "../UserRegistry.sol";
import "../AccountFactory.sol";

contract Test is DSTest {
    CheatCode cheatCode = CheatCode(HEVM_ADDRESS);

    LERC20 public ltoken;
    LEther public lEther;
    ERC20PresetMinterPauser public token;

    DefaultRateModel public rateModel;
    
    AccountManager public accountManager;
    RiskEngine public riskEngine;
    UserRegistry public userRegistry;
    AccountFactory public factory;

    function setUpLEther() public {
        lEther = new LEther("LEther", "LETH", 1, address(0), address(rateModel), address(accountManager), 1);
    }

    function setUpLtoken() public {
        token = new ERC20PresetMinterPauser("Sentiment", "STM");
        ltoken = new LERC20("LSentiment", "LSTM", 1, address(token), address(rateModel), address(accountManager), 1);
    }

    function setUpAccountManager() public {
        riskEngine = setUpRiskEngine();
        factory = new AccountFactory(address(0));
        userRegistry = new UserRegistry();
        accountManager = new AccountManager(address(riskEngine), address(factory), address(userRegistry));
    }

    function setUpRiskEngine() public returns (RiskEngine engine) {
        Oracle oracle = new Oracle();
        engine = new RiskEngine(address(oracle));
    }

    function basicSetup() public {
        setUpAccountManager();
        setUpLEther();
        setUpLtoken();
    }
}