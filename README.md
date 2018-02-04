# X32 channel view

Shows the mute state and meter level for all input channels to a Behringer X32 sound desk.

## Setup
To install all the dependencies, run:

```
bundle install
```

Next the app requires some env vars for configuration. A sample `.env.sample` is provided for running the app locally. You can copy `.env.sample` to `.env` which foreman will pick up.

Using foreman we can boot the application.

```
$ foreman start
```

You can now visit <http://localhost:5000> to see the application.

## Useful development links
 - https://sites.google.com/site/patrickmaillot/x32
 - https://github.com/pmaillot/X32-Behringer

