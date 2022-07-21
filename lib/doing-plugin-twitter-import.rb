# frozen_string_literal: true

# title: Twitter Import
# description: Import entries from a Twitter timeline
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  # Capture Thing import plugin
  class TwitterImport
    require 'time'
    require 'twitter'

    include Doing::Util
    include Doing::Errors

    def self.settings
      {
        trigger: '^tw(?:itter)?$',
        config: { 'api_key' => 'xxxxx', 'api_secret' => 'xxxxx', 'user' => 'xxxxx' }
      }
    end

    ##
    ## Imports a Capture Thing folder
    ##
    ## @param      wwid     [WWID] WWID object
    ## @param      path     [String] Path to Capture Thing folder
    ## @param      options  [Hash] Additional Options
    ##
    def self.import(wwid, path, options: {})
      key = Doing.setting('plugins.twitter.api_key')
      secret = Doing.setting('plugins.twitter.api_secret')

      raise PluginException, 'Please add Twitter API key/secret to config. Run `doing config refresh` to add placeholders.' if key =~ /^xxxxx/

      user = Doing.setting('plugins.twitter.user')

      @client = Twitter::REST::Client.new do |config|
        config.consumer_key = key
        config.consumer_secret = secret
      end

      options[:no_overlap] = true
      options[:autotag] ||= wwid.auto_tag

      tags = options[:tag] ? options[:tag].split(/[ ,]+/).map { |t| t.sub(/^@?/, '') } : []
      options[:tag] = nil
      prefix = options[:prefix] || ''

      @old_items = wwid.content

      new_items = load_timeline(user, wwid, { prefix: prefix, tags: tags, section: options[:section], autotag: options[:autotag] })

      return if new_items.nil?

      total = new_items.count

      options[:count] = 0

      new_items = wwid.filter_items(new_items, opt: options)

      skipped = total - new_items.count
      Doing.logger.debug('Skipped:' , %(#{skipped} items that didn't match filter criteria)) if skipped.positive?

      imported = []

      new_items.each do |item|
        next if duplicate?(item)

        imported.push(item)
      end

      dups = new_items.count - imported.count
      Doing.logger.info('Skipped:', %(#{dups} duplicate items)) if dups.positive?

      imported = wwid.dedup(imported, no_overlap: !options[:overlap])
      overlaps = new_items.count - imported.count - dups
      Doing.logger.debug('Skipped:', "#{overlaps} items with overlapping times") if overlaps.positive?

      imported.each do |item|
        wwid.content.add_section(item.section)
        wwid.content.push(item)
      end

      Doing.logger.info('Imported:', "#{imported.count} items")
    end

    def self.duplicate?(item)
      @old_items.each do |oi|
        return true if item.equal?(oi)
      end

      false
    end

    def self.load_timeline(user, wwid, options)
      config_dir = File.join(Util.user_home, '.config', 'doing')
      id_storage = File.join(config_dir, 'last_tweet_id')
      Doing.logger.log_now(:info, 'Twitter:', "retrieving timeline for #{user}")

      if File.exist?(id_storage)
        last_id = IO.read(id_storage).strip.to_i
      else
        last_id = nil
      end

      tweet_options = {
        count: 200,
        include_rts: true,
        exclude_replies: true
      }
      tweet_options[:since_id] = last_id if last_id

      tweets = @client.user_timeline(user, tweet_options).map do |t|
        { date: t[:created_at], title: t[:text], id: t[:id] }
      end
      if !tweets.nil? && tweets.count.positive?
        Doing.logger.log_now(:info, 'Twitter:', "found #{tweets.count} new tweets")
      else
        Doing.logger.log_now(:info, 'Twitter:', 'no new tweets found')
        return
      end

      items = []

      tweets.reverse.each do |tweet|
        last_id = tweet[:id] if tweet[:id]
        date = Time.parse(tweet[:date].strftime('%Y-%m-%d %H:%M'))
        text = tweet[:title].dup
        text = text.force_encoding('utf-8') if text.respond_to? :force_encoding
        input = text.split("\n")
        title = input[0]
        note = Note.new(input.slice(1, input.count))

        title = "#{options[:prefix]} #{title} @done"
        options[:tags].each do |tag|
          if title =~ /\b#{tag}\b/i
            title.sub!(/\b#{tag}\b/i, "@#{tag}")
          else
            title += " @#{tag}"
          end
        end
        title = wwid.autotag(title) if options[:autotag]
        title.gsub!(/ +/, ' ')
        title.strip!
        section = options[:section] || wwid.config['current_section']

        new_item = Item.new(date, title, section)
        new_item.note = note

        items << new_item if new_item
      end

      FileUtils.mkdir(config_dir) unless File.exist?(config_dir)
      File.open(id_storage, 'w+') do |f|
        f.puts last_id
      end

      items
    end

    Doing::Plugins.register 'twitter', :import, self
  end
end
