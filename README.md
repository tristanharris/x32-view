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

##Using Docker

Build:
Copy and edit the `.env.sample` to `.env` (leave the PORT set to 5000)
```
docker build . -t x32-view
```

Run:
docker
```
run -it --rm -p 5000:5000 x32-view
```

## Useful development links
 - https://sites.google.com/site/patrickmaillot/x32
 - https://github.com/pmaillot/X32-Behringer

