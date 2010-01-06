require 'hoptoad_notifier'

module Resque
  module Failure
    # A Failure backend that retries failures and sends exceptions raised by jobs to Hoptoad.
    #
    # To use it, put this code in an initializer, Rake task, or wherever:
    #
    #   Resque::Failure.backend = RedisHoptoad
    class RedisHoptoad < Resque::Failure::Redis

      # Returns the actual class constant represented in this job's payload.
      def payload_class
        constantize(@payload['class'])
      end

      # Returns an array of args represented in this job's payload.
      def args
        @payload['args']
      end
      
      def save
        super

        begin
          # Notify Hoptoad
          data = {
            :error_class   => exception.class.name,
            :error_message => "#{exception.class.name}: #{exception.message} (#{exception.backtrace[0]})",
            :backtrace     => exception.backtrace,
            :environment   => {},
            :session       => {},
            :request       => {
              :params => payload.merge(:worker => worker.to_s, :queue => queue.to_s)
            }
          }

          HoptoadNotifier.notify(data)
        rescue
          log("Unable to notify Hoptoad: #{$!}")
        end
      end

    end

  end
end