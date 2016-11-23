require 'spec_helper'

describe Paperclip::Storage::Eitheror do
  let(:source_image_path) { 'spec/image.jpg' }

  let(:primary_storage_url) { '/url/primary_storage' }
  let(:fallback_storage_url) { '/url/fallback_storage' }

  let!(:primary_storage_path) { 'spec/primary_storage' }
  let!(:fallback_storage_path) { 'spec/fallback_storage' }

  let(:primary_image_path) { "#{primary_storage_path}/image.jpg" }
  let(:fallback_image_path) { "#{fallback_storage_path}/image.jpg" }

  let(:user) do
    ActiveRecord::Base.connection.execute("INSERT into users (id, avatar_file_name, avatar_content_type) values (999, 'image.jpg', 'image/jpg')")
    User.find(999)
  end

  before(:each) do
    FileUtils.mkdir_p primary_storage_path
    FileUtils.mkdir_p fallback_storage_path
  end

  after(:each) do
    User.delete_all
    FileUtils.rm_rf(primary_storage_path)
    FileUtils.rm_rf(fallback_storage_path)
  end

  context 'when creating a new attachment' do
    it 'uses the primary storage' do
      user.avatar = File.open(source_image_path)
      user.save

      expect(user.avatar.path).to match primary_storage_path
      expect(user.avatar.url).to match primary_storage_url
      expect(File.exists? user.avatar.path).to be true
    end
  end

  describe '#exists?' do
    subject(:avatar) { user.avatar }

    context 'when attachment is on "either"' do
      before { FileUtils.cp(source_image_path, primary_image_path) }
      it { expect(avatar.exists?).to be_truthy }
    end

    context 'when attachment is on "or"' do
      before { FileUtils.cp(source_image_path, fallback_image_path) }
      it { expect(avatar.exists?).to be_truthy }
    end

    context "when attachment isn't anywhere" do
      it { expect(avatar.exists?).to be_falsy }
      end
  end

  context 'when deleting' do
    it 'deletes from both storages' do
      FileUtils.cp(source_image_path, primary_image_path)
      FileUtils.cp(source_image_path, fallback_image_path)

      user.destroy

      expect(File.exists?(primary_image_path)).to be false
      expect(File.exists?(fallback_image_path)).to be false
    end
  end

  context 'when "either" is not available' do
    context 'but "or" is' do

      before(:each) { FileUtils.cp(source_image_path, fallback_image_path)}

      it 'fallsback to "or" storage' do
        expect(user.avatar.path).to match fallback_storage_path
        expect(user.avatar.url).to match fallback_storage_url
      end
    end

    it 'delegates calls to "or" storage' do
      or_storage = double
      allow(or_storage).to receive(:exists?).and_return true
      expect(or_storage).to receive(:public_url).and_return('a public url')
      user.avatar.instance_variable_set(:@or, or_storage)

      expect(user.avatar.public_url).to eq 'a public url'
    end
  end
end
