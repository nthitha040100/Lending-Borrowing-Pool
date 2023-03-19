# Lending-Borrowing-Pool

Place where one can 
<li>lend tokens for the interest which is calculated on the basis of the timeperiod to which the token is lend </li>
<li>borrow tokens in exchange of the collateral</li>

### Functions
lendToken(address _erc20LT, uint256 _lendingAmt)\
takeLendedToken(uint256 _lendingId)\
borrowToken(address _erc20BT, uint256 _borrowAmt, address _erc20CT, uint256 _collatoralAmt)\
tokenAmount(string memory symbol) returns(uint256)
### Helper functions
percentage(uint256 amount, uint256 bps) internal returns (uint256)\
getSymbol(address _token) internal returns(string memory)

### Events
LendToken(uint256 lendingID, address lender, address lendingToken, uint256 lendingAmt, uint timeOfLending)\
TakeLendedToken(uint256 lendingID, int timeOfTakingLendingToken)

### Enum
LendingStates {OPEN,CLOSED}

### Modifiers
onlyInitiator(uint256 Id)\
onlyOpenLendings(uint256 Id)
