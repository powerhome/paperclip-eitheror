$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "paperclip-eitheror"

require 'active_record'
require 'paperclip'
require 'byebug'

Dir['spec/fixtures/*.rb'].each do |f|
  require_relative "../#{f}"
end

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.suppress_messages do
  ActiveRecord::Schema.define version: 0 do
    create_table :users, force: true do |t|
      t.boolean :eitheror
      t.string :avatar_file_name
      t.string :avatar_content_type
    end
  end
end

Paperclip.options[:log] = false
Paperclip.interpolates(:rails_root) do |a, _|
  Dir.tmpdir
end
