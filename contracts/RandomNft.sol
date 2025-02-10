// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "hardhat/console.sol";

error RandomIpfsNft__AlreadyInitialized();
error RandomIpfsNft__NeedMoreETHSent();
error RandomIpfsNft__RangeOutOfBounds();
error RandomIpfsNft__TransferFailed();

contract RandomIpfsNft is ERC721URIStorage, VRFConsumerBaseV2Plus, Ownable {
    // Types
    enum Breed {
        PUG,
        SHIBA_INU,
        ST_BERNARD
    }

    // Chainlink VRF Variables
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant numWords = 1;
    bytes32 public keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    // uint32 public callbackGasLimit = 1_00_000;

    // NFT Variables
    uint256 private immutable i_mintFee;
    uint256 private s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_dogTokenUris;
    bool private s_initialized;

    // VRF Helpers
    mapping(uint256 => address) public s_requestIdToSender;

    // Events
    event NftRequested(uint256 indexed requestId, address indexed requester);
    event NftMinted(
        uint256 indexed tokenId,
        Breed indexed breed,
        address indexed minter
    );

    constructor(
        address _vrfCoordinator,
        uint256 subscriptionId,
        uint256 mintFee,
        string[3] memory dogTokenUris
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) ERC721("Random IPFS NFT", "RIN") {
        i_subscriptionId = subscriptionId;
        i_mintFee = mintFee;
        _initializeContract(dogTokenUris);
        s_tokenCounter = 0;
    }

    function requestNft() public payable returns (uint256 requestId) {
        if (msg.value < i_mintFee) {
            revert RandomIpfsNft__NeedMoreETHSent();
        }
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: 1_00_000,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: true
                    })
                )
            })
        );

        s_requestIdToSender[requestId] = msg.sender;
        emit NftRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        address dogOwner = s_requestIdToSender[requestId];
        uint256 newItemId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;
        Breed dogBreed = getBreedFromModdedRng(moddedRng);
        _safeMint(dogOwner, newItemId);
        _setTokenURI(newItemId, s_dogTokenUris[uint256(dogBreed)]);
        emit NftMinted(newItemId, dogBreed, dogOwner);
    }

    function getChanceArray() public pure returns (uint256[3] memory) {
        return [10, 40, MAX_CHANCE_VALUE];
    }

    function _initializeContract(string[3] memory dogTokenUris) private {
        if (s_initialized) {
            revert RandomIpfsNft__AlreadyInitialized();
        }
        s_dogTokenUris = dogTokenUris;
        s_initialized = true;
    }

    function getBreedFromModdedRng(
        uint256 moddedRng
    ) public pure returns (Breed) {
        uint256 cumulativeSum = 0;
        uint256[3] memory chanceArray = getChanceArray();
        for (uint256 i = 0; i < chanceArray.length; i++) {
            // Pug = 0 - 9  (10%)
            // Shiba-inu = 10 - 39  (30%)
            // St. Bernard = 40 = 99 (60%)
            if (moddedRng >= cumulativeSum && moddedRng < chanceArray[i]) {
                return Breed(i);
            }
            cumulativeSum = chanceArray[i];
        }
        revert RandomIpfsNft__RangeOutOfBounds();
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert RandomIpfsNft__TransferFailed();
        }
    }

    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    function getDogTokenUris(
        uint256 index
    ) public view returns (string memory) {
        return s_dogTokenUris[index];
    }

    function getInitialized() public view returns (bool) {
        return s_initialized;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
