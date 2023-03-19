// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract Pool{

    address public owner;

    constructor(){
        owner = msg.sender;
    }

    struct LenderInfo {
        address lender;
        address lendingToken;
        uint256 lendingAmt;
        uint timeOfLending;
    }

    struct BorrowerInfo{
        address borrower;
        address borrowingToken;
        uint256 borrowingAmt;     
        address colToken;
        uint256 colAmt;
        uint timeOfBorrowing;
    }

    enum LendingStates {
        OPEN,
        CLOSED
    }

    mapping(string => uint256) liquidityPool;
    mapping(uint256 => LendingStates) lendingStates;
    mapping(uint256 => LenderInfo) lenders;
    mapping(uint256 => BorrowerInfo) borrowers;

    event LendToken(uint256 lendingID, address lender, address lendingToken, uint256 lendingAmt, uint timeOfLending);
    event TakeLendedToken(uint256 lendingID, int timeOfTakingLendingToken);

    uint256 lendingId;
    function lendToken(address _erc20LT, uint256 _lendingAmt ) public {
        
        IERC20 erc20LT = IERC20(_erc20LT);
        require(erc20LT.allowance(msg.sender,address(this)) >= _lendingAmt );
        require(erc20LT.transferFrom(msg.sender,address(this),_lendingAmt));
        
        LenderInfo memory lenderinfo = LenderInfo({
            lender: msg.sender,
            lendingToken: _erc20LT,
            lendingAmt: _lendingAmt,
            timeOfLending: block.timestamp
        });

        lenders[lendingId] = lenderinfo;
        lendingStates[lendingId] = LendingStates.OPEN;
        lendingId++;
        liquidityPool[getSymbol(_erc20LT)] += _lendingAmt;

    }

    function takeLendedToken(uint256 _lendingId) onlyInitiator(lendingId) onlyOpenLendings(lendingId) public{

        LenderInfo memory lenderinfo = lenders[_lendingId];
        IERC20 erc20LT = IERC20(lenderinfo.lendingToken);
        uint256 returnAmount;

        if((block.timestamp - lenders[_lendingId].timeOfLending) >= 31536000){ 
            //If more than 1Year, ROI % = 12%
            returnAmount = lenderinfo.lendingAmt + percentage(lenderinfo.lendingAmt,1200);

        }else if( (31536000 > (block.timestamp - lenders[lendingId].timeOfLending)) || ((block.timestamp - lenders[lendingId].timeOfLending) > 15768000)){ 
            //If in betwen 6m and 1Y, ROI % = 5%
            returnAmount = lenderinfo.lendingAmt + percentage(lenderinfo.lendingAmt,500);
        
        }else{
            //If less than 6m, ROI % = 0%
            returnAmount = lenderinfo.lendingAmt;

        }
        require(liquidityPool[getSymbol(lenderinfo.lendingToken)] >= returnAmount,"Sorry unable to fulfil your request!");
        lendingStates[_lendingId] = LendingStates.CLOSED;
        liquidityPool[getSymbol(lenderinfo.lendingToken)] -= returnAmount;
        require(erc20LT.transfer(msg.sender, returnAmount));

    }

    uint256 borrowId;
    function borrowToken(address _erc20BT, uint256 _borrowAmt, address _erc20CT, uint256 _collatoralAmt) public{
        
        IERC20 erc20BT = IERC20(_erc20BT);
        IERC20 erc20CT = IERC20(_erc20CT);

        require(percentage(_borrowAmt,5000) < _collatoralAmt); //Collateral Amount should be moe than 50% of borrowing amount
        require(liquidityPool[getSymbol(_erc20BT)] >= _borrowAmt); //Borrowing amount should be suffcient in the liquiding Pool

        BorrowerInfo memory borrowerinfo = BorrowerInfo({
            borrower: msg.sender,
            borrowingToken: _erc20BT,
            borrowingAmt: _borrowAmt,
            colToken: _erc20CT,
            colAmt: _collatoralAmt,
            timeOfBorrowing: block.timestamp
        });
        
        require(erc20CT.allowance(msg.sender,address(this)) >= _collatoralAmt );
        require(erc20CT.transferFrom(msg.sender,address(this),_collatoralAmt));
        liquidityPool[getSymbol(_erc20CT)] += _collatoralAmt;

        require(erc20BT.allowance(address(this),msg.sender) >= _borrowAmt );
        require(erc20BT.transferFrom(address(this),msg.sender,_borrowAmt));
        liquidityPool[getSymbol(_erc20BT)] -= _borrowAmt;

        borrowers[borrowId] = borrowerinfo;
        borrowId++;

    }

    function tokenAmount(string memory symbol) public view returns(uint256){
        return liquidityPool[symbol];
    }

    function getTokenAddress() public view returns(address){
        return address(this);
    }

    function percentage(uint256 amount, uint256 bps) internal pure returns (uint256) {
        require((amount * bps) >= 10_000);
        return amount * bps / 10_000;
    }

    function getSymbol(address _token) internal view returns(string memory){
        IERC20Metadata token = IERC20Metadata(_token);
        return token.symbol();
    }

    modifier onlyInitiator(uint256 Id){
        require(msg.sender == lenders[Id].lender, "Only Initiator can perform this task");
        _;
    }

    modifier onlyOpenLendings(uint256 Id){
        require(lendingStates[Id] == LendingStates.OPEN, "This transaction has been closed");
        _;
    }    
}