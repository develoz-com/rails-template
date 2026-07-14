# frozen_string_literal: true

RSpec.describe Develoz do
  it "has a version number" do
    expect(Develoz::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end

  describe "::VERSION" do
    it "is a string" do
      expect(Develoz::VERSION).to be_a(String)
    end

    it "is not empty" do
      expect(Develoz::VERSION).not_to be_empty
    end
  end

  describe Develoz::CLI do
    describe "#version" do
      it "outputs the version" do
        cli = described_class.new
        expect { cli.version }.to output(/develoz \d+\.\d+\.\d+/).to_stdout
      end
    end
  end
end
