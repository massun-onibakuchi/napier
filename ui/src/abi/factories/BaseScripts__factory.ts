/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type { BaseScripts, BaseScriptsInterface } from "../BaseScripts";

const _abi = [
  {
    inputs: [],
    name: "IS_SCRIPT",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "vm",
    outputs: [
      {
        internalType: "contract Vm",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];

export class BaseScripts__factory {
  static readonly abi = _abi;
  static createInterface(): BaseScriptsInterface {
    return new utils.Interface(_abi) as BaseScriptsInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): BaseScripts {
    return new Contract(address, _abi, signerOrProvider) as BaseScripts;
  }
}
