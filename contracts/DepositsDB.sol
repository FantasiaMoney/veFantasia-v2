pragma solidity ^0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DepositsDB is Ownable {
  struct Deposit {
    uint256 balanceBefore;
    uint256 balanceAfter;
    uint256 time;
  }

  mapping (address => Deposit[]) public depositsPerUser;
  mapping (address => bool) public permitted;

  function deposit(address receiver, uint256 balanceBefore, uint256 balanceAfter) external{
    require(permitted[msg.sender], "Not permitted to write in DB");
    Deposit memory deposit = Deposit(balanceBefore, balanceAfter, now);
    depositsPerUser[receiver].push(deposit);
  }

  function updatePermitted(address account, bool status) external onlyOwner {
    permitted[account] = status;
  }

  /**
  * @dev return length of all user deposits
  */
  function totalUserDeposits(address user)
    external
    view
    returns(uint256)
  {
     Deposit[] memory deposits = depositsPerUser[user];
     return deposits.length;
  }
}
