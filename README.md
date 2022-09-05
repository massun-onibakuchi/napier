# Napier

## Requirements

- [Foundry](https://book.getfoundry.sh/)

## Setup

You need access to an archive node like the free ones from [Alchemy](https://alchemyapi.io/). Create `.env` file and paste the RPC url.

Type:

```bash
cp .env.example .env
```

Then set the environment variable.

```
RPC_URL=<mainnet RRC URL>
```

## Compiling

Type:

```
forge build
```

## Testing

Type:

```
forge test -vvv --fork-url=$RPC_URL --fork-block-number=<block number>
```
