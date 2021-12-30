# Copyright (c) 2016-2022 The Ruby-Eth Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "net/http"
require "json"

# Provides the `Eth` module.
module Eth
  class HttpClient < Client
    attr_accessor :host
    attr_accessor :port
    attr_accessor :uri
    attr_accessor :ssl
    attr_accessor :proxy

    def initialize(host, proxy = nil, log = false)
      # super(log)
      uri = URI.parse(host)
      raise ArgumentError unless ["http", "https"].include? uri.scheme
      @host = uri.host
      @port = uri.port
      @proxy = proxy

      @ssl = uri.scheme == "https"
      @uri = URI("#{uri.scheme}://#{@host}:#{@port}#{uri.path}")
    end

    def send_single(payload)
      if @proxy.present?
        _, p_username, p_password, p_host, p_port = @proxy.gsub(/(:|\/|@)/, " ").squeeze(" ").split
        http = ::Net::HTTP.new(@host, @port, p_host, p_port, p_username, p_password)
      else
        http = ::Net::HTTP.new(@host, @port)
      end

      if @ssl
        http.use_ssl = true
      end
      header = { "Content-Type" => "application/json" }
      request = ::Net::HTTP::Post.new(uri, header)
      request.body = payload
      response = http.request(request)
      response.body
    end

    def send_batch(batch)
      result = send_single(batch.to_json)
      result = JSON.parse(result)
      result.sort_by! { |c| c["id"] }
    end
  end
end
