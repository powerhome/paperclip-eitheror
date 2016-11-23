require 'spec_helper'

describe Paperclip::Storage::Eitheror do

  after(:each) do
    User.delete_all
    File.delete('spec/primary_storage/users/avatars/original/image.jpg') if File.exists?('spec/primary_storage/users/avatars/original/image.jpg')
  end

  context 'when creating a new attachment' do
    it 'uses the primary storage' do
      user = User.create avatar: File.open('spec/image.jpg')

      expect(user.avatar.path).to match /primary_storage/
      expect(File.exists? user.avatar.path).to be true
    end
  end
end
