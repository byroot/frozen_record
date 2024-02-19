require 'spec_helper'

describe 'test fixture loading' do
  describe 'by default' do
    it 'uses the default fixtures' do
      expect(Country.count).to be == 3
    end
  end

  describe '.load_fixture' do
    it 'uses alternate test fixtures' do
      test_fixtures_base_path = File.join(File.dirname(__FILE__), 'fixtures', 'test_helper')

      FrozenRecord::TestHelper.load_fixture(Country, test_fixtures_base_path)
      expect(Country.count).to be == 1

      FrozenRecord::TestHelper.unload_fixtures # Note: This is called just to ensure a clean teardown between tests.
    end

    it 'raises an ArgumentError if the model class does not inherit from FrozenRecord::Base' do
      expect {
        some_class = Class.new
        FrozenRecord::TestHelper.load_fixture(some_class, 'some/path')
      }.to raise_error(ArgumentError)
    end

    it 'uses test fixtures that were loaded first, and ignores repeat calls to load_fixture' do
      test_fixtures_base_path = File.join(File.dirname(__FILE__), 'fixtures', 'test_helper')
      FrozenRecord::TestHelper.load_fixture(Country, test_fixtures_base_path)
      expect(Country.count).to be == 1

      # Note: If we actually loaded this fixture, we'd expect 3 Countries to be loaded. Instead, we continue to get 3.
      test_fixtures_base_path = File.join(File.dirname(__FILE__), 'fixtures')
      FrozenRecord::TestHelper.load_fixture(Country, test_fixtures_base_path)
      expect(Country.count).to be == 1

      FrozenRecord::TestHelper.unload_fixtures
    end
  end

  describe '.unload_fixture' do
    it 'restores the default fixtures for the specified model class' do
      test_fixtures_base_path = File.join(File.dirname(__FILE__), 'fixtures', 'test_helper')

      FrozenRecord::TestHelper.load_fixture(Continent, test_fixtures_base_path)
      FrozenRecord::TestHelper.load_fixture(Country, test_fixtures_base_path)
      FrozenRecord::TestHelper.unload_fixture(Country)

      expect(Continent.count).to be == 1
      expect(Country.count).to be == 3
    end

    context "when the test fixture does not exist in normal base path" do
      class OnlyInTest < FrozenRecord::Base; end
      before do
        test_fixtures_base_path = File.join(File.dirname(__FILE__), 'fixtures', 'test_helper')
        FrozenRecord::TestHelper.load_fixture(OnlyInTest, test_fixtures_base_path)
      end
      it 'unload fixture gracefully recovers from an ' do

        expect { FrozenRecord::TestHelper.unload_fixture(OnlyInTest) }.not_to raise_error
      end
    end
  end

  describe '.unload_fixtures' do
    it 'restores the default fixtures' do
      test_fixtures_base_path = File.join(File.dirname(__FILE__), 'fixtures', 'test_helper')

      FrozenRecord::TestHelper.load_fixture(Continent, test_fixtures_base_path)
      FrozenRecord::TestHelper.load_fixture(Country, test_fixtures_base_path)
      FrozenRecord::TestHelper.unload_fixtures

      expect(Continent.count).to be == 3
      expect(Country.count).to be == 3
    end

    it 'does has no effect if no alternate fixtures were loaded' do
      FrozenRecord::TestHelper.unload_fixtures

      expect(Continent.count).to be == 3
      expect(Country.count).to be == 3
    end
  end
end
