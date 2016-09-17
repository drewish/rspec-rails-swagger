require 'rspec/core/formatters/base_text_formatter'

module RSpec
  module Swagger
    class Formatter < RSpec::Core::Formatters::BaseTextFormatter
       RSpec::Core::Formatters.register self,
        :example_group_started, :example_group_finished, :example_finished

      def initialize(output)
        super
        @document = {}
      end

      def watching?
        !!@watching
      end

      def example_group_started(notification)
        @watching = notification.group.metadata[:type] == :request
        return unless watching?

        pp notification.group.metadata
      end

      def example_finished(notification)
        return unless watching?

        # pp notification
      end

      def example_group_finished(notification)
        @watching = true
      end
    end
  end
end
