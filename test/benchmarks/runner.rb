# frozen_string_literal: true

require "benchmark"

module Benchmarks
  class Context
    include ActiveRecord::TestFixtures
    include CommerceHelpers
    include QuillBotStub

    self.fixture_paths = [ Rails.root.join("test/fixtures") ]
    fixtures :all

    def initialize
      setup_fixtures
    end

    def name
      "benchmarks"
    end
  end

  class Runner
    Scenario = Struct.new(:name, :setup, :measure, keyword_init: true)

    def self.register(name, &block)
      scenarios << Scenario.new(name: name, setup: nil, measure: block)
    end

    def self.setup(name, &block)
      scenario = scenarios.find { |s| s.name == name }
      raise ArgumentError, "Unknown scenario: #{name}" unless scenario

      scenario.setup = block
    end

    def self.scenarios
      @scenarios ||= []
    end

    def self.run(filter: nil)
      new(filter: filter).run
    end

    def initialize(filter: nil)
      @filter = filter
      @warmup = ENV.fetch("BENCHMARK_WARMUP", 2).to_i
      @iterations = ENV.fetch("BENCHMARK_ITERATIONS", 5).to_i
      @context = Context.new
    end

    def run
      selected = self.class.scenarios
      selected = selected.select { |s| s.name.include?(@filter) } if @filter.present?

      if selected.empty?
        warn "No scenarios matched filter: #{@filter.inspect}"
        exit 1
      end

      puts format_header
      selected.each { |scenario| run_scenario(scenario) }
    end

    private

    def run_scenario(scenario)
      @context.instance_eval(&scenario.setup) if scenario.setup

      @warmup.times { @context.instance_eval(&scenario.measure) }

      times = Array.new(@iterations) do
        Benchmark.realtime { @context.instance_eval(&scenario.measure) }
      end

      mean_ms = (times.sum / times.size * 1000).round(1)
      min_ms = (times.min * 1000).round(1)
      max_ms = (times.max * 1000).round(1)

      puts format("%-32s %8.1f ms  (min %6.1f, max %6.1f)", scenario.name, mean_ms, min_ms, max_ms)
    end

    def format_header
      <<~HEADER

        Benchmarks (RAILS_ENV=test, warmup=#{@warmup}, iterations=#{@iterations})
        #{"-" * 72}
      HEADER
    end
  end
end
