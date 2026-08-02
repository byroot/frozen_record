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

    it 'raises when alternate fixtures are missing attributes' do
      original_base_path = Country.base_path
      test_fixtures_base_path = File.join(File.dirname(__FILE__), 'fixtures', 'test_helper', 'missing_attributes')

      expect {
        FrozenRecord::TestHelper.load_fixture(Country, test_fixtures_base_path)
      }.to raise_error(
        FrozenRecord::TestHelper::FixtureAttributeMismatch,
        'Country fixture attributes do not match (missing: nato)'
      )

      expect(Country.base_path).to eq(original_base_path)
      expect(Country.count).to be == 3
    end

    it 'raises when alternate fixtures have unexpected attributes' do
      original_base_path = Country.base_path
      test_fixtures_base_path = File.join(File.dirname(__FILE__), 'fixtures', 'test_helper', 'unexpected_attributes')

      expect {
        FrozenRecord::TestHelper.load_fixture(Country, test_fixtures_base_path)
      }.to raise_error(
        FrozenRecord::TestHelper::FixtureAttributeMismatch,
        'Country fixture attributes do not match (unexpected: region_code)'
      )

      expect(Country.base_path).to eq(original_base_path)
      expect(Country.count).to be == 3
    end

    it 'is a no-op when called again with the same path' do
      test_fixtures_base_path = File.join(File.dirname(__FILE__), 'fixtures', 'test_helper')
      FrozenRecord::TestHelper.load_fixture(Country, test_fixtures_base_path)
      expect(Country.count).to be == 1

      FrozenRecord::TestHelper.load_fixture(Country, test_fixtures_base_path)
      expect(Country.count).to be == 1

      FrozenRecord::TestHelper.unload_fixtures
    end

    it 'switches to the new fixtures when called with a different path' do
      test_fixtures_base_path = File.join(File.dirname(__FILE__), 'fixtures', 'test_helper')
      FrozenRecord::TestHelper.load_fixture(Country, test_fixtures_base_path)
      expect(Country.count).to be == 1

      default_fixtures_base_path = File.join(File.dirname(__FILE__), 'fixtures')
      FrozenRecord::TestHelper.load_fixture(Country, default_fixtures_base_path)
      expect(Country.count).to be == 3

      FrozenRecord::TestHelper.unload_fixtures
    end

    it 'preserves the original base_path for unload after switching paths' do
      original_base_path = Country.base_path

      test_fixtures_base_path = File.join(File.dirname(__FILE__), 'fixtures', 'test_helper')
      FrozenRecord::TestHelper.load_fixture(Country, test_fixtures_base_path)

      default_fixtures_base_path = File.join(File.dirname(__FILE__), 'fixtures')
      FrozenRecord::TestHelper.load_fixture(Country, default_fixtures_base_path)

      FrozenRecord::TestHelper.unload_fixtures
      expect(Country.base_path).to eq(original_base_path)
      expect(Country.count).to be == 3
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
