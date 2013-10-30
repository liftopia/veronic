module Route53
  class Zone
    class Record

      def initialize(zone, name, values=[], type, ttl)
        @zone = zone
        @name = name.downcase
        @values = values
        @type =  type
        @ttl = ttl
        @logger = Veronic::Deployer.new().logger
      end

      def get
        @zone.records.select {|x| x.name == @name+'.'}.first
      end

      def exist?
        @zone.records.any? {|x| x.name == @name+'.'}
      end

      def match?
        @zone.records.any? {|x| x.name == @name+'.' && x.values == @values}
      end

      def wait_set
        @logger.info "Waitting for record { name: #{@name}, value: #{@values} }..."
        while !self.match?
          @logger.info "."
          self.set
          sleep 5
        end
        @logger.info "\nRecord { name: #{@name}, value: #{@values} } updated"
      end

      def set
        if self.exist?
          record = self.get
          new_record = Route53::DNSRecord.new(record.name, record.type, record.ttl, record.values, @zone)
          record.update(@name, @type, @ttl, @values, @zone)
        else
          record = Route53::DNSRecord.new(@name, @type, @ttl, @values, @zone)
          record.create
        end
      end

      def delete
        if self.exist?
          record = self.get
          delete_record = Route53::DNSRecord.new(record.name, record.type, record.ttl, record.values, @zone)
          delete_record.delete
        end
      end

    end
  end
end
