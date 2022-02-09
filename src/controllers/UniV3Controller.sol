// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../utils/Pausable.sol";
import "../interface/controllers/IController.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

contract UniV3Controller is Pausable, IController {
    bytes4 public constant EXACT_INPUT_SINGLE = 0x414bf389;
    bytes4 public constant EXACT_OUTPUT_SINGLE = 0xac9650d8;
    mapping(address => bool) public isSwapAllowed;

    constructor() {
        admin = msg.sender;
    }

    function canCall(
        address target,
        bytes4 sig,
        bytes calldata data
    ) external view returns (bool, address[] memory, address[] memory)  
    {
        return _parseSwapArgs(sig, data);
    }

    function toggleAllowance(address tokenAddr) external {
        require(msg.sender == admin);
        isSwapAllowed[tokenAddr] = !isSwapAllowed[tokenAddr];
    }

    function _parseSwapArgs(
        bytes4 sig,
        bytes calldata data
    ) internal view returns (bool, address[] memory, address[] memory) 
    {
        address tokenSent;
        address tokenReceived;
        address[] memory tokensIn = new address[](1);
        address[] memory tokensOut = new address[](1);

        if(sig == EXACT_INPUT_SINGLE) {
            ISwapRouter.ExactInputSingleParams memory swapArgs; 
            swapArgs = abi.decode(data, (ISwapRouter.ExactInputSingleParams));
            tokenSent = swapArgs.tokenIn;
            tokenReceived = swapArgs.tokenOut;
        } else if (sig == EXACT_OUTPUT_SINGLE) {
            ISwapRouter.ExactOutputSingleParams memory swapArgs;
            swapArgs = abi.decode(data, (ISwapRouter.ExactOutputSingleParams));
            tokenSent = swapArgs.tokenIn;
            tokenReceived = swapArgs.tokenOut;
        } else revert("UniV3Controller: Restricted");
        
        tokensIn[0] = tokenReceived;
        tokensOut[0] = tokenSent;

        return (isSwapAllowed[tokenReceived], tokensIn, tokensOut);
    }
}