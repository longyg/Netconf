#!/usr/bin/ruby

require 'rubygems'
require 'builder'
require 'xml'
require 'netconf/connection_exception'
require 'netconf/rpc_error'
require 'netconf/rpc_exception'

module Netconf
  class Device
    attr_reader :capabilities, :remote_capabilities, :message_id

    DEFAULT_CAPABILITIES = [
      'urn:ietf:params:xml:ns:netconf:base:1.0',
    ]

    def initialize connection, options = {}
      @capabilities = []
      capabilities_path = File.expand_path('../capabilities', __FILE__)
      Dir.entries(capabilities_path).each do |file|
        next if (file == '.' || file == '..')
        class_name = file.classify
        class_name.gsub!(/\.rb$/, '')
        if (file =~ /\.rb$/)
          require "#{capabilities_path}/#{file}"
          begin
            klass = Object.const_get(class_name)
          rescue NameError => e
            raise "Expected #{capabilities_path}/#{file} to declare #{class_name}"
          end
          @capabilities.push(klass)
        end
      end

      @connection = connection
      @message_id = 0
      send_and_recv_hello
    end

    # appropriate mesage-id attribute.  Once the initial rpc
    # tag has been sent the block will be called and the XML
    # builder object will be passed to the block.  The block
    # should construct only the XML it is required to send.
    # When the block returns the send_rpc method will close the
    # initial rpc tag
    # 
    # For example:
    #   device.send_rpc do |xml|
    #     xml.config do
    #       xml.value "config value"
    #     end
    #   end
    #
    # The above code example will send out something close to:
    #   <rpc message-id='0'>
    #     <config>
    #       <value>config value</value>
    #     </config>
    #   </rpc>
    #
    # The reason for using a block as a callback in this case
    # is for IO optimization since the Builder object is
    # actually tied to the output stream and will be sending
    # the data as the document is being constructed
    #
    def send_rpc &block
      @connection.send do |out|
        xml = Builder::XmlMarkup.new(:target => out, :indent => 1)
        xml.rpc 'message-id' => "#{(@message_id += 1)}" do
          block.call(xml)
        end
      end
    end

    # Read and parse a reply from the server.  This method will
    # call a provided block with an XML::Reader that has its cursor
    # positioned at the beginning of the content within a <data>
    # tag.  The block *must* only read the content and complete
    # at the ending <data> tag
    #
    # If the response includes errors then an RPCExxception
    # is raised and will contain the errors raised.
    #
    # If no response is received but the servers response with
    # 'ok' then the method will return nil
    #
    # Finally if no errors, payload or ok are sent back by the server
    # then an RPCException is raised
    def recv_rpc &block
      payload = nil
      errors = []
      xml_retval = nil
      @connection.recv do |ins|
        reader = XML::Reader.io(ins)
        while (reader.read)
          case reader.name
          when 'rpc-error'
            errors.push(RPCError.new(reader))
          when 'ok'
            ok = true
          when 'data'
            if (reader.node_type == XML::Reader::TYPE_ELEMENT)
              ok = true
              if (block)
                block.call(reader)
              else
                xml_retval = reader.read_inner_xml
              end
            end
          end
        end
        if (errors.length > 0)
          raise RPCException.new(errors)
        end
        if !ok
          raise RPCException("Failed to receive proper RPC reply")
        end
      end
      xml_retval
    end

    private
      def send_and_recv_hello
        @connection.send do |out|
          xml = Builder::XmlMarkup.new(:target => out, :indent => 1)
          xml.hello do
            xml.capabilities do
              DEFAULT_CAPABILITIES.each do |capability|
                xml.capability capability
              end
            end
          end
        end

        @connection.recv do |ins|
          begin
            reader = XML::Reader.io(ins)
            @remote_capabilities = []
            while (reader.read)
              if (reader.name == 'capability')
                remote_capability = reader.read_inner_xml
                next if (remote_capability.nil? || remote_capability =~ /^\s*$/)
                @remote_capabilities.push remote_capability
                @capabilities.each do |capability|
                  if capability.has_capability?(remote_capability)
                    extend capability
                  end
                end
              end
            end
            raise "No capabilities received from device" if @remote_capabilities.length == 0
          rescue => e
            @connection.close
            raise ConnectionException.new("Failed to send and receive hello: #{e}")
          end
        end
      end
  end
end

