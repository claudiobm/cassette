

describe Cassette do
  def keeping_logger(&block)
    original_logger = Cassette.logger
    block.call
    Cassette.logger = original_logger
  end

  describe '.config' do
    it 'defines Cassette initial configuration based on a OpenStruct' do

      config = OpenStruct.new(
        YAML.load_file('spec/config.yml')
      )

      Cassette.config = config

      expect(Cassette.config)
        .to eq(config)
    end

    context 'when tls_version was not specified' do
      it 'uses default TLS version: TLSv1_2' do
        config = OpenStruct.new(
          YAML.load_file('spec/config.yml')
        )

        # Removing tls_version field
        config.delete_field(:tls_version)

        Cassette.config = config

        expect(Cassette.config.tls_version)
          .to eq('TLSv1_2')
      end
    end

    context 'when tls_version is specified' do
      it 'uses this version' do
        config = OpenStruct.new(
          YAML.load_file('spec/config.yml')
        )

        Cassette.config = config

        expect(Cassette.config.tls_version)
          .to eq('TLSv1_2')
      end
    end

    context 'when verify_ssl was not specified' do
      it 'uses default verify_ssl value: false' do
        config = OpenStruct.new(
          YAML.load_file('spec/config.yml')
        )

        # Removing verify_ssl field
        config.delete_field(:verify_ssl)

        Cassette.config = config

        expect(Cassette.config.verify_ssl)
          .to be false
      end
    end

    context 'when verify_ssl is specified' do
      it 'uses this value' do
        config = OpenStruct.new(
          YAML.load_file('spec/config.yml')
        )

        Cassette.config = config

        expect(Cassette.config.verify_ssl)
          .to be true
      end
    end
  end

  describe '.logger' do
    it 'returns a default instance' do
      expect(Cassette.logger).not_to be_nil
      expect(Cassette.logger.is_a?(Logger)).to eql(true)
    end

    it 'returns rails logger when Rails is available' do
      keeping_logger do
        Cassette.logger = nil
        rails = double('Rails')
        expect(rails).to receive(:logger).and_return(rails).at_least(:once)
        stub_const('Rails', rails)
        expect(Cassette.logger).to eql(rails)
      end
    end
  end

  describe '.logger=' do
    let(:logger) { Logger.new(STDOUT) }
    it 'defines the logger instance' do
      keeping_logger do
        Cassette.logger = logger
        expect(Cassette.logger).to eq(logger)
      end
    end
  end

  describe '.cache_backend' do
    context 'when the cache_backend is already set' do
      it 'returns the cache_backend set' do
        new_cache = double('cache_backend')
        described_class.cache_backend = new_cache

        # exercise and verify
        expect(described_class.cache_backend).to eq(new_cache)

        # tear down
        described_class.cache_backend = nil
      end
    end

    context 'when the cache_backend is not set' do
      it 'returns Rails.cache if set' do
        described_class.cache_backend = nil
        rails_cache = double('cache')
        rails = double('Rails')
        allow(rails).to receive(:cache).and_return(rails_cache)
        stub_const('Rails', rails)

        # exercise and verify
        expect(described_class.cache_backend).to eq(rails_cache)

        # tear down
        described_class.cache_backend = nil
      end

      it 'returns MemoryStore if Rails.cache not set' do
        described_class.cache_backend = nil

        # exercise and verify
        expect(described_class.cache_backend).to be_a(ActiveSupport::Cache::MemoryStore)

        # tear down
        described_class.cache_backend = nil
      end

      it 'returns NullStore if Rails.cache and MemoryStore are not set' do
        described_class.cache_backend = nil
        hide_const('ActiveSupport::Cache::MemoryStore')
        require 'cassette/cache/null_store'

        # exercise and verify
        expect(described_class.cache_backend).to be_a(Cassette::Cache::NullStore)

        # tear down
        described_class.cache_backend = nil
      end
    end
  end
end
