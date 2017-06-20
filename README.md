# COTA FORK

This fork differs from the original upstream in three different ways. 

1. new directories
	- debian

2. modified directories
	- etc

3. modified files
	- Makefile

## Requirements

```sh
sudo apt-get install git gnupg-agent build-essential libsystemd-dev
```

and

```
Go (>=1.8.3)
```

and

a valid __journalbeat.yml__**

and

Goes without saying `GOROOT`, `GOPATH` environment variables and have both be callable by sudo.

and

a properly signed and configured gpg key.

## How to use this ?

```sh
# you need gpg-agent to sign you deb file
# import a valid gpg public, private keys of user define in debian/control
eval $(gpg-agent --daemon)
gpg --import public.key
gpg --import -allow-secret-key-import private.key
# other stuff
git clone <URL>/journalbeat
cd journalbeat
debuild
```

## How to configure journalbeat ?

In order of preference

- Creates a symlink of you config file to __/etc/journalbeat/journalbeat.yml__

OR

- In etc/journalbeat.default file, modifies JOURNAL_BEAT_CONFIG_FILE_PATH

OR

- Modifies __etc/journalbeat.service__

OR

- Modifies __etc/journalbeat.yml__ file

## How to run the beat as a systemd service ?

```sh
dpkg -i <journalbeat_name>.deb
sudo systemctl enable journalbeat.service
sudo systemctl start journalbeat.service
```

## How to update upstream ?

```sh
git remote add upstream https://github.com/mheese/journalbeat
git pull upstream
```

You will most definitely have merge conflicts in [.gitignore, etc/, Makefile]. But it is expected.

KEEP:
- Makefile
- etc/journalbeat.default
- etc/journalbeat.service
- .gitignore

It is unlikely the debian/ directory will conflict with any upstream changes.

## How to remove this ?

```sh
sudo apt-get purge journalbeat -y
rm -rf /usr/local/journalbeat
```

## Do I need Go to run this ?

No

## How this works ?

### Makefile

The _Makefile_** is consist of 2 parts.

The first part is mostly internal, used for building purposes.
While the second part is used almost exclusively by the debian packaging engine `dh binary` or `debuild` depends on your preference.

__Makefile Internal__

A modified copy of cloudflare's hellogopher/Makefile.

The Makefile is basically a packaging toolkit that downloads all third party dependencies into a .GOPATH directory locally. 

After all dependencies is packaged in .GOPATH, the Makefile will then execute `go install`, which compile the actual executable binary in a newly created directory call `bin` locally.

__Makefile Debian__

this section is used by debuild.

Words from debian god or when you want to know more. (https://www.debian.org/doc/manuals/maint-guide/)

`debuild` is basically a command and control tool that used to invoke a collection of dh_* commands. It is in all those sequence of dh_* commands that our Makefile will be invoked.

[Example] ~ this calls make build in our Makefile
`debuild dh_auto_build` == `make build`

The sequence of commands and how debuild behaves are dictated by `debian/rules` in it you will see what are being run and what are being ignored. 

`dh $@` basically means that we are telling debuild to run all dh_* commands.

### debian directory

The __debian__** directory is use by the debian packaging tool `debuild` and the likes to store state and configuration files.

__debian/rules__ is where you configures how debuild behaves.

__debian/install__ is where you configures dpkg where you want to install dependent files.

__debian/control__ is the README.md equivalence for dpkg


### Remark

look through `debian/rules`, `Makefiles`, `debian/install`, `etc/journalbeat.service`, and `etc/journalbeat.default` should give you enough information to know how this works

__.GOPATH__**

It is important for GOPATH to be moved to the debian target directory. If not, the compiled `journalbeat` will throw an exception and fail.

---


[![Build Status](https://travis-ci.org/mheese/journalbeat.svg?branch=master)](https://travis-ci.org/mheese/journalbeat)

# Journalbeat

Journalbeat is the [Beat](https://www.elastic.co/products/beats) used for log
shipping from systemd/journald based Linux systems. It follows the system journal
very much like `journalctl -f` and sends the data to Logstash/Elasticsearch (or
whatever you configured for your beat).

Journalbeat is targeting pure systemd distributions like CoreOS, Atomic Host, or
others. There are no intentions to add support for older systems that do not use
journald.

## Use Cases and Goals

Besides from the obvious use case (log shipping) the goal of this project is also
to provide a common source for more advanced topics like:
- FIM (File Integrity Monitoring)
- SIEM
- Audit Logs / Monitoring

This is all possible because of the tight integration of the Linux audit events
into journald. That said _journalbeat_ can only provide the data source for
these more advanced use cases. We need to develop additional pieces for
monitoring and alerting - as well as hopefully a standardized Kibana dashboard
to cover these features.

## Documentation

None so far. As of this writing, this is the first commit. There are things to
come. You can find a `journalbeat.yml` config file in the `etc` folder which
should be self-explanatory for the time being.

## Install

You need to install `systemd` development packages beforehand. In a
RHEL or Fedora environment, you need to install the `systemd-devel` package, `libsystemd-dev` in debian-based systems, et al.

`go get github.com/mheese/journalbeat`

**NOTE:** This is not the preferred way from Elastic on how to do it. Needs to
be revised (of course).

## Caveats

A few current caveats with journalbeat

### cgo

The underlying system library [go-systemd](https://github.com/coreos/go-systemd) makes heavy usage of cgo and the final binary will be linked against all client libraries that are needed in order to interact with sd-journal. That means that
the resulting binary is not really Linux distribution independent (which is kind of expected in a way).
