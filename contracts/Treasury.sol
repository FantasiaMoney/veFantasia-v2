pragma solidity ^0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract Treasury is Ownable {
  using SafeERC20 for IERC20;

  // deposit in strategy

  // withdraw from strategy

  // set strategy

  function withdraw(uint256 _amount, address _token) external onlyOwner {
    IERC20(_token).safeTransfer(msg.sender, _amount);
  }
}
