# DEPRECATED

This bot is no longer maintained, probably never will be. It's successor is 
https://github.com/512mb-org/512mb.org-bot - the official bot of the 512mb.org server

# Suppa Bot

Suppa Bot is a plugin based multi-purpose discord bot written in Lua.
It features a highly customizable environment, scripting, cron-like tasks for commands, and more.

## Installation

This bot runs on [luvit](https://luvit.io) framework using [discordia library](https://github.com/SinisterRectus/discordia)

The installation process should be performed from within the root directory of this bot

First, [install luvit runtime](https://luvit.io/install.html) and discordia library using lit.
```
lit install SinisterRectus/discordia
```
Then, place the token for your bot into the "./token" file (newlines excluded).

Lastly, enable the plugins you need on your Discord server using the ``enable`` command. <br />
To see which plugins are available, use the ``plugins`` command. <br />
Default prefix for every server is ``/``

## Wiki

This bot has its own [wiki](https://github.com/yessiest/SuppaBot/wiki) page for explanations that don't fit into a single embed.

## Contribute
<details>
<summary> Preface </summary>
Preferrably, don't.
I'm not saying you can't, I'm saying you shouldn't.
The code itself is a flaming mess, and, probably, it will remain in that state.
</details>

However, if you are willing to contribute for some particular reason,
be it your will to fix the code or fix a typo in the readme or something else,
feel free to do anything you like to and send a pull request afterwards.

## Versioning conventions

```
Major.Minor.patch
```

## License

This bot's source code, and subsequent parts of it are all licensed under the [MIT license](https://mit-license.org)
