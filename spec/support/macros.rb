module Macros
  def self.extended(base)
    ways_to_read_attributes = [:method, :read_attribute, :[]].freeze
    ways_to_write_attributes = [:initializer, :write_attribute, :[]=].freeze
    ways_to_read_and_write_attributes = (
      ways_to_read_attributes.flat_map do |way_to_read|
        ways_to_write_attributes.map do |way_to_write|
          [way_to_read, way_to_write]
        end
      end
    ).freeze

    base.define_singleton_method(:reading_attributes_via) do |&block|
      ways_to_read_attributes.each do |way_to_read|
        context "reading attributes via #{way_to_read}" do
          instance_exec(way_to_read, &block)
        end
      end
    end

    base.define_singleton_method(:writing_attributes_via) do |&block|
      ways_to_write_attributes.each do |way_to_write|
        context "writing attributes via #{way_to_write}" do
          instance_exec(way_to_write, &block)
        end
      end
    end

    base.define_singleton_method(:reading_and_writing_attributes_via) do |&block|
      ways_to_read_and_write_attributes.each do |way_to_read, way_to_write|
        context "reading attributes via #{way_to_read} and writing attributes via #{way_to_write}" do
          instance_exec(way_to_read, way_to_write, &block)
        end
      end
    end
  end
end
