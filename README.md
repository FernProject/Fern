# FernOS

> [!IMPORTANT]
> READ THE [DOCS](docs/README.md)

> [!NOTE]
> Fern started just a couple of days ago, please don't expect usability for a while.<br>The installer won't be out for a while.

To skip the preamble:<br>
* [Functionality Disclaimer](#disclaimer)
* [Why Fern?](#why-fern)
* [Dependencies](#dependencies)
* [Building an ISO](#building)
* [Installation](#installation)
* [Licensing and AI](#licensing-and-ai)

<br>
Fern is a standalone GNU/Linux distribution; made because others pissed me off. Fern (when completed) aims to be **actually** user friendly without bloating your system. Fern aims to have an (optionally) completely offline install process. By default, we use our own init system, and don't have a package manager. However, in the installer, you choose any package manager from any distro, you can even pick multiple.
<br><br>

## Disclaimer

Fern has been in development for only a few days, it won't be usable for a few weeks. I also have school, so development may be slower than mainstream distros, unless users make pull requests.

## Why Fern?

Fern is a standalone GNU/Linux distribution that I'm making because I'm bored. I want to prove to my computer science teacher that GNU/Linux is better than Windows (which it is). But also, I'm annoyed with the way so many distros are handled. The vast majority of the time, you either have a heavily bloated, commercialised system (such as Ubuntu), or you have a very minimal system where you have to set up everything yourself. Fern aims to act as the middle ground between the two. My goal is to make an operating system capable of heavy feature customisation, while being easy to understand.<br>

Okay, boring. But, **why would you pick Fern?** If you're someone who wants to  know what's actually going on in your system, and wants to be able to change, add, remove, or update components quickly, that's Fern. The vision is simple: quickly opting in or out of features, choosing when to update without pestering, making your system as minimal or complex as you want; done easily. How? We'll be making a TUI tool that can show you all of these things, explaining everything in detail and why you might want it.

## Dependencies

In order to build the ISO, you must have the following on your host machine:

(basic):
* A GNU/Linux host computer
* An internet connection
* Bash shell
* GNU make

(packages):
* wget
* xorriso
* tar
* gzip
* nproc

Alternatively, you can download the latest ISO from the [release page](https://github.com/FernProject/Fern/releases) (if available).

## Building

> [!NOTE]
> Feature currently being developed.

Building an ISO is quite simple. First, clone the repository:

``git clone https://github.com/fernproject/fern``

Once inside the repo, run the following commands:

```
chmod +x build.sh
./build.sh
```

`build.sh` copies over the `base` folder into a `basefs`, which acts as the root for the system. It downloads prerequisites from the internet, and compiles them inside the `build` folder, before adding them into the system.

Once this process is finished, the script will pause, to ask you this:

``Make live ISO? [Y/n]``

Please note, typing `n`  or `no` will stop the script, and you will have to run the whole process again (wiping and recompiling your build) to make your ISO (or just do it manually).

> [!IMPORTANT]
> **DO NOT RUN `make`**! the makefile is used by the build script, and is not intended to be used by the user at any time (unless running `make clean`). Running `make` will not do anything.

If you do not want to go through the build process, check for the latest release on the [release page](https://github.com/fernproject/fern/releases)

## Installation

> [!NOTE]
> This feature has not been developed yet. 

## Licensing and AI

The [license](LICENSE) used by this repository is the [GNU General Public License V.3](https://www.gnu.org/licenses/gpl-3.0.html) because I completely agree with the Free Software movement, and the [Four Freedoms](https://www.gnu.org/philosophy/free-sw.en.html#four-freedoms) of free software. It is important to me that Fern upholds the values of free software.

A big part of that, to me, is the restriction of AI. The point of free software, open source, and even Github is to bring **humans** together in collaberation; not machines. That's why we have a very strict, non-permissing [AI Policy](docs/AI_POLICY.md). **IT IS IMPORTANT YOU READ THE [POLICY](docs/AI_POLICY.md)!**