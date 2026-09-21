require_relative 'spec_helper'
require "tmpdir"

RSpec.describe RbsEnum do
  describe ".values" do
    it "keeps quoted hash characters and stops at the next declaration" do
      Dir.mktmpdir("rbs-enum") do |root|
        File.write(File.join(root, "types.rbs"), <<~RBS)
          type Widget::Kind = :small | :'large#x' # trailing comment
          type Widget::Next = :next
        RBS

        expect(described_class.values("Widget::Kind", sig_root: root)).to eq([:small, :"large#x"])
      end
    end

    it "isolates caches for configured signature roots" do
      Dir.mktmpdir("rbs-enum-a") do |first|
        Dir.mktmpdir("rbs-enum-b") do |second|
          File.write(File.join(first, "types.rbs"), "type Widget::Kind = :first\n")
          File.write(File.join(second, "types.rbs"), "type Widget::Kind = :second\n")

          expect(described_class.values("Widget::Kind", sig_root: first)).to eq([:first])
          expect(described_class.values("Widget::Kind", sig_root: second)).to eq([:second])
        end
      end
    end

    context "with single-line symbol unions" do
      it "returns symbols for ButtonComponent::Color" do
        values = described_class.values("ButtonComponent::Color")
        expect(values).to include(:primary, :warning, :danger, :success, :info)
        expect(values).to all(be_a(Symbol))
      end

      it "returns symbols for ButtonComponent::Size including :'2xl'" do
        values = described_class.values("ButtonComponent::Size")
        expect(values).to include(:sm, :md, :lg, :'2xl')
      end

      it "returns symbols for ButtonComponent::Variant and Shape" do
        expect(described_class.values("ButtonComponent::Variant")).to include(:outline, :solid, :ghost, :tonal)
        expect(described_class.values("ButtonComponent::Shape")).to include(:square, :rounded, :pill, :circle)
      end
    end

    context "with multi-line unions with comments" do
      it "returns symbols for IconComponent::NameSymbol" do
        values = described_class.values("IconComponent::NameSymbol")
        expect(values).to include(:ruby, :rails, :javascript)
        expect(values).to include(:'arrow-right', :'arrow-left')
        expect(values).to all(be_a(Symbol))
      end

      it "returns strings for IconComponent::NameString" do
        values = described_class.values("IconComponent::NameString")
        expect(values).to include("ruby", "rails", "javascript")
        expect(values).to include("arrow-right", "arrow-left")
        expect(values).to all(be_a(String))
      end
    end

    context "caching" do
      it "can be cleared between calls" do
        first = described_class.values("ButtonComponent::Color")
        described_class.clear_cache!
        second = described_class.values("ButtonComponent::Color")
        expect(second).to eq(first)
      end
    end

    context "strict lookups" do
      it "returns an empty array for an unknown alias by default" do
        expect(described_class.values("ButtonComponent::Missing")).to eq([])
      end

      it "raises UnknownType for an unknown alias when strict" do
        expect { described_class.values("ButtonComponent::Missing", strict: true) }
          .to raise_error(RbsEnum::UnknownType, /ButtonComponent::Missing/)
      end

      it "returns the union for a known alias when strict" do
        values = described_class.values("ButtonComponent::Color", strict: true)
        expect(values).to include(:primary, :warning)
      end

      it "raises for an unknown alias when the configured default is strict" do
        described_class.configure { |config| config.strict = true }

        expect { described_class.values("ButtonComponent::Missing") }
          .to raise_error(RbsEnum::UnknownType)
      end

      it "lets a per-call strict: false override a strict default" do
        described_class.configure { |config| config.strict = true }

        expect(described_class.values("ButtonComponent::Missing", strict: false)).to eq([])
      end

      it "does not cache an empty result when the strict lookup raises" do
        expect { described_class.values("ButtonComponent::Missing", strict: true) }
          .to raise_error(RbsEnum::UnknownType)
        expect { described_class.values("ButtonComponent::Missing", strict: true) }
          .to raise_error(RbsEnum::UnknownType)
      end

      it "raises when no signature root is set at all" do
        described_class.sig_root = nil

        expect { described_class.values("ButtonComponent::Color", strict: true) }
          .to raise_error(RbsEnum::UnknownType)
      ensure
        described_class.sig_root = File.expand_path("fixtures", __dir__)
      end
    end
  end
end
