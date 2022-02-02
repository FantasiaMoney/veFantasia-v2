pragma solidity ^0.6.2;

import "./interfaces/IBurn.sol";
import "./interfaces/IMint.sol";
import "./interfaces/IFetch.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract VTokenToToken is Ownable {
  using SafeMath for uint256;

  address public tokenMinter;
  address public vToken;
  address public fetch = address(0);

  mapping (address => mapping (uint256 => bool)) public timeUsed;

  constructor(address _tokenMinter, address _vToken) public {
    tokenMinter = _tokenMinter;
    vToken = _vToken;
  }

  function setFetch(address _fetch) external onlyOwner {
    fetch = _fetch;
  }

  // convert vToken to token
  // rate depends on time
  // max rate 1 to 1
  function convert(address _to, uint256 _depositId, uint256 _amount) external {
    require(fetch != address(0), "Zerro fetch");

    // get deposit data
    (uint256 balanceBefore,
     uint256 balanceAfter,
     uint256 time) = IFetch(fetch).depositsPerUser(_to, _depositId);

    // check if time not used before for this user
    require(timeUsed[_to][time] == false, "Time used");

    // calculate how much to mint token
    uint256 toReedem = balanceBefore > balanceAfter
    ? balanceBefore.sub(balanceAfter)
    : balanceAfter.sub(balanceBefore);

    uint256 toTransfer = calculateReturn(time, toReedem);

    // burn vtoken
    IBurn(vToken).burnFrom(_to, toReedem);
    // mint token
    IMint(tokenMinter).mint(_to, toTransfer);

    // not allow reedem from this deposit date twice
    timeUsed[_to][time] = true;
  }

  // return amount of token to withdraw
  // more time hold more close rate 1 to 1
  function calculateReturn(uint256 _startTime, uint256 _amount)
    public
    view
    returns(uint256)
  {
    uint256 duration = 365 days;

    if(block.timestamp >= _startTime + duration) {
      return _amount;
    }
    else{
      return _amount.mul(block.timestamp.sub(_startTime)).div(duration);
    }
  }
}
