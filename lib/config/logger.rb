module Veronic
	class Logger
		require 'logger'

		def initialize(std)
			@std = set_std(std)
			@logger = set_logger(@std)
		end

		def message(msg)
			logger.info(msg)
		end

		def set_std(std)
			if std == 'stderr'
				$stderr.sync = true
			else
				$stdout.sync = true
			end
		end

		def set_logger(std)
			logger = Logger.new(std)
		end

	end
end
		
		