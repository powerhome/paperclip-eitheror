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

  let(:user_with_storage_alias) do
    ActiveRecord::Base.connection.execute("INSERT into users (id, avatar_file_name, avatar_content_type) values (998, 'image.jpg', 'image/jpg')")
    UserWithStorageAlias.find(998)
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

  context 'when "either" is available' do
    before { FileUtils.cp(source_image_path, primary_image_path) }
    subject(:avatar) { user_with_storage_alias.avatar }

    it 'deletes unknown call to "either" storage' do
      either_storage = double
      allow(either_storage).to receive(:exists?).and_return true
      expect(either_storage).to receive(:some_unknown_method).and_return('some response')

      avatar.instance_variable_set(:@either, either_storage)

      expect(avatar.some_unknown_method).to eq 'some response'
    end

    context 'and an alias is set' do
      it 'uses the aliased method' do
        either_storage = avatar.instance_variable_get(:@either)
        either_storage.stub(:either_handler)

        expect(either_storage).to receive(:either_handler).with(:params)

        avatar.only_on_or(:params)
      end

      context 'and the alias is to a lambda' do
        it 'calls the lambda with both storages and any extra arguments' do
          avatar.either_lambda_alias(:param)

          either_storage = avatar.instance_variable_get(:@either)
          or_storage = avatar.instance_variable_get(:@or)

          expect(UserWithStorageAlias.instance_variable_get(:@either_lambda_called_with)).to eql [either_storage, or_storage, avatar, :param]
        end
      end
    end
  end

  context 'when "either" is not available' do
    subject(:avatar) { user_with_storage_alias.avatar }
    context 'but "or" is' do
      before(:each) { FileUtils.cp(source_image_path, fallback_image_path)}

      it 'fallsback to "or" storage' do
        expect(avatar.path).to match fallback_storage_path
        expect(avatar.url).to match fallback_storage_url
      end

      context 'and an alias is set on "or"' do
        it 'uses the aliased method' do
          or_storage = avatar.instance_variable_get(:@or)
          or_storage.stub(:or_handler)

          expect(or_storage).to receive(:or_handler).with(:param)

          avatar.only_on_either(:param)
        end

        context 'and the alias is to a lambda' do
          it 'calls the lambda with both storages and any extra arguments' do
            avatar.either_lambda_alias(:param)

            either_storage = avatar.instance_variable_get(:@either)
            or_storage = avatar.instance_variable_get(:@or)

            expect(UserWithStorageAlias.instance_variable_get(:@either_lambda_called_with)).to eql [either_storage, or_storage, avatar, :param]
          end
        end
      end
    end

    it 'delegates unknown calls to "or" storage' do
      or_storage = double
      allow(or_storage).to receive(:exists?).and_return true
      expect(or_storage).to receive(:an_unknown_method).and_return('some result')

      avatar.instance_variable_set(:@or, or_storage)

      expect(avatar.an_unknown_method).to eq 'some result'
    end
  end

  describe '#sync' do
    before { FileUtils.cp(source_image_path, fallback_image_path) }

    it 'copies asset from the "or" over to the "either" storage' do
      synced = user.avatar.sync

      expect(synced).to be_truthy
      expect(user.avatar.path).to match /primary_storage/
      expect(File.exists? user.avatar.path).to be_truthy
    end
  end

  describe '#synced?' do
    context 'when asset is not in the "either" storage' do
      it { expect(user.avatar).to_not be_synced }
    end

    context 'when asset is in the "either" storage' do
      before { FileUtils.cp(source_image_path, primary_storage_path) }
      it { expect(user.avatar).to be_synced }
    end
  end
end
