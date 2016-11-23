require 'spec_helper'

describe Paperclip::Storage::Eitheror do
  let(:fallback_user) do
    ActiveRecord::Base.connection.execute("INSERT into users (id, avatar_file_name, avatar_content_type) values (999, 'fallback.png', 'image/png')")
    User.find(999)
  end

  after(:each) do
    User.delete_all
    File.delete('spec/primary_storage/users/avatars/original/image.jpg') if File.exists?('spec/primary_storage/users/avatars/original/image.jpg')

    File.delete('spec/fallback_storage/users/avatars/original/image.jpg') if File.exists?('spec/fallback_storage/users/avatars/original/image.jpg')
  end

  context 'when creating a new attachment' do
    it 'uses the primary storage' do
      user = User.create avatar: File.open('spec/image.jpg')

      expect(user.avatar.path).to match /primary_storage/
      expect(File.exists? user.avatar.path).to be true
    end
  end

  context 'when deleting' do
    it 'deletes from both storages' do
      user = User.create avatar: File.open('spec/image.jpg')
      primary_storage_path = 'spec/primary_storage/users/avatars/original/image.jpg'
      fallback_storage_path = 'spec/fallback_storage/users/avatars/original/image.jpg'
      FileUtils.cp(primary_storage_path, fallback_storage_path)

      expect(File.exists?(user.avatar.path)).to be true

      user.destroy

      expect(File.exists?(primary_storage_path)).to be false
      expect(File.exists?(fallback_storage_path)).to be false
    end
  end

  context 'when "either" is not available' do
    it 'fallsback to "or" storage' do
      expect(fallback_user.avatar.path).to match /fallback_storage/
    end

    it 'delegates calls to "or" storage' do
      or_storage = double
      allow(or_storage).to receive(:exists?).and_return true
      expect(or_storage).to receive(:public_url).and_return('a public url')
      user = fallback_user
      user.avatar.instance_variable_set(:@or, or_storage)

      expect(user.avatar.public_url).to eq 'a public url'
    end
  end
end
