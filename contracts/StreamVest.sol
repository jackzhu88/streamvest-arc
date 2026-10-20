// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title StreamVest - USDC vesting / scheduled payouts on Arc
/// @notice A payer locks native USDC for a beneficiary. Funds vest linearly
///         between start+cliff and start+duration. The beneficiary claims
///         vested funds at any time; a revocable schedule can be revoked by the
///         payer, who gets back the unvested part (vested part stays claimable).
contract StreamVest {
    struct Schedule {
        address payer;
        address beneficiary;
        uint128 total;
        uint128 claimed;
        uint64 start;
        uint64 cliff;     // seconds after start before anything vests
        uint64 duration;  // seconds after start until fully vested
        uint64 revokedAt; // 0 if not revoked
        bool revocable;
        string memo;
    }

    Schedule[] private schedules;
    bool private locked;

    event Created(uint256 indexed id, address indexed payer, address indexed beneficiary, uint256 total, uint64 start, uint64 cliff, uint64 duration, bool revocable, string memo);
    event Claimed(uint256 indexed id, address indexed beneficiary, uint256 amount);
    event Revoked(uint256 indexed id, uint256 refunded);

    modifier nonReentrant() { require(!locked, "reentrant"); locked = true; _; locked = false; }

    function create(address beneficiary, uint64 start, uint64 cliff, uint64 duration, bool revocable, string calldata memo)
        external payable returns (uint256 id)
    {
        require(beneficiary != address(0), "beneficiary");
        require(msg.value > 0 && msg.value <= type(uint128).max, "amount");
        require(duration > 0 && cliff <= duration, "timing");
        if (start == 0) start = uint64(block.timestamp);
        id = schedules.length;
        schedules.push(Schedule(msg.sender, beneficiary, uint128(msg.value), 0, start, cliff, duration, 0, revocable, memo));
        emit Created(id, msg.sender, beneficiary, msg.value, start, cliff, duration, revocable, memo);
    }

    function vestedAt(uint256 id, uint256 t) public view returns (uint256) {
        Schedule storage s = schedules[id];
        if (s.revokedAt != 0 && t > s.revokedAt) t = s.revokedAt;
        if (t < uint256(s.start) + s.cliff) return 0;
        if (t >= uint256(s.start) + s.duration) return s.total;
        return uint256(s.total) * (t - s.start) / s.duration;
    }

    function claimable(uint256 id) public view returns (uint256) {
        return vestedAt(id, block.timestamp) - schedules[id].claimed;
    }

    function claim(uint256 id) external nonReentrant {
        Schedule storage s = schedules[id];
        require(msg.sender == s.beneficiary, "not beneficiary");
        uint256 amt = claimable(id);
        require(amt > 0, "nothing to claim");
        s.claimed += uint128(amt);
        (bool ok,) = s.beneficiary.call{value: amt}("");
        require(ok, "transfer failed");
        emit Claimed(id, s.beneficiary, amt);
    }

    function revoke(uint256 id) external nonReentrant {
        Schedule storage s = schedules[id];
        require(msg.sender == s.payer, "not payer");
        require(s.revocable && s.revokedAt == 0, "not revocable");
        s.revokedAt = uint64(block.timestamp);
        uint256 refund = s.total - vestedAt(id, block.timestamp);
        if (refund > 0) {
            (bool ok,) = s.payer.call{value: refund}("");
            require(ok, "refund failed");
        }
        emit Revoked(id, refund);
    }

    function count() external view returns (uint256) { return schedules.length; }
    function getSchedule(uint256 id) external view returns (Schedule memory) { return schedules[id]; }
}
