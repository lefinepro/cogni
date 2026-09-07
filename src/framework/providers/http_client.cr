require "http/client"
require "json"
require "openssl"

module OcaweCore
  module AI
    # Shared transport for providers that speak OpenAI-compatible HTTP APIs.
    #
    # Generated workflow images are sometimes built from scratch and do not
    # inherit the host's OpenSSL certificate search path. Configure the CA
    # bundle explicitly when one is available, while keeping peer and hostname
    # verification enabled.
    module ProviderHTTP
      private def post_json(
        url : String,
        key : String,
        body : String,
        timeout : Time::Span,
      ) : HTTP::Client::Response
        uri = URI.parse(url)
        tls = provider_tls_context(uri)

        HTTP::Client.new(uri, tls: tls) do |client|
          client.connect_timeout = timeout
          client.read_timeout = timeout
          client.write_timeout = timeout
          client.post(
            uri.request_target,
            headers: HTTP::Headers{
              "Authorization" => "Bearer #{key}",
              "Content-Type"  => "application/json",
            },
            body: body
          )
        end
      end

      private def request_timeout(metadata : AnyHash) : Time::Span
        seconds = metadata_number(metadata["timeout_seconds"]?) || metadata_number(metadata["timeout"]?) || 20.0
        seconds = 1.0 if seconds < 1.0
        seconds.seconds
      end

      private def metadata_number(value : JSON::Any?) : Float64?
        return nil unless value
        value.as_f? || value.as_i?.try(&.to_f) || value.as_s?.try(&.to_f?)
      end

      private def provider_tls_context(uri : URI) : OpenSSL::SSL::Context::Client?
        return nil unless uri.scheme == "https"

        context = OpenSSL::SSL::Context::Client.new
        if ca_file = provider_ca_file
          context.ca_certificates = ca_file
        elsif ca_dir = provider_ca_directory
          context.ca_certificates_path = ca_dir
        end
        context
      end

      private def provider_ca_file : String?
        candidates = [
          ENV["SSL_CERT_FILE"]?,
          ENV["NIX_SSL_CERT_FILE"]?,
          "/etc/ssl/certs/ca-certificates.crt",
          "/etc/ssl/certs/ca-bundle.crt",
          "/etc/pki/tls/certs/ca-bundle.crt",
        ]
        candidates.each do |path|
          next unless path
          next if path.empty?
          return path if File.file?(path)
        end
        nil
      end

      private def provider_ca_directory : String?
        candidates = [
          ENV["SSL_CERT_DIR"]?,
          "/etc/ssl/certs",
          "/etc/pki/tls/certs",
        ]
        candidates.each do |path|
          next unless path
          next if path.empty?
          return path if Dir.exists?(path)
        end
        nil
      end
    end
  end
end
