interface IFetch {
  function depositFor(bool _isClaimAbleStake, address receiver) external payable;

  function depositsPerUser(address user, uint256 id)
    external
    view
    returns(uint256, uint256, uint256);
}
