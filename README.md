# Doing plugin: Twitter Import

This is a plugin for [Doing](http://brettterpstra.com/projects/doing) which imports a user's tweets as Doing entries.

## Installation

Just run `gem install doing-plugin-twitter-import`. You may need to run with `sudo`, depending on your setup.

## Configuration

To set up, you need to [register an app with Twitter](https://apps.twitter.com/) and add its credentials to your Doing config. To create the config keys, run `doing config refresh`, then use `doing config open` to open the main `config.yml` file. You'll see the necessary fields (api_key, api_secret, and user) under the plugins->twitter section of the config.

The user key will probably be your own Twitter handle, but you could grab any user's tweets if you fancy.

## Usage

Once you have credentials set up, you can run an import:

	doing import --type twitter --tag twitter --prefix "Tweet: "

The `tag` and `prefix` options are entirely optional.

The first time you run it, it will grab the last 200 tweets, including retweets but excluding replies. It will store the id of the most recent tweet, and the next time you run the import, it will only get tweets newer than that tweet. The plugin will automatically avoid duplicating tweets in your Doing file.
