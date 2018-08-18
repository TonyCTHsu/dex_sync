# DexSync

DexSync is a simple automated tool for downloading and updating multiple configurations from [Dex App](https://github.com/honestbee/dex-app) at honestbee, which is used to grant developer kubernetes access. DexSync requires minimal configuration of the user's github cookie sessions, since honestbee adopts Github stable connector for user authentication at the moment.

## Installation

Install it yourself as:

    $ gem install dex_sync

## Usage

DexSync requires some configuration setup at the first time. Keeping `USER_SESSION ` and `GH_SESSION` in the configuration file up-to-date should be sufficient for follow-up execution.

* Create dex_sync configuration `dex_sync.yaml`, under home directory.

```
$ touch ~/dex_sync.yaml
```

* Create a directory for storing the downloaded configuration.

```
$ mkdir ~/.kubeconfigs
```

* Setup the configuration based on usage context.

	* **DEX** is the url path of your dex app.
	* **DOWNLOAD_PATH** is the path of the directory for storing the downloaded configuration. It is not mandatory, the default is set as `~/.kubeconfigs`.
	* **CLUSTERS** is a list names of your kubernetes clusters.
	* **NAMESPACES** is a list names of your kubernetes namespaces in the cluster.
	* **USER_SESSION** is your user session of Github. Copy and paste it from your browser cookie `user_session`.
	* **GH_SESSION** is your github session. Copy and paste it from your browser cookie `_gh_session`.

An example for `dex_sync.yaml`

```
DEX: http://my-dex-app.com/
DOWNLOAD_PATH: ~/.kubeconfigs
CLUSTERS:
  - cluster-1
  - cluster-2
NAMESPACES:
  - backend
  - data
USER_SESSION: ASDASDASDASD....
GH_SESSION: QWERTQWERT.....................
```

* Execute command in terminal to download the configurations.

```
$ dex_sync
```

**Note:** Unlike `USER_SESSION`, `GH_SESSION` is very likely to change frequently, ie: refreshing the browser. You may check `GH_SESSION` and keep it up-to-date when the configuration is not working.

**Note:** Repetitively executing the command within a short period of time might result in error. For security concern, the server identifies user having abnormal activity for requesting access too frequently, you would have to reauthorize through browser to continue the automated flow.


* After execution, configurations are downloaded in your designated directory. 

```
$ ls ~/.kubeconfigs
```

* Concatenate those files and export `$KUBECONFIG`, and you are able to access to kubernetes

In `~/.bashrc`

```
export KUBECONFIG=$KUBECONFIG:$HOME/.kubeconfigs/config-1
export KUBECONFIG=$KUBECONFIG:$HOME/.kubeconfigs/config-2
...
..
```

```
$ kubectl config get-contexts
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/TonyCTHsu/dex_sync. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DexSync project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/TonyCTHsu/dex_sync/blob/master/CODE_OF_CONDUCT.md).
